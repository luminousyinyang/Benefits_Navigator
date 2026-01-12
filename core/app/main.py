from fastapi import FastAPI, Depends, HTTPException, status
from models import UserSignup, UserLogin, Token, Card, UserCard, RecommendationRequest, RecommendationResponse
import auth as auth
import os
from google import genai
from google.genai import types
from dotenv import load_dotenv
import jobs as jobs

load_dotenv()

app = FastAPI(title="Benefits App Backend")

@app.on_event("startup")
def startup_event():
    jobs.start_scheduler()

@app.on_event("shutdown")
def shutdown_event():
    jobs.shutdown_scheduler()

# Initialize Gemini Client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)
else:
    print("Warning: GEMINI_API_KEY not set. AI features will be disabled.")

from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Verifies the Firebase ID token and returns the decoded token (user info).
    """
    try:
        # Verify the ID token while checking if the token is revoked.
        decoded_token = auth.auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )

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
            email=auth_response['email'],
            refresh_token=auth_response.get('refreshToken'),
            expires_in=auth_response.get('expiresIn')
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/refresh", response_model=Token)
def refresh_token(refresh_token: str):
    """
    Exchanges a refresh token for a new ID token.
    """
    try:
        response = auth.refresh_access_token(refresh_token)
        return Token(
            id_token=response['id_token'],
            local_id=response['user_id'],
            email="", # Refresh doesn't always return email, and it's not critical for session restoration if UID matches
            refresh_token=response['refresh_token'],
            expires_in=response['expires_in']
        )
    except HTTPException as e:
        raise e
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))

@app.get("/me", response_model=dict)
def read_users_me(current_user: dict = Depends(get_current_user)):
    """
    Fetch current user profile using the Bearer token.
    """
    try:
        uid = current_user['uid']
        profile = auth.get_user_profile(uid)
        return profile
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/me/onboarding")
def complete_onboarding(current_user: dict = Depends(get_current_user)):
    """Sets user's onboarded status to True."""
    try:
        uid = current_user['uid']
        auth.set_onboarded(uid, True)
        return {"status": "success"}
    except HTTPException as e:
        raise e

    except HTTPException as e:
        raise e

import google.generativeai as genai_deprecated # Avoid conflict if needed, or remove
from google import genai
from google.genai import types

# ... impots ...

# Initialize Gemini Client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)
else:
    print("Warning: GEMINI_API_KEY not set. AI features will be disabled.")


# ... (auth routes) ...

@app.get("/cards/auto")
def suggest_cards(query: str, current_user: dict = Depends(get_current_user)):
    """
    Returns card suggestions for autocomplete.
    """
    try:
        suggestions = auth.get_card_suggestions(query)
        return {"suggestions": suggestions}
    except Exception as e:
        # Don't break the UI if autocomplete fails
        print(f"Autocomplete error: {e}")
        return {"suggestions": []}

@app.get("/cards/search")
def search_card(query: str, current_user: dict = Depends(get_current_user)):
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
        
        if not client:
             raise HTTPException(status_code=503, detail="AI Service Unavailable")

        # 2. Ask Gemini (Prompt Hardened)
        # We sanitize the query to avoid injection
        safe_query = query.replace('"', '\\"').replace('\n', ' ')
        
        prompt = f"""
        I need you to identify a credit card based on this search query: "{safe_query}".
        
        If the query matches a known real-world credit card (e.g. "Chase Sapphire", "Amex Gold", "Capital One Venture"), perform a deep search for its **OFFICIAL "Guide to Benefits" or "Terms and Conditions" (PDF or Official Site)**.
        
        Return a JSON object with its details.
        Format:
        {{
            "name": "Full Official Name",
            "brand": "Issuing Bank (e.g. Chase)",
            "benefits": [
                {{
                    "category": "Travel" | "Dining" | "Shopping" | "Protection" | "Lifestyle",
                    "title": "Short Title (e.g. 'Delta SkyClub Access')",
                    "description": "One sentence summary.",
                    "details": "Deep details. List specific retailers, coverage amounts, or limitations."
                }}
            ]
        }}
        
        IMPORTANT RULES:
        1. 📄 SOURCE OF TRUTH: You MUST try to find the "Guide to Benefits" PDF or official landing page. Do not rely on third-party blogs if possible.
        2. 🚫 EXCLUDE GENERIC/FINANCIAL FEATURES: Exclude "0% APR", "Annual Fees", "Balance Transfers", "Monthly Installments", "Family/Authorized User" features, "$0 Liability", "ID Theft Protection", and "Presale Tickets". These are standard or costs.
        3. 💰 FOCUS ON VALUE: Prioritize benefits that save money (Credits, Reimbursements, Insurance, Status, Price Protection, Cash Back tiers).
        4. 🛡️ MANDATORY CHECK: You MUST explicitly look for "Extended Warranty", "Purchase Protection", and "Return Protection". If the card has them, INCLUDE THEM. If not, only then omit them. Do not miss them.
        5. 🔗 CONSOLIDATE: If a benefit is split (e.g. "3% at Apple" and "3% at Partners"), COMBINE them into one single benefit (e.g. "3% Daily Cash at Apple & Select Partners").
        6. 📅 VERIFY DATE VALIDITY: Double-check that detailed partners (e.g. Panera, T-Mobile) are STILL valid for the current date. Do not list expired partners.
        7. 📝 BE SPECIFIC: List specific active retailers and coverage amounts in 'details'.
        8. 🔎 GO DEEP: Find mostly purchase perks and insurance.
        
        If the query is gibberish, return {{}}.
        Output strictly valid JSON.
        """
        
        response = client.models.generate_content(
            model='gemini-3-pro-preview',
            contents=prompt,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type='application/json'
            )
        )
        
        text = response.text.strip()
        
        # Cleanup potential markdown code blocks (even with mime type it can happen)
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
def read_user_cards(current_user: dict = Depends(get_current_user)):
    """Fetch user's wallet securely."""
    try:
        uid = current_user['uid']
        return auth.get_user_cards(uid)
    except HTTPException as e:
        raise e

