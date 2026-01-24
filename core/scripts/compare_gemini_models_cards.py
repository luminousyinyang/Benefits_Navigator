import os
import asyncio
import json
from datetime import datetime
from google import genai
from google.genai import types

# Configure API Key
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    print("❌ ERROR: GEMINI_API_KEY environment variable not set.")
    # Exit hard if no key, but in this script we'll just let it fail gracefully or user sets it
    # exit(1) 

client = genai.Client(api_key=API_KEY)

MODEL_FLASH = "gemini-3-flash-preview"
MODEL_PRO = "gemini-3-pro-preview"
ITERATIONS = 10
OUTPUT_FILE = "reports/gemini_comparison_report_cards.md"

# ==========================================
# 1. DEFINE PROMPTS & MOCK CONTEXT
# ==========================================

# --- SEARCH CARD PROMPT ---
# From main.py lines 217-256
MOCK_SEARCH_QUERY = "Chase Sapphire Reserve"
SAFE_QUERY_SEARCH = MOCK_SEARCH_QUERY.replace('"', '\\"').replace('\n', ' ')

SEARCH_CARD_PROMPT = f"""
I need you to identify a credit card based on this search query: "{SAFE_QUERY_SEARCH}".

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

# --- STORE RECOMMENDATION PROMPT ---
# From main.py lines 456-498
MOCK_STORE_NAME = "Whole Foods Market"
MOCK_CARDS_LIST_STR = """- ID: c1, Name: Amex Gold Card, Brand: American Express
  Benefits: 4x Points on Dining & U.S. Supermarkets ($25k cap), 3x Points on Flights, $120 Uber Cash
- ID: c2, Name: Chase Sapphire Reserve, Brand: Chase
  Benefits: 3x Points on Travel & Dining, $300 Travel Credit, Priority Pass
- ID: c3, Name: Capital One Venture X, Brand: Capital One
  Benefits: 2x Miles on Everything, $300 Travel Credit"""

MOCK_USER_CONTEXT = "CURRENT FINANCIAL GOAL: Optimize for Travel Points"
PRIORITY_TEXT = "Maximizing Cash Back/Points Value is the ONLY goal."
FALLBACK_TEXT = ""

RECOMMENDATION_PROMPT = f"""
Act as an expert financial advisor. The user is shopping at: "{MOCK_STORE_NAME}".

GOAL: Recommend the SINGLE BEST credit card from the list below to use for this purchase.
STRATEGY: {PRIORITY_TEXT}
{FALLBACK_TEXT}

ADDITIONAL CONTEXT (IMPORTANT):{MOCK_USER_CONTEXT}

USER'S CARDS:
{MOCK_CARDS_LIST_STR}

STEPS:
1. 🌍 SEARCH: Use Google Search to identify what kind of store "{MOCK_STORE_NAME}" is.
   - **VALIDATION**: If the input is gibberish, random letters, or clearly not a place of business (e.g. "asdf", "hello"), MARK it as INVALID.
   - **CORRECTION**: If it is a typo or informal name (e.g. "strbcks", "mcdonalds"), CORRECT it to the proper canonical name (e.g. "Starbucks", "McDonald's").
   - **CRITICAL EXCEPTION**: Do NOT "correct" valid words or brand names that might be other things.
     - EXAMPLE: "Delta" is an Airline. Do NOT correct it to "Dell".
     - EXAMPLE: "Apple" is a Store. Do NOT correct it to "Applebees".
     - If the input is ALREADY a valid real-world business (like "Delta"), USE IT AS IS.
2. 🧠 ANALYZE: Compare the user's cards against this category.
   - If Strategy is PRIORITIZED CATEGORY: Look specifically for that benefit type (e.g. "Car Rental Insurance", "Warranty"). A card with this WINS over a card with high points but no protection.
   - If Strategy is VALUE (or Fallback): Look for the highest multiplier (e.g. 4x > 3x > 2% > 1.5%).
   - **POINT VALUATION**: Estimate the REALISTIC cash value of the specific points/miles currency (e.g. Amex MR, Chase UR, Delta SkyMiles) based on general market value. Do NOT use a fixed rate for all cards.
   - **APPLY CONTEXT**: If the user has specific goals (e.g. "earning miles") or financial constraints (e.g. "needs low APR"), factor this heavily into the decision.
3. 🧮 CALCULATE: Estimate the return value. Do NOT mention "requested valuation" or "at X valuation" in the output. Just state the result.

