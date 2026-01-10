from fastapi import FastAPI, Depends, HTTPException, status
from models import UserSignup, UserLogin, Token, Card, UserCard
import auth
import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Benefits App Backend")

# Initialize Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-3-pro-preview') # Using 1.5 Pro for better reasoning
else:
    print("Warning: GEMINI_API_KEY not set. AI features will be disabled.")
    model = None

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

@app.post("/me/onboarding")
def complete_onboarding(uid: str):
    """Sets user's onboarded status to True."""
    try:
        auth.set_onboarded(uid, True)
        return {"status": "success"}
    except HTTPException as e:
        raise e

@app.get("/cards/search")
def search_card(query: str):
    """
    Searches for a card. 
    1. Checks global DB.
    2. If not found, asks Gemini to find details and adds to global DB.
    """
    try:
        # 1. Local / Global Search
        existing_card = auth.get_global_card(query)
        if existing_card:
            print(f"Found card in global DB: {existing_card.get('name')}")
            return existing_card
        
        if not model:
             raise HTTPException(status_code=503, detail="AI Service Unavailable")

        # 2. Ask Gemini
        prompt = f"""
        I need you to identify a credit card based on this search query: "{query}".
        
        If the query matches a known real-world credit card (e.g. "Chase Sapphire", "Amex Gold", "Capital One Venture"), return a JSON object with its details.
        
        Rules:
        1. 'name': The full official name of the card.
        2. 'brand': The issuing bank or network (e.g. 'Chase', 'American Express', 'Citi').
        3. 'benefits': A dictionary where keys are short benefit titles (e.g. "Dining", "Travel") and values are brief descriptions (e.g. "4x points", "3x points").
        
        If the query is gibberish or does not look like a credit card, return an empty JSON object {{}}.
        
        Output strictly valid JSON. No markdown.
        """
        
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Cleanup potential markdown code blocks
        if text.startswith("```json"):
            text = text[7:]
        if text.endswith("```"):
            text = text[:-3]
            
        import json
        card_data = json.loads(text)
        
        if not card_data:
             raise HTTPException(status_code=404, detail="Card not found. Please try a different name.")
             
        # Normalize keys just in case
        if "name" not in card_data or "brand" not in card_data:
             raise HTTPException(status_code=404, detail="Could not identify card details.")

        # 3. Save to global DB
        auth.save_global_card(card_data)
        
        return card_data

    except Exception as e:
        print(f"Error searching card: {e}")
        # Fallback error
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/me/cards")
def read_user_cards(uid: str):
    """Fetch user's wallet."""
    try:
        return auth.get_user_cards(uid)
    except HTTPException as e:
        raise e

@app.post("/me/cards")
def add_card_to_wallet(uid: str, card: UserCard):
    """Adds a card to the user's wallet."""
    try:
        auth.add_user_card(uid, card.dict())
        return {"status": "success"}
    except HTTPException as e:
        raise e

@app.delete("/me/cards/{card_id}")
def remove_card_from_wallet(uid: str, card_id: str):
    """Removes a card from the user's wallet."""
    try:
        auth.remove_user_card(uid, card_id)
        return {"status": "success"}
    except HTTPException as e:
        raise e

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