@app.post("/me/cards")
def add_card_to_wallet(card: UserCard, current_user: dict = Depends(get_current_user)):
    """Adds a card to the user's wallet securely."""
    try:
        uid = current_user['uid']
        auth.add_user_card(uid, card.dict())
        return {"status": "success"}
    except HTTPException as e:
        raise e

@app.delete("/me/cards/{card_id}")
def remove_card_from_wallet(card_id: str, current_user: dict = Depends(get_current_user)):
    """Removes a card from the user's wallet securely."""
    try:
        uid = current_user['uid']
        auth.remove_user_card(uid, card_id)
        return {"status": "success"}
    except HTTPException as e:
        raise e

@app.post("/recommend", response_model=RecommendationResponse)
def get_recommendation(request: RecommendationRequest, current_user: dict = Depends(get_current_user)):
    """
    Analyzes the user's cards and the specific store to recommend the best card.
    Uses Gemini + Google Search to determine store category (MCC) and match perks.
    """
    try:
        if not client:
             raise HTTPException(status_code=503, detail="AI Service Unavailable")

        # Prepare card data for prompt
        cards_str = ""
        for card in request.user_cards:
            benefits_str = ", ".join([f"{b.title} ({b.category})" for b in card.benefits]) if card.benefits else "Standard Benefits"
            cards_str += f"- ID: {card.card_id}, Name: {card.name}, Brand: {card.brand}\n  Benefits: {benefits_str}\n"

        priority_text = "PRIORITIZE EXTENDED WARRANTY and PURCHASE PROTECTION above all else." if request.prioritize_warranty else "Maximizing Cash Back/Points Value is the ONLY goal."

        prompt = f"""
        Act as an expert financial advisor. The user is shopping at: "{request.store_name}".
        
        GOAL: Recommend the SINGLE BEST credit card from the list below to use for this purchase.
        STRATEGY: {priority_text}
        
        USER'S CARDS:
        {cards_str}
        
        STEPS:
        1. 🌍 SEARCH: Use Google Search to identify what kind of store "{request.store_name}" is (e.g., Grocery, Dining, Travel, Electronics, Drugstore).
        2. 🧠 ANALYZE: Compare the user's cards against this category.
           - If Strategy is WARRANTY: Look for "Extended Warranty", "Purchase Protection". A card with these WINS over a card with high points but no protection.
           - If Strategy is VALUE: Look for the highest multiplier (e.g. 4x > 3x > 2% > 1.5%).
        3. 🧮 CALCULATE: Estimate the return value (e.g. "4% back", "$15 value").
        
        OUTPUT JSON:
        {{
            "best_card_id": "Exact ID from list",
            "reasoning": ["Reason 1", "Reason 2"],
            "estimated_return": "e.g. '4% Cash Back' or 'Extended Warranty Included'",
            "runner_up_id": "Optional ID of 2nd best",
            "runner_up_reasoning": ["Why it's second"],
            "runner_up_return": "e.g. '1.5% Cash Back'"
        }}
        """
        
        response = client.models.generate_content(
            model='gemini-3-pro-preview',
            contents=prompt,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type='application/json'
            )
        )
        
        text = response.text.strip()
        if text.startswith("```json"): text = text[7:]
        if text.endswith("```"): text = text[:-3]
        
        import json
        result = json.loads(text)
        
        return RecommendationResponse(**result)

    except Exception as e:
        print(f"Recommendation Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