OUTPUT JSON:
{{
    "best_card_id": "Exact ID from list",
    "reasoning": [
        "Primary Reason (Merge math here if relevant: e.g. '3x Points on Dining is worth ~4.5%, beating your 2% card')",
        "Secondary Reason (e.g. 'Fits your goal of earning travel miles')",
        "Additional Context (if needed)"
    ],
    "estimated_return": "EXTREMELY SHORT. Max 3-4 words. (e.g. '4x Points' or '3% Cash Back' or '$50 Value')",
    "runner_up_id": "Optional ID of 2nd best",
    "runner_up_reasoning": ["Why it's second"],
    "runner_up_return": "e.g. '1.5% Cash Back'",
    "corrected_store_name": "Canonical Name (e.g. 'Starbucks') or null if invalid",
    "is_valid_store": true/false
}}
"""

TEST_CASES = [
    {"name": "Card Benefit Search", "prompt": SEARCH_CARD_PROMPT},
    {"name": "Store Recommendation", "prompt": RECOMMENDATION_PROMPT}
]

# ==========================================
# 2. RUNNER LOGIC (ASYNC)
# ==========================================

async def run_prompt_async(model_name, prompt, i):
    """Runs a single prompt on a specific model."""
    try:
        response = await client.aio.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
            )
        )
        return response.text
    except Exception as e:
        print(f"ERROR in run {i}: {e}")
        return f"ERROR: {str(e)}"

async def run_comparison_async(test_name, prompt):
    print(f"\n🚀 Running Test: {test_name}")
    print(f"   Prompt Length: {len(prompt)} chars")

    # Run Flash Concurrently
    print(f"   Starting {ITERATIONS} iterations on {MODEL_FLASH} (Parallel)...")
    tasks_flash = [run_prompt_async(MODEL_FLASH, prompt, i) for i in range(ITERATIONS)]
    results_flash = await asyncio.gather(*tasks_flash)
    print("   ✅ Flash Done.")

    # Run Pro Concurrently
    print(f"   Starting {ITERATIONS} iterations on {MODEL_PRO} (Parallel)...")
    tasks_pro = [run_prompt_async(MODEL_PRO, prompt, i) for i in range(ITERATIONS)]
    results_pro = await asyncio.gather(*tasks_pro)
    print("   ✅ Pro Done.")

    return {
        "flash": results_flash,
        "pro": results_pro
    }

# ==========================================
# 3. ANALYZER LOGIC
# ==========================================

async def analyze_results(test_name, results):
    print(f"   Analyzing results for {test_name} with {MODEL_PRO}...")
    
    full_flash_dump = "\n".join([f"=== FLASH OUTPUT {i+1} ===\n{out}\n" for i, out in enumerate(results["flash"])])
    full_pro_dump = "\n".join([f"=== PRO OUTPUT {i+1} ===\n{out}\n" for i, out in enumerate(results["pro"])])

    analysis_prompt = f"""
    You are an expert LLM Evaluator.
    I have run the same prompt {ITERATIONS} times on '{MODEL_FLASH}' and {ITERATIONS} times on '{MODEL_PRO}'.
    
    TEST NAME: {test_name}
    
    Here are the outputs:
    
    DATASET A ({MODEL_FLASH}):
    {full_flash_dump}
    
    DATASET B ({MODEL_PRO}):
    {full_pro_dump}
    
    TASK:
    Compare the quality, consistency, and correctness of the two models.
    1. **Consistency**: Is Flash less consistent than Pro? Do they both hallucinate?
    2. **Quality**: Is Pro's reasoning significantly better? 
    3. **Formatting**: Did both models follow JSON/formatting rules strictly?
    4. **Recommendation**: Can I safely switch to Flash for this prompt?
    
    Provide a concise summary comparison.
    """

    try:
        response = await client.aio.models.generate_content(
            model=MODEL_PRO, # Always use Pro for analysis
            contents=analysis_prompt
        )
        return response.text
    except Exception as e:
        return f"ANALYSIS ERROR: {str(e)}"

# ==========================================
# 4. MAIN EXECUTION
# ==========================================

async def main():
    if not os.path.exists("reports"):
        os.makedirs("reports")

    report_content = f"# Gemini Cards Comparison Report\nDate: {datetime.now()}\n\n"

    for test in TEST_CASES:
        results = await run_comparison_async(test["name"], test["prompt"])
        analysis = await analyze_results(test["name"], results)
        
        report_content += f"## Test: {test['name']}\n"
        report_content += f"### Analysis\n{analysis}\n\n"
        report_content += "---\n\n"
    
    with open(OUTPUT_FILE, "w") as f:
        f.write(report_content)
    
    print(f"\n✅ Comparison Complete. Report saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    asyncio.run(main())
