import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from dotenv import load_dotenv
import requests
from fastapi import HTTPException, status

load_dotenv()

# ... (imports)

# Initialize Firebase Admin
try:
    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    if not cred_path:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH environment variable not set.")
    
    if not os.path.exists(cred_path):
        raise FileNotFoundError(f"Firebase credentials file not found at: {cred_path}")

    cred = credentials.Certificate(cred_path)
    # Check if app is already initialized to avoid errors during reload
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
        
    # Initialize Firestore
    db = firestore.client()
except Exception as e:
    # Fail fast: The app cannot work without Firebase Admin.
    raise RuntimeError(f"Failed to initialize Firebase Admin: {e}")

FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY")

def create_user(email: str, password: str, first_name: str, last_name: str):
    """Creates a new user in Firebase Authentication and stores profile in Firestore."""
    try:
        # 1. Create Auth User
        user = auth.create_user(
            email=email,
            password=password
        )
        
        # 2. Create User Profile in Firestore
        user_data = {
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "onboarded": False,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        db.collection("users").document(user.uid).set(user_data)
        
        return user
    except auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    except Exception as e:
        # If Firestore fails, we might want to delete the Auth user, 
        # but for simplicity in this hackathon context, we'll just fail.
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

def get_user_profile(uid: str):
    """Fetches user profile from Firestore."""
    try:
        doc = db.collection("users").document(uid).get()
        if doc.exists:
            return doc.to_dict()
        else:
             raise HTTPException(status_code=404, detail="User profile not found")
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))


def verify_password(email: str, password: str):
    """
    Logs in a user via Firebase REST API to get an ID token.
    Firebase Admin SDK does not support logging in with password directly.
    """
    if not FIREBASE_WEB_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Server misconfiguration: FIREBASE_WEB_API_KEY not set."
        )

    request_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    
    response = requests.post(request_url, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        # Debugging
        print(f"Login failed: {response.status_code} - {response.text}")
        
        # Map Firebase errors to HTTP exceptions
        try:
            error_data = response.json()
        except:
             print("Could not parse error JSON")
             raise HTTPException(status_code=500, detail=f"Upstream auth error: {response.status_code}")

        error_msg = error_data.get('error', {}).get('message', 'Login failed')
        if "INVALID_PASSWORD" in error_msg or "EMAIL_NOT_FOUND" in error_msg:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )

def set_onboarded(uid: str, status: bool = True):
    """Updates the user's onboarded status."""
    try:
        db.collection("users").document(uid).update({"onboarded": status})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def save_global_card(card_data: dict):
    """Saves a card definition to the global 'cards' collection."""
    card_id = card_data.get('name')
    if not card_id:
        return
    
    # Use name as document ID for simplicity and deduplication
    db.collection('cards').document(card_id).set(card_data, merge=True)
    return card_id

def get_global_card(query: str):
    """
    Searches global cards collection.
    Using exact match on ID (name) for this iteration since we use name as ID.
    In real app, would use Angolia or ElasticSearch for fuzzy search.
    """
    # 1. Try direct ID match (exact name)
    doc = db.collection('cards').document(query).get()
    if doc.exists:
        return doc.to_dict()
    
    # 2. Try simple equality filter on 'name' field
    # (Firestore queries are case sensitive unfortunately)
    docs = db.collection('cards').where('name', '==', query).stream()
    for doc in docs:
        return doc.to_dict()
        
    return None

def add_user_card(uid: str, card_data: dict):
    """
    Links a card to the user's wallet.
    We only store the reference (card_id) in the user's subcollection.
    """
    card_id = card_data.get('id') or card_data.get('name')
    if not card_id:
         raise ValueError("Card must have an ID or Name")

    # 1. Ensure it exists in global (it should, but just in case)
    # If we are adding it, we might want to refresh the global record or ensure it's there?
    # For now, we assume user flow is Search -> (Save Global) -> Add to User.
    # So we just save the reference.
    
    user_card_ref = {'card_reference': card_id, 'added_at': firestore.SERVER_TIMESTAMP}
    db.collection('users').document(uid).collection('cards').document(card_id).set(user_card_ref)
    
def get_user_cards(uid: str):
    """
    Fetches user's cards by looking up references.
    """
    user_cards_refs = db.collection('users').document(uid).collection('cards').stream()
    
    cards = []
    for user_card_doc in user_cards_refs:
        ref_data = user_card_doc.to_dict()
        card_id = ref_data.get('card_reference')
        
        if card_id:
            # Fetch actual data from global collection
            # Note: In production, use getAll() for batch fetching for performance
            global_card_doc = db.collection('cards').document(card_id).get()
            if global_card_doc.exists:
                data = global_card_doc.to_dict()
                # Inject the ID into the dict so frontend has it
                data['card_id'] = global_card_doc.id 
                cards.append(data)
                
    return cards

def remove_user_card(uid: str, card_id: str):
    """Removes a card from the user's wallet."""
    try:
        # Debugging
        print(f"Removing card {card_id} for user {uid}")
        
        # The document ID in the subcollection is the card ID (name)
        db.collection('users').document(uid).collection('cards').document(card_id).delete()
        print(f"Successfully deleted card document {card_id}")
    except Exception as e:
        print(f"Error removing card: {e}")
        raise HTTPException(status_code=500, detail=str(e))
