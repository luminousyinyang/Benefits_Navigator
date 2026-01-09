import os
import firebase_admin
from firebase_admin import credentials, auth
import requests
from dotenv import load_dotenv
from fastapi import HTTPException, status

load_dotenv()

# Initialize Firebase Admin
try:
    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    if not cred_path:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH environment variable not set.")
    
    if not os.path.exists(cred_path):
        raise FileNotFoundError(f"Firebase credentials file not found at: {cred_path}")

    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
except Exception as e:
    # Fail fast: The app cannot work without Firebase Admin.
    raise RuntimeError(f"Failed to initialize Firebase Admin: {e}")

FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY")

def create_user(email: str, password: str):
    """Creates a new user in Firebase Authentication."""
    try:
        user = auth.create_user(
            email=email,
            password=password
        )
        return user
    except auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

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
