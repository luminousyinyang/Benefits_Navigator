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
        
        saved_count = 0
        for tx in transactions:
            # Create a new document ref (auto-ID)
            doc_ref = transactions_ref.document()
            
            # Prepare data for DB (use copy to avoid mutating response with non-serializable Sentinel)
            tx_db = tx.copy()
            tx_db['created_at'] = firestore.SERVER_TIMESTAMP
            tx_db['source_file'] = file.filename
            
            batch.set(doc_ref, tx_db)
            saved_count += 1
            
            # Add serializable metadata to response if desired
            tx['source_file'] = file.filename
            
        batch.commit()
        
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
