import os
import json
import time
from datetime import datetime, date
from google import genai
from google.genai import types
import auth
from models import AgentPrivateState, AgentPublicState
import services.constraints as constraints
from firebase_admin import firestore

class MarathonAgent:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            self.client = genai.Client(api_key=self.api_key)
        else:
            self.client = None
            print("⚠️ MarathonAgent: GEMINI_API_KEY missing.")

    def run_agent_cycle(self, user_id: str):
        """
        The Core Loop: Wake Up -> Think -> Act -> Sleep.
        """
        print(f"🏃‍♂️ MarathonAgent: Starting cycle for {user_id}")
        
        try:
            # 1. WAKE UP: Fetch Context & State
            user_ref = auth.db.collection('users').document(user_id)
            user_doc = user_ref.get()
            if not user_doc.exists:
                print(f"❌ User {user_id} not found.")
                return

            user_data = user_doc.to_dict()
            agent_sessions_ref = auth.db.collection('agent_sessions').document(user_id)
            agent_doc = agent_sessions_ref.get()
            
            # Restore Thought Signature
            thought_signature = ""
            if agent_doc.exists:
                private_state = agent_doc.to_dict()
                thought_signature = private_state.get('thought_signature', "")
            
            # Fetch Wallet & Transactions (Context)
            # We need a snapshot of recent financial activity to "jog the memory"
            cards = auth.get_user_cards(user_id)
            # Fetch recent transactions (last 30 days) - simplified for now
            # In real app, we might want to query subcollection
            
            # 2. THINK: Call Gemini 3
            if not self.client:
                print("❌ No AI Client available.")
                return

            # Construct Prompt
            cards_str = ", ".join([c['name'] for c in cards])
            
            # Inject Constraints Context
            # We calculate these deterministically and feed them to the AI so it doesn't hallucinate rules.
            # Convert cards to simple list of dicts for the helper if needed, or just iterate.
            # For 5/24 we need dates. 'get_user_cards' returns dicts. 
            # We assume 'date_opened' is in the card data or we might be missing it in simple model.
            # For now, let's assume we pass what we have.
            
            # Retrieve 'opened_cards_history' roughly from current wallet? 
            # If we don't have dates, we can't truly check 5/24. 
            # Let's assume for this MVP we might not have perfect dates yet, 
            # so we tell the AI "Assume 5/24 status is: SAFE/BLOCKED" if we had the data.
            # Since constraints.py is hardcoded, let's try to use it if data exists.
            
            # Placeholder for opened stats
            is_under_5_24 = True # Default safe if unknown
            # is_under_5_24 = constraints.check_5_24_status(cards) # If cards had dates
            
            # Velocity check
            # last_app_date = user_data.get('last_application_date')
            # is_velocity_safe = constraints.check_velocity(last_app_date)
            is_velocity_safe = True 

            constraints_str = f"""
            HARD CONSTRAINTS STATUS:
            - 5/24 Rule Status: {"✅ SAFE" if is_under_5_24 else "❌ BLOCKED (>4 cards in 24mo)"}
            - Velocity Status: {"✅ SAFE" if is_velocity_safe else "❌ BLOCKED (Recent application)"}
            
            If BLOCKED, do NOT recommend applying for a new card.
            """

            current_goal = "Optimize Credit & Travel" # Default
            # If public state exists, maybe grab goal from there? 
            # Or usually goal is set once. Let's look for it in Public State or User Profile.
            public_ref = auth.db.collection('users').document(user_id).collection('public_agent_state').document('main')
            public_doc = public_ref.get()
            
            roadmap_context = "No previous roadmap."
            if public_doc.exists:
                data = public_doc.to_dict()
                current_goal = data.get('target_goal', current_goal)
                existing_roadmap = data.get('roadmap', [])
                if existing_roadmap:
                    # Enrich context with icons to help stability
                    roadmap_context = "CURRENT MILESTONES (Preserve these unless changing strategy):\n"
                    for m in existing_roadmap:
                        icon = m.get('icon', 'map.fill')
                        status = m.get('status', 'pending')
                        roadmap_context += f"- [{status}] {m.get('title')} (Icon: {icon})\n"

            # Retrieve Financial Context
            financial_profile_str = ""
            if user_data:
                financial_profile_str = f"""
                FINANCIAL PROFILE:
                - Details: {user_data.get('financial_details', 'None')}
                """

            prompt = f"""
            You are 'CreditAgent', a long-term strategist for this user.
            CURRENT GOAL: "{current_goal}"
            
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
                    "target_goal": "{current_goal}",
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
            
            response = self.client.models.generate_content(
                model='gemini-3-flash-preview', 
                contents=prompt,
                config=types.GenerateContentConfig(
                    tools=[types.Tool(google_search=types.GoogleSearch())],
                    response_mime_type='application/json'
                )
            )

            text = response.text.strip()
            if text.startswith("```json"): text = text[7:]
            if text.endswith("```"): text = text[:-3]
            
            result = json.loads(text)
            
            new_thought_signature = result.get('thought_signature', "")
            public_plan = result.get('public_plan', {})
            
            # 3. ACT / SLEEP: Persist State
            
            # Save Private State (The Brain)
            agent_sessions_ref.set({
                "thought_signature": new_thought_signature,
                "last_run_date": datetime.now().isoformat(),
                "next_scheduled_action": public_plan.get('action_date')
            }, merge=True)
            
            # Save Public State (The UI)
            # Ensure we keep the target_goal if not returned (it might not be)
            if 'target_goal' not in public_plan:
                public_plan['target_goal'] = current_goal
            
            # Set status to idle so the UI stops spinning
            public_plan['status'] = "idle"
                
            public_ref.set(public_plan, merge=True)
            
            print(f"✅ Agent Cycle Complete. Next Action: {public_plan.get('next_action')}")

        except Exception as e:
            print(f"❌ MarathonAgent Error: {e}")
            raise e
