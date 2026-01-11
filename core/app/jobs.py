from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from google import genai
from google.genai import types
import os
import auth
from firebase_admin import firestore
import time
import json

# Initialize Scheduler
scheduler = BackgroundScheduler()

def get_gemini_client():
    """Returns a configured Gemini Client."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None
    return genai.Client(api_key=api_key)

def update_all_cards():
    """
    CRON JOB: Runs monthly.
    Iterates through all cards in Global DB and updates their benefits using AI Search.
    """
    print("--- 🔄 STARTING MONTHLY CARD UPDATE JOB ---")
    client = get_gemini_client()
    if not client:
        print("Skipping job: No Gemini API Key.")
        return

    try:
        # 1. Fetch all Global Cards
        cards_ref = auth.db.collection('cards')
        docs = cards_ref.stream()
        
        for doc in docs:
            card = doc.to_dict()
            card_name = card.get('name')
            if not card_name:
                continue
                
            print(f"Checking updates for: {card_name}...")
            
            # 2. Ask Gemini for Updates
            prompt = f"""
            Perform a deep, comprehensive search for the **OFFICIAL "Guide to Benefits" or "Terms and Conditions" (PDF or Official Site)** for the credit card: "{card_name}".
            Read through the fine print to find every single perk, including hidden ones like insurance and protections.
            
            Return a JSON object with a 'benefits' list.
            Format:
            {{
                "benefits": [
                    {{
                        "category": "Travel" | "Dining" | "Shopping" | "Protection" | "Lifestyle",
                        "title": "Short Title (e.g. 'Delta SkyClub Access')",
                        "description": "One sentence summary.",
                        "details": "Deep details. List specific retailers, coverage amounts (e.g. '$50k collision'), or limitations."
                    }}
                ]
            }}
            
            IMPORTANT RULES:
            1. 📄 SOURCE OF TRUTH: You MUST try to find the "Guide to Benefits" PDF or official landing page.
            2. 🚫 EXCLUDE GENERIC/FINANCIAL FEATURES: Exclude "0% APR", "Annual Fees", "Balance Transfers", "Monthly Installments", "Family/Authorized User" features, "$0 Liability", "ID Theft Protection", and "Presale Tickets". These are standard or costs.
            3. 💰 FOCUS ON VALUE: Prioritize benefits that save money (Credits, Reimbursements, Insurance, Status, Price Protection, Cash Back tiers).
            4. 🛡️ MANDATORY CHECK: You MUST explicitly look for "Extended Warranty", "Purchase Protection", and "Return Protection". If the card has them, INCLUDE THEM.
            5. 🔗 CONSOLIDATE: If a benefit is split (e.g. "3% at Apple" and "3% at Partners"), COMBINE them into one single benefit (e.g. "3% Daily Cash at Apple & Select Partners").
            6. 📅 VERIFY DATE VALIDITY: Double-check that detailed partners (e.g. Panera, T-Mobile) are STILL valid for the current date. Do not list expired partners.
            7. 📝 BE SPECIFIC: List specific active retailers and coverage amounts in 'details'.
            8. 🔎 GO DEEP: Find mostly purchase perks and insurance.
            """
            
            try:
                # Add delay to avoid rate limits
                time.sleep(2) 
                
                response = client.models.generate_content(
                    model='gemini-3-pro-preview',
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        tools=[types.Tool(google_search=types.GoogleSearch())],
                        response_mime_type='application/json' 
                    )
                )
                
                # Extract JSON (Using response_mime_type handles most formatting, but good to be safe)
                text = response.text.strip()
                # If the model returns markdown code blocks despite mime_type request
                if text.startswith("```json"): text = text[7:]
                if text.endswith("```"): text = text[:-3]
                
                result = json.loads(text)
                
                new_benefits = result.get('benefits')
                
                if new_benefits:
                    # 3. Update Global DB
                    cards_ref.document(doc.id).update({
                        'benefits': new_benefits,
                        'last_updated': firestore.SERVER_TIMESTAMP
                    })
                    print(f"✅ Updated {card_name}")
                else:
                    print(f"⚠️ No benefits found for {card_name}")
                    
            except Exception as e:
                print(f"❌ Error updating {card_name}: {e}")
                
        print("--- ✅ MONTHLY UPDATE JOB COMPLETE ---")
        
    except Exception as e:
        print(f"Fatal Job Error: {e}")

def start_scheduler():
    # Schedule: 2nd of every month at midnight
    trigger = CronTrigger(day=2, hour=0, minute=0)
    
    # For Testing: Run every 5 minutes if TEST_MODE is set, else use cron
    # trigger = CronTrigger(minute='*/5') 
    
    scheduler.add_job(update_all_cards, trigger, id='monthly_card_update')
    scheduler.start()
    print("📅 Scheduler started: Monthly card updates active.")

def shutdown_scheduler():
    scheduler.shutdown()
