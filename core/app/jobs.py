from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from google import genai
from google.genai import types
import os
import auth as auth
from firebase_admin import firestore
import time
import json

from services.marathon_agent import MarathonAgent

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
            3. 💰 COMPREHENSIVE REWARDS STRUCTURE: You MUST list EVERY SINGLE earning rate. Do not summarize.
               - Include specific multipliers (e.g. "2x miles on Restaurants", "2x miles on Hotel Stays").
               - Include the base rate (e.g. "1x miles on all other purchases").
               - Include any tier bonuses.
               - MISS NOTHING. Errors of omission are unacceptable.
            4. 🛡️ MANDATORY CHECK: You MUST explicitly look for "Extended Warranty", "Purchase Protection", and "Return Protection". If the card has them, INCLUDE THEM.
            5. 🔗 CONSOLIDATE BY RATE: Group all categories with the SAME earning rate into one single line.
               - BAD: "2x on Dining", "2x on Travel" (Separate lines)
               - GOOD: "2x Miles on Dining & Travel" (Combined)
               - Combine partner offers if they share a rate.
            6. 📅 VERIFY DATE VALIDITY: Double-check that detailed partners (e.g. Panera, T-Mobile) are STILL valid for the current date. Do not list expired partners.
            7. 📝 BE SPECIFIC: List specific active retailers and coverage amounts in 'details'.
            8. 🔎 GO DEEP: Find mostly purchase perks and insurance.
            """
            
            try:
                # Add delay to avoid rate limits
                time.sleep(2) 
                
                response = client.models.generate_content(
                    model='gemini-3-flash-preview',
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



def check_single_item_price(item: dict, client=None):
    """
    Checks the price for a single item. 
    Can be called by Cron Job OR manually via API trigger.
    """
    if not client:
        client = get_gemini_client()
        if not client:
            print("Skipping check: No Gemini API Key.")
            return

    item_id = item.get('id')
    uid = item.get('uid')
    product_name = item.get('item_bought')
    original_price = item.get('total')
    
    if not product_name or not uid:
        return
        
    print(f"Checking price for: {product_name} (Paid: ${original_price})")
    
    # 2. Ask Gemini 3 Flash
    prompt = f"""
    Search specifically for the CURRENT lowest price of this exact product: "{product_name}".
    Search all major retailers (Amazon, Best Buy, Walmart, Target, Manufacturer Store).
    
    Identify the lowest valid price currently available for a NEW (not used/refurbished) item.
    
    Return JSON:
    {{
        "lowest_price": 123.45,
        "retailer": "Store Name",
        "url": "Link to deal"
    }}
    
    CRITICAL URL RULES:
    1. The 'url' MUST be the exact, real link returned by the Google Search tool. 
    2. DO NOT guess or hallucinate URLs. 
    3. Ensure the link goes directly to the product page, not a search results page.
    4. If you cannot find a 100% confirmed valid link, return null for the URL.
    
    If no clear price/URL found, return null for lowest_price.
    """
    
    try:
        # Rate limit protection if running in batch (caller handles big loops, but small safety here)
        # time.sleep(1) 
        
        response = client.models.generate_content(
            model='gemini-3-flash-preview', # Updated to valid model
            contents=prompt,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type='application/json'
            )
        )
        
        text = response.text.strip()
        if text.startswith("```json"): text = text[7:]
        if text.endswith("```"): text = text[:-3]
        
        try:
            result = json.loads(text)
            
            # Handle potential list response
            if isinstance(result, list):
                if len(result) > 0:
                    result = result[0]
                else:
                    print(f"Empty list returned for {product_name}")
                    return
        except json.JSONDecodeError:
            print(f"JSON Decode Error for {product_name}: {text}")
            return

        found_price = result.get('lowest_price')
        found_url = result.get('url')
        
        if found_price and isinstance(found_price, (int, float)):
            # Check if lower
            if found_price < original_price:
                print(f"📉 PRICE DROP FOUND: ${found_price} at {result.get('retailer')}")
                
                # Update Item
                auth.update_action_item(uid, 'price_protection', item_id, {
                    "lowest_price_found": found_price,
                    "lowest_price_url": found_url,
                    "last_checked": firestore.SERVER_TIMESTAMP,
                })
            else:
                print(f"No drop. Lowest found: ${found_price}")
                # Update last check anyway
                auth.update_action_item(uid, 'price_protection', item_id, {
                    "last_checked": firestore.SERVER_TIMESTAMP
                })
        else:
            print("Could not verify price.")
            
    except Exception as e:
        print(f"Error checking {product_name}: {e}")

def check_price_drops():
    """
    CRON JOB: Runs Daily at Midnight.
    Checks all items in 'price_protection' that have monitoring enabled.
    Uses Gemini 3 Flash + Google Search to find lower prices.
    """
    print("--- 💰 STARTING PRICE CHECK JOB ---")
    client = get_gemini_client()
    if not client:
        print("Skipping job: No Gemini API Key.")
        return

    try:
        # 1. Fetch Monitored Items
        items = auth.get_all_monitored_price_items()
        print(f"Found {len(items)} items to monitor.")
        
        for item in items:
            check_single_item_price(item, client)
            # Add delay to avoid rate limits
            time.sleep(1)
                
        print("--- ✅ PRICE CHECK JOB COMPLETE ---")

    except Exception as e:
        print(f"Fatal Price Job Error: {e}")

def run_daily_marathon():
    """
    CRON JOB: Runs Daily at Midnight.
    Triggers the CreditAgent for all users.
    """
    print("--- 🧠 STARTING MARATHON AGENT JOB ---")
    try:
        agent = MarathonAgent()
        
        # Fetch all users
        # In production, query only active users or chunk this.
        users_stream = auth.db.collection('users').stream()
        
        for user_doc in users_stream:
            uid = user_doc.id
            if uid:
                try:
                    agent.run_agent_cycle(uid)
                    # Add delay to avoid rate limits per user
                    time.sleep(5) 
                except Exception as e:
                    print(f"❌ Error running agent for user {uid}: {e}")
                    
        print("--- ✅ MARATHON AGENT JOB COMPLETE ---")
    except Exception as e:
        print(f"Fatal Marathon Job Error: {e}")

def start_scheduler():
    # Schedule: 2nd of every month at midnight (Card Update)
    trigger_cards = CronTrigger(day=2, hour=0, minute=0)
    scheduler.add_job(update_all_cards, trigger_cards, id='monthly_card_update')
    
    # Schedule: Daily at Midnight (Price Check)
    trigger_prices = CronTrigger(hour=0, minute=0)
    scheduler.add_job(check_price_drops, trigger_prices, id='daily_price_check')
    
    # Schedule: Weekly on Monday at Midnight (Marathon Agent - Deep Search)
    trigger_agent = CronTrigger(day_of_week='mon', hour=0, minute=0)
    scheduler.add_job(run_daily_marathon, trigger_agent, id='weekly_marathon_agent')
    
    scheduler.start()
    print("📅 Scheduler started: Monthly card updates & Daily price checks active.")

def shutdown_scheduler():
    scheduler.shutdown()
