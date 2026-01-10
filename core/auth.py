import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from dotenv import load_dotenv
import requests

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
        # Map Firebase errors to HTTP exceptions
        error_msg = response.json().get('error', {}).get('message', 'Login failed')
        if "INVALID_PASSWORD" in error_msg or "EMAIL_NOT_FOUND" in error_msg:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )
