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
        
        # --- STATS CALCULATION ---
        try:
             # Query ALL transactions to re-calculate stats
             all_tx_docs = transactions_ref.stream()
             
             total_cashback = 0.0
             retailer_counts = {}
             
             for doc in all_tx_docs:
                 data = doc.to_dict()
                 # Cashback
                 total_cashback += data.get('cashback_earned', 0.0)
                 
                 # Retailer Frequency
                 retailer = data.get('retailer', 'Unknown')
                 retailer_counts[retailer] = retailer_counts.get(retailer, 0) + 1
                 
             # Determine Top Retailer
             top_retailer = "Must do more shopping!"
             if retailer_counts:
                 top_retailer = max(retailer_counts, key=retailer_counts.get)
                 
             # Update User Profile
             user_ref = db.collection('users').document(uid)
             user_ref.update({
                 "total_cashback": total_cashback,
                 "top_retailer": top_retailer
             })
             
        except Exception as stats_error:
            print(f"Stats Calculation Error: {stats_error}")
            # Non-blocking, continue
        
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
