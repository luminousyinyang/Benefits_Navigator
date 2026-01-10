from fastapi import FastAPI, Depends, HTTPException, status
from models import UserSignup, UserLogin, Token
import auth

app = FastAPI(title="Benefits App Backend")

@app.get("/health")
def read_health():
    return {"status": "ok"}

@app.post("/signup", response_model=dict, status_code=status.HTTP_201_CREATED)
def signup(user: UserSignup):
    """
    Registers a new user in Firebase.
    """
    try:
        created_user = auth.create_user(user.email, user.password, user.first_name, user.last_name)
        return {"message": f"User {created_user.uid} created successfully", "uid": created_user.uid}
    except HTTPException as e:
        raise e
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))

@app.post("/login", response_model=Token)
def login(user: UserLogin):
    """
    Logs in a user and returns a Firebase ID token.
    """
    try:
        auth_response = auth.verify_password(user.email, user.password)
        return Token(
            id_token=auth_response['idToken'],
            local_id=auth_response['localId'],
            email=auth_response['email']
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/me", response_model=dict)
def read_users_me(uid: str):
    """
    Fetch current user profile.
    """
    try:
        profile = auth.get_user_profile(uid)
        return profile
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
