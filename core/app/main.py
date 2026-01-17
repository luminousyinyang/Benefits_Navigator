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

from routers import transactions, actions, agent
app.include_router(transactions.router)
app.include_router(actions.router)
app.include_router(agent.router)

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

@app.patch("/me", response_model=dict)
def update_user_me(updates: dict, current_user: dict = Depends(get_current_user)):
    """
    Updates current user profile (first_name, last_name, email).
    """
    try:
        uid = current_user['uid']
        # Filter allowed keys
        allowed_keys = {'first_name', 'last_name', 'email', 'financial_details'}
        filtered_updates = {k: v for k, v in updates.items() if k in allowed_keys}
        
        if not filtered_updates:
            raise HTTPException(status_code=400, detail="No valid fields to update")
            
        updated_profile = auth.update_user_profile(uid, filtered_updates)
        return updated_profile
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
        3. 💰 COMPREHENSIVE REWARDS STRUCTURE: You MUST list EVERY SINGLE earning rate. Do not summarize.
           - Include specific multipliers (e.g. "2x miles on Restaurants", "2x miles on Hotel Stays").
           - Include the base rate (e.g. "1x miles on all other purchases").
           - Include any tier bonuses.
           - MISS NOTHING. Errors of omission are unacceptable.
        4. 🛡️ MANDATORY CHECK: You MUST explicitly look for "Extended Warranty", "Purchase Protection", and "Return Protection". If the card has them, INCLUDE THEM. If not, only then omit them. Do not miss them.
        5. 🔗 CONSOLIDATE BY RATE: Group all categories with the SAME earning rate into one single line.
           - BAD: "2x on Dining", "2x on Travel" (Separate lines)
           - GOOD: "2x Miles on Dining & Travel" (Combined)
           - Combine partner offers if they share a rate.
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

@app.patch("/me/cards/{card_id}/bonus")
def update_card_bonus(card_id: str, bonus_update: dict, current_user: dict = Depends(get_current_user)):
    """
    Manually updates the sign-on bonus progress.
    Expects JSON: {"current_spend": 123.45}
    """
    try:
        uid = current_user['uid']
        # 1. Get current card data
        card_ref = auth.db.collection('users').document(uid).collection('cards').document(card_id)
        doc = card_ref.get()
        if not doc.exists:
             raise HTTPException(status_code=404, detail="Card not found in wallet")
             
        data = doc.to_dict()
        bonus = data.get('sign_on_bonus')
        if not bonus:
             raise HTTPException(status_code=404, detail="No active bonus for this card")
             
        # 2. Update fields
        if 'current_spend' in bonus_update:
            bonus['current_spend'] = float(bonus_update['current_spend'])
            
        # Update last_updated to now to simulate manual edit "most recent"
        import datetime
        bonus['last_updated'] = datetime.date.today().isoformat()
        
        # 3. Check completion (logic duplicative but necessary for manual trigger)
        # If manual edit reaches goal, we should process it?
        # User: "Have a way for the user to manually edit... If... reached... add it to the users total cashback"
        # Since this is manual, let's apply the same logic.
        
        if bonus['current_spend'] >= bonus.get('target_spend', 0.0):
             bonus_val = bonus.get('bonus_value', 0.0)
             
             # Add to user total
             user_ref = auth.db.collection('users').document(uid)
             user_ref.update({
                 "total_cashback": auth.firestore.Increment(bonus_val)
             })
             
             # Create reward record
             import hashlib
             reward_id = hashlib.md5(f"MANUAL_REWARD_{card_id}_{bonus['last_updated']}".encode()).hexdigest()
             tx_ref = auth.db.collection('users').document(uid).collection('transactions').document(reward_id)
             tx_ref.set({
                 "date": bonus['last_updated'],
                 "retailer": f"Reward: {data.get('name', 'Card')} Bonus (Manual)",
                 "amount": 0.0,
                 "cashback_earned": bonus_val,
                 "card_name": data.get('name', 'Card'),
                 "created_at": auth.firestore.SERVER_TIMESTAMP,
                 "type": "reward"
             })
             
             # Remove bonus
             card_ref.update({"sign_on_bonus": auth.firestore.DELETE_FIELD})
             return {"status": "success", "message": "Goal reached! Bonus awarded."}
        
        else:
             card_ref.update({"sign_on_bonus": bonus})
             return {"status": "success", "bonus": bonus}
             
    except Exception as e:
        print(f"Error updating bonus: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/me/cards/{card_id}/bonus")
