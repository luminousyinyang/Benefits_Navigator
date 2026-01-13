from fastapi import APIRouter, UploadFile, File, HTTPException, Header, Depends
from typing import List, Dict, Any
from services.gemini_service import GeminiService
from firebase_admin import auth as firebase_auth
from firebase_admin import firestore
import auth as auth_utils # Using your existing auth module for DB access

router = APIRouter(
    prefix="/transactions",
    tags=["transactions"]
)

gemini_service = GeminiService()
db = auth_utils.db # Reuse the db instance from your auth module

def get_current_user_uid(authorization: str = Header(...)):
    """
    Verifies the Firebase ID Token and returns the UID.
    """
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        token = authorization.split("Bearer ")[1]
        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token['uid']
    except Exception as e:
        print(f"Auth Error: {e}")
        raise HTTPException(status_code=401, detail="Invalid credential")

@router.post("/upload")
async def upload_statement(
    file: UploadFile = File(...),
    uid: str = Depends(get_current_user_uid)
):
    """
    Uploads a PDF statement, extracts transactions using Gemini, and saves them to Firestore.
    """
    if file.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="Only PDF files are allowed.")
    
    try:
        # Read file bytes
        content = await file.read()
        
        # Process with Gemini
        transactions = gemini_service.process_statement(content)
        
        if not transactions:
            return {"message": "No transactions found or processing failed.", "count": 0}
            
        # Save to Firestore (Subcollection: users/{uid}/transactions)
        batch = db.batch()
        transactions_ref = db.collection('users').document(uid).collection('transactions')
        
        import hashlib
        
        saved_count = 0
        for tx in transactions:
            # Create a deterministic ID to prevent duplicates
            # ID = Hash(date + retailer + amount)
            # You could add card_name if you distinguish overlapping transactions on different cards
            unique_str = f"{tx.get('date')}_{tx.get('retailer')}_{tx.get('amount')}"
            tx_id = hashlib.md5(unique_str.encode()).hexdigest()
            
            # Create a document ref with the deterministic ID
            doc_ref = transactions_ref.document(tx_id)
            
            # Prepare data for DB (use copy to avoid mutating response with non-serializable Sentinel)
            tx_db = tx.copy()
            # Only set created_at if it's new, but MERGE=TRUE handles updates.
            # However, if we want to preserve original created_at, we might need a read. 
            # For simplicity, we just update/overwrite.
            tx_db['updated_at'] = firestore.SERVER_TIMESTAMP
            tx_db['source_file'] = file.filename
            
            # Use SET with merge=True to update existing or create new
            batch.set(doc_ref, tx_db, merge=True)
            saved_count += 1
            
            # Add serializable metadata to response if desired
            tx['source_file'] = file.filename
            
        batch.commit()
        
        # --- INCREMENTAL UPDATES & BONUS TRACKING ---
        try:
             # 0. Identify NEW transactions to prevent double counting stats
             # We already generated doc_refs above but we didn't check existence.
             # We need to know which hashes are new.
             # Re-generate IDs locally to map them.
             tx_map = {}
             for tx in transactions:
                 unique_str = f"{tx.get('date')}_{tx.get('retailer')}_{tx.get('amount')}"
                 tx_id = hashlib.md5(unique_str.encode()).hexdigest()
                 tx_map[tx_id] = tx
                 
             # Check existence in batch
             tx_ids = list(tx_map.keys())
             existing_ids = set()
             
             # Firestore get_all supports up to 500? chunks if needed.
             # 50 limit on Gemini usually safe.
             refs = [transactions_ref.document(tid) for tid in tx_ids]
             snapshots = db.get_all(refs)
             for snap in snapshots:
                 if snap.exists:
                     existing_ids.add(snap.id)
                     
             new_transactions = [tx for tid, tx in tx_map.items() if tid not in existing_ids]

             print(f"Incremental Stats: Found {len(new_transactions)} new transactions out of {len(transactions)} uploaded.")
             
             if not new_transactions:
                 print("No new transactions. Skipping stats update.")
                 return {
                    "message": "Statement processed. No new transactions found.",
                    "count": saved_count,
                    "data": []
                 }
             

             # 1. Incremental Cashback Update
             new_cashback = sum(tx.get('cashback_earned', 0.0) for tx in new_transactions)
             
             user_ref = db.collection('users').document(uid)
             
             if new_cashback > 0:
                 user_ref.update({
                     "total_cashback": firestore.Increment(new_cashback)
                 })
                 print(f"Added ${new_cashback} to user total.")
             
             # 2. Sign On Bonus Progress
             # Fetch user cards to find active bonuses
             user_cards = auth_utils.get_user_cards(uid)
             
             # Prepare updates
             batch_bonus = db.batch()
             bonus_updates = False
             
             for card in user_cards:
                 bonus = card.get('sign_on_bonus')
                 if not bonus:
                     continue
                 
                 card_doc_id = card.get('card_id') # This is the doc ID in subcollection
                 if not card_doc_id: continue
                     
                 # Determine filtered transactions for this card
                 # Logic: Does tx.card_name match card.name?
                 # Gemini extracts 'card_name'.
                 target_card_name = card.get('name', '').lower()
                 
                # Initialize Bonus Object helpers
                 # If last_updated is None, it means track from the beginning (or as far back as we have).
                 last_updated_str = bonus.get('last_updated') 
                 # User said: "when its first added that should be the date it was last edited".
                 # If None, assume it was just added or we check all? 
                 # Let's assume None = check all new.
                 
                 relevant_amount = 0.0
                 max_tx_date = last_updated_str
                 
                 for tx in new_transactions:
                     tx_card = tx.get('card_name', '').lower()
                     
                     # Simple substring match or exact?
                     # Gemini might say "Chase Sapphire" vs "Chase Sapphire Reserve".
                     # If target is present in tx_card or vice versa?
                     # Let's try containment.
                     match = (target_card_name in tx_card) or (tx_card in target_card_name and len(tx_card) > 5)
                     
                     if not match:
                         continue
                         
                     tx_date = tx.get('date') # YYYY-MM-DD
                     
                     # specific logic: "if its after the date last edited"
                     if last_updated_str and tx_date <= last_updated_str:
                         continue
                         
                     relevant_amount += tx.get('amount', 0.0)
                     
                     # Track max date
                     if not max_tx_date or tx_date > max_tx_date:
                         max_tx_date = tx_date
                 
                 if relevant_amount > 0:
                     print(f"Adding ${relevant_amount} to bonus for {card.get('name')}")
                     
                     # Update Bonus State
                     current_spend = bonus.get('current_spend', 0.0)
                     target_spend = bonus.get('target_spend', 0.0)
                     
                     new_spend = current_spend + relevant_amount
                     bonus['current_spend'] = new_spend
                     bonus['last_updated'] = max_tx_date
                     
                     # Check Completion
                     if new_spend >= target_spend:
                         bonus_val = bonus.get('bonus_value', 0.0)
                         print(f"Goal Reached! Adding bonus ${bonus_val}")
                         
                         # Add to User Total
                         # Store as a visible transaction? User: "Create a 'Reward' transaction record... yes that sounds good."
                         reward_tx = {
                             "date": max_tx_date,
                             "retailer": f"Reward: {card.get('name')} Bonus",
                             "amount": 0.0,
                             "cashback_earned": bonus_val,
                             "card_name": card.get('name'),
                             "created_at": firestore.SERVER_TIMESTAMP,
                             "type": "reward"
                         }
                         # ID for reward
                         reward_id = hashlib.md5(f"REWARD_{card_doc_id}_{max_tx_date}".encode()).hexdigest()
                         transactions_ref.document(reward_id).set(reward_tx)
                         
                         user_ref.update({
                             "total_cashback": firestore.Increment(bonus_val)
                         })
                         
                         # Remove bonus from card (User: "remove it from the user's account")
                         # Field delete
                         card_ref = db.collection('users').document(uid).collection('cards').document(card_doc_id)
                         batch_bonus.update(card_ref, {"sign_on_bonus": firestore.DELETE_FIELD})
                         
                     else:
                         # Just update progress
                         card_ref = db.collection('users').document(uid).collection('cards').document(card_doc_id)
                         batch_bonus.update(card_ref, {"sign_on_bonus": bonus})
                     
                     bonus_updates = True
                     
             if bonus_updates:
                 batch_bonus.commit()
                 
        except Exception as e:
            print(f"Stats Error: {e}")
            import traceback
            traceback.print_exc()

        
        return {
            "message": "Statement processed successfully",
            "count": saved_count,
            "data": transactions # Optional: return data for immediate UI update
        }
        
    except Exception as e:
        print(f"Upload Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/")
async def get_transactions(uid: str = Depends(get_current_user_uid)):
    """
    Fetches all transactions for the user.
    """
    try:
        transactions_ref = db.collection('users').document(uid).collection('transactions')
        # Order by date descending if 'date' is a consistent YYYY-MM-DD string
        docs = transactions_ref.order_by('date', direction=firestore.Query.DESCENDING).limit(50).stream()
        
        results = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            # Convert timestamp to string if needed, or handle on client.
            # `date` is already string YYYY-MM-DD from Gemini.
            results.append(data)
            
        return results
        
    except Exception as e:
        print(f"Fetch Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
