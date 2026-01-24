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
    exit(1)

client = genai.Client(api_key=API_KEY)

MODEL_FLASH = "gemini-3-flash-preview"
MODEL_PRO = "gemini-3-pro-preview"
ITERATIONS = 10
OUTPUT_FILE = "gemini_comparison_report.md"

# ==========================================
# 1. DEFINE PROMPTS & MOCK CONTEXT
# ==========================================

# --- MARATHON AGENT PROMPT ---
MOCK_CARDS_STR = "Chase Sapphire Reserve, Amex Gold, Citi Custom Cash"
MOCK_FINANCIAL_PROFILE = """
FINANCIAL PROFILE:
- Details: High spender on dining and travel. Good credit score. Interested in maximizing points for international flights.
"""
MOCK_CONSTRAINTS = """
HARD CONSTRAINTS STATUS:
- 5/24 Rule Status: ✅ SAFE
- Velocity Status: ✅ SAFE

If BLOCKED, do NOT recommend applying for a new card.
"""
MOCK_THOUGHT_SIGNATURE = "User is focusing on travel points. Previous advice was to hold off on new applications until next month."
MOCK_ROADMAP_CONTEXT = """
CURRENT MILESTONES (Preserve these unless changing strategy):
- [pending] Reach Amex Gold Bonus (Icon: star.fill)
"""

MARATHON_PROMPT_TEMPLATE = """
You are 'CreditAgent', a long-term strategist for this user.
CURRENT GOAL: "Optimize Credit & Travel"

USER CONTEXT:
- Current Cards: {cards_str}
{financial_profile_str}
{constraints_str}

THOUGHT HISTORY:
"{thought_signature}"

CURRENT ROADMAP STATUS:
{roadmap_context}

STABILITY RULES (CRITICAL):
1. 🛑 PRESERVE EXISTING: Do NOT change the Title or Icon of existing milestones unless the strategy fundamentally changes. If a milestone is 'completed', keep it exactly as is.
2. 🛑 ONE CURRENT STEP: Only ONE milestone can be `current` at any time. If multiple tasks are active, pick the most immediate one as `current` and others as `pending`.
3. 🛑 ICONS: Use ONLY simple, valid SF Symbols.
   - SAFE: map.fill, creditcard.fill, airplane, cart.fill, house.fill, star.fill, list.bullet
   - AVOID: complex symbols or those with multiple dots/badges (e.g. 'creditcard.triangle.badge...').
   - If unsure, use 'map.fill' or 'star.fill'.

TASK:
1. 🔍 CHECK USER UPDATES: Scan current milestones for `user_notes`. If the user has flagged a roadblock (e.g., "Rejected", "Too expensive", "Don't want to"), you MUST adjust the plan accordingly.
2. 🌍 DEEP WEB SEARCH: 
   - If this is a **NEW GOAL** (roadmap empty), search extensively to build the best strategy from scratch.
   - If this is a **WEEKLY RUN**, search for *new* offers or changes that might accelerate the goal.
   - Search for solutions to any user roadblocks.
3. 🧠 ANALYZE: Review progress, spending habits, and the Current Roadmap against search results.
4. 🛣️ UPDATE ROADMAP:
   - Update milestones based on new findings or user updates.
   - **IMPORTANT**: If a milestone is "current" but the user says they are stuck, either provide a solution in `description` or replace it with a new step.
   - **SPLIT TASKS**: When recommending a new card, create TWO separate milestones:
     1. "Apply for [Card]" (Status: current. NO `spending_goal`).
     2. "Reach [Card] Bonus" (Status: pending. Set `spending_goal` equal to the bonus requirement here).
5. ⚔️ SIDE QUESTS (OPTIONAL TASKS):
   - Identify 2-3 "Side Quests" based on their financial profile or potential bad habits (e.g., "Dining out too much? -> Cook at home", "Unused Subscriptions? -> Cancel").
   - Also look for "Card Perks" side quests (e.g., "Activate Amex Offers", "Use your $50 Hotel Credit").

OUTPUT RULES:
- **Google Search**: Verify offers.
- **Milestones**: Same rules as before.
- **Optional Tasks**:
  - `id`: Unique string.
  - `title`: Short action title.
  - `description`: Why they should do it.
  - `impact`: Estimated savings or value (e.g. "$20/mo").
  - `category`: "Savings" | "Credit Health" | "Lifestyle".
  - `icon`: SF Symbol (e.g. "fork.knife", "dollarsign.circle", "tag.fill").

OUTPUT JSON:
{{
    "thought_signature": "Summary...",
    "public_plan": {{
        "target_goal": "Optimize Credit & Travel",
        "progress_percentage": 50,
        "roadmap": [...],
        "optional_tasks": [
            {{
                "id": "sq_1",
                "title": "Cook Dinner 3x/Week",
                "description": "You spent $450 on dining last week. Cooking could save you significantly.",
                "impact": "Save ~$200/mo",
                "category": "Lifestyle",
                "icon": "fork.knife"
            }}
        ],
        "reasoning_summary": "...",
        "next_action": "Apply for Citi Strata",
        "action_date": "2026-01-16"
    }}
}}
"""

MARATHON_PROMPT_FINAL = MARATHON_PROMPT_TEMPLATE.format(
    cards_str=MOCK_CARDS_STR,
    financial_profile_str=MOCK_FINANCIAL_PROFILE,
    constraints_str=MOCK_CONSTRAINTS,
    thought_signature=MOCK_THOUGHT_SIGNATURE,
    roadmap_context=MOCK_ROADMAP_CONTEXT
)


# --- ACTION HELP PROMPT ---
MOCK_CATEGORY_CONTEXT = "Price Protection"
MOCK_CARD_NAME = "Chase Sapphire Reserve"
MOCK_USER_NOTES = "I bought a TV at Best Buy for $1000 and now it's $800. I want to get the difference back."
MOCK_ITEM_DETAILS = """
Retailer: Best Buy
Date: 2023-11-01
Total: $1000.00
Item: Sony 65" OLED TV
"""

ACTION_HELP_PROMPT = f"""
The user is asking for assistance with **{MOCK_CATEGORY_CONTEXT}** on their **{MOCK_CARD_NAME}**.

TRANSACTION DETAILS:
{MOCK_ITEM_DETAILS}

USER'S SITUATION / ISSUE:
"{MOCK_USER_NOTES}"

TASK:
Provide a **short, super concise, step-by-step instruction set** on how to proceed. 
The output will be displayed in a mobile app, so formatting must be clean and minimal.

- Focus on exactly what they need to do (e.g., "File a claim at [URL]", "Call 1-800-...", "Upload receipt").
- Do not give generic advice if specific card details are known (infer from card name if possible, or give general best practice for that issuer).
- Use clear headings or bullet points.
"""

TEST_CASES = [
    {"name": "Marathon Agent Planning", "prompt": MARATHON_PROMPT_FINAL},
    {"name": "Action Center Help", "prompt": ACTION_HELP_PROMPT}

]

# ==========================================
# 2. RUNNER LOGIC (ASYNC)
# ==========================================

async def run_prompt_async(model_name, prompt, i):
    """Runs a single prompt on a specific model."""
    try:
        # print(f"DEBUG: Starting {model_name} run {i}")
        response = await client.aio.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
            )
        )
        # print(f"DEBUG: Finished {model_name} run {i}")
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
    report_content = f"# Gemini Comparison Report\nDate: {datetime.now()}\n\n"

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