def delete_card_bonus(card_id: str, current_user: dict = Depends(get_current_user)):
    """Removes the sign-on bonus from a card manually."""
    try:
        uid = current_user['uid']
        card_ref = auth.db.collection('users').document(uid).collection('cards').document(card_id)
        card_ref.update({"sign_on_bonus": auth.firestore.DELETE_FIELD})
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
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
            bonus_str = ""
            if card.sign_on_bonus:
                bonus_str = f"\n  *** ACTIVE SIGN-ON BONUS: Earn {card.sign_on_bonus.bonus_value} {card.sign_on_bonus.bonus_type} by {card.sign_on_bonus.end_date}. Spent: ${card.sign_on_bonus.current_spend} ***"
            cards_str += f"- ID: {card.card_id}, Name: {card.name}, Brand: {card.brand}\n  Benefits: {benefits_str}{bonus_str}\n"

        if request.prioritize_category:
            priority_text = f"PRIORITIZE '{request.prioritize_category}' benefits above all else."
            fallback_text = f"CRITICAL: If NO card matches the '{request.prioritize_category}' priority, you MUST explicitly state 'No cards found with {request.prioritize_category} benefit' in the reasoning, and then FALLBACK to finding the best card for VALUE (Cash Back/Points)."
        else:
            priority_text = "Maximizing Cash Back/Points Value is the ONLY goal."
            fallback_text = ""
        
        # User Context
        user_context = ""
        user_profile = auth.get_user_profile(current_user['uid'])

        # START CHANGE: Fetch Current Goal from Agent State (Roadmap)
        try:
            agent_state_ref = auth.db.collection('users').document(current_user['uid']).collection('public_agent_state').document('main')
            agent_state_doc = agent_state_ref.get()
            if agent_state_doc.exists:
                agent_data = agent_state_doc.to_dict()
                current_goal = agent_data.get('target_goal')
                if current_goal:
                    user_context += f"\nCURRENT FINANCIAL GOAL: {current_goal}"
        except Exception as e:
            print(f"Error fetching agent goal for recommendation: {e}")
        # END CHANGE

        if user_profile.get('financial_details'):
             user_context += f"\nFINANCIAL CONTEXT: {user_profile['financial_details']}"

        prompt = f"""
        Act as an expert financial advisor. The user is shopping at: "{request.store_name}".
        
        GOAL: Recommend the SINGLE BEST credit card from the list below to use for this purchase.
        STRATEGY: {priority_text}
        {fallback_text}
        
        ADDITIONAL CONTEXT (IMPORTANT):{user_context}
        
        USER'S CARDS:
        {cards_str}
        
        STEPS:
        1. 🌍 SEARCH: Use Google Search to identify what kind of store "{request.store_name}" is (e.g., Grocery, Dining, Travel, Electronics, Drugstore).
        2. 🧠 ANALYZE: Compare the user's cards against this category.
           - If Strategy is PRIORITIZED CATEGORY: Look specifically for that benefit type (e.g. "Car Rental Insurance", "Warranty"). A card with this WINS over a card with high points but no protection.
           - If Strategy is VALUE (or Fallback): Look for the highest multiplier (e.g. 4x > 3x > 2% > 1.5%).
           - **APPLY CONTEXT**: If the user has specific goals (e.g. "earning miles") or financial constraints (e.g. "needs low APR"), factor this heavily into the decision.
        3. 🧮 CALCULATE: Estimate the return value (e.g. "4% back", "$15 value").
        
        OUTPUT JSON:
        {{
            "best_card_id": "Exact ID from list",
            "reasoning": ["Reason 1", "Reason 2 (mention priority status)", "How it fits user goals"],
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
