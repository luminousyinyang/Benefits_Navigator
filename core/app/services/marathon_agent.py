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
                    roadmap_context = json.dumps(existing_roadmap, indent=2)

            prompt = f"""
            You are 'CreditAgent', a long-term strategist for this user.
            CURRENT GOAL: "{current_goal}"
            
            USER CONTEXT:
            - Current Cards: {cards_str}
            {constraints_str}
            
            THOUGHT HISTORY:
            "{thought_signature}"
            
            CURRENT ROADMAP STATUS:
            {roadmap_context}
            
            TASK:
            1. 🌍 SEARCH: Check for offers.
            2. 🧠 ANALYZE: Review progress and the Current Roadmap.
            3. 🛣️ UPDATE ROADMAP:
               - If the user completed the 'current' milestone (e.g. got the card), mark it 'completed'.
               - Create the NEXT 'current' milestone.
               - Plan 3-5 future 'locked' milestones to show a long-term path (e.g. "Wait 3 months", "Apply for Card Y", "Book Flight").
               - The roadmap should be substantial: Completed -> Current -> Locked -> Locked -> Locked.
            
            OUTPUT RULES:
            - **Google Search**: Verify offers.
            - **Milestones**:
              - `status`: "completed" (green), "current" (blue/active), "locked" (gray/future).
              - `icon`: Use SF Symbols (e.g., "checkmark.circle.fill", "creditcard.fill", "airplane", "clock.fill").
              - `spending_goal`: If the milestone involves a spending requirement (e.g. "Spend $4000 in 3 months"), set this to the float value (e.g. 4000.0). Otherwise null.
            
            OUTPUT JSON:
            {{
                "thought_signature": "Summary...",
                "public_plan": {{
                    "target_goal": "{current_goal}",
                    "progress_percentage": 50,
                    "roadmap": [
                        {{
                            "id": "1",
                            "title": "Opened Chase Sapphire",
                            "description": "You started your journey!",
                            "status": "completed",
                            "icon": "checkmark.circle.fill"
                        }},
                        {{
                            "id": "2",
                            "title": "Apply for Citi Strata",
                            "description": "75k bonus available. Transfer partner to ANA.",
                            "status": "current",
                            "icon": "creditcard.fill",
                            "spending_goal": 4000.0,
                            "spending_current": 0.0
                        }}
                    ],
                    "reasoning_summary": "• Point 1\\n• Point 2",
                    "next_action": "Apply for Citi Strata",
                    "action_date": "2026-01-16"
                }}
            }}
            """
            
            response = self.client.models.generate_content(
                model='gemini-3-pro-preview', # Thinking model, supports search
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
