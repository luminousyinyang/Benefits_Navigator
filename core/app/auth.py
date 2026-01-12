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

def refresh_access_token(refresh_token: str):
    """
    Exchanges a valid refresh token for a new ID token.
    Endpoint: https://securetoken.googleapis.com/v1/token
    """
    if not FIREBASE_WEB_API_KEY:
        raise HTTPException(
             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
             detail="Server misconfiguration: FIREBASE_WEB_API_KEY not set."
        )
        
    url = f"https://securetoken.googleapis.com/v1/token?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token
    }
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Token refresh failed: {response.text}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not refresh token. Please login again."
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

def get_card_suggestions(query: str):
    """
    Returns a list of card names that start with the query (Autocomplete).
    """
    # Simple Firestore prefix search
    # Note: Case sensitive. Ideally we store lowercase_name.
    # For now assuming query matches the casing in DB or DB has standard casing.
    end_query = query + '\uf8ff'
    docs = db.collection('cards')\
        .where('name', '>=', query)\
        .where('name', '<=', end_query)\
        .limit(10)\
        .stream()
        
    suggestions = []
    for doc in docs:
        data = doc.to_dict()
        if 'name' in data:
            suggestions.append(data['name'])
    return suggestions

def add_user_card(uid: str, card_data: dict):
    """
    Links a card to the user's wallet.
    WE COPY the full data (Snapshot) so the wallet loads instantly.
    """
    card_id = card_data.get('id') or card_data.get('name')
    if not card_id:
         raise ValueError("Card must have an ID or Name")

    # Relational Strategy:
    # We only need the ID in the user's subcollection to link to global.
    # But we might store 'added_at' metadata.
    link_data = {
        'card_id': card_id,
        'added_at': firestore.SERVER_TIMESTAMP,
        'name': card_data.get('name') # Redundant but useful for quick debugging
    }
    
    # Save User-Specific Fields
    if 'sign_on_bonus' in card_data and card_data['sign_on_bonus']:
        link_data['sign_on_bonus'] = card_data['sign_on_bonus']
    
    # Save to user's subcollection
    db.collection('users').document(uid).collection('cards').document(card_id).set(link_data)
    
def get_user_cards(uid: str):
    """
    Fetches user's cards using a Relational Pattern.
    1. Get Card IDs and User-Specific Data from User's subcollection.
    2. Fetch up-to-date details from Global 'cards' collection.
    3. Merge Global Details + User Specifics (Sign-on Bonus).
    """
    # 1. Get references/IDs
    user_card_docs = db.collection('users').document(uid).collection('cards').stream()
    
    user_cards_map = {} # Map ID -> User Data (e.g. bonus)
    card_ids = []
    
    for doc in user_card_docs:
        # We use the document ID as the card ID (name)
        card_ids.append(doc.id)
        user_cards_map[doc.id] = doc.to_dict()
        
    if not card_ids:
        return []
        
    # 2. Fetch Global Data (Batch / WHERE IN)
    # Firestore 'in' query supports up to 10 items. If > 10, need to chunk or use getAll.
    # strict_consistency: db.getAll(*refs) is best.
    
    cards = []
    
    # Chunking for safety (though getAll supports more, 'in' only 10)
    # Using getAll with document references is efficient.
    refs = [db.collection('cards').document(cid) for cid in card_ids]
    
    global_docs = db.get_all(refs)
    
    for doc in global_docs:
        if doc.exists:
            data = doc.to_dict()
            # Ensure ID is injected
            data['card_id'] = doc.id
            
            # 3. Merge User Specifics
            user_specific_data = user_cards_map.get(doc.id, {})
            if 'sign_on_bonus' in user_specific_data:
                data['sign_on_bonus'] = user_specific_data['sign_on_bonus']
            
            cards.append(data)
        else:
            # Handle case where global card was deleted but user still has ref
            # Option: Return basic data from user doc? Or skip?
            # For now, skip.
            print(f"Warning: User {uid} has orphaned card {doc.id}")
            
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
