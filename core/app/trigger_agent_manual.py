
import firebase_admin
from firebase_admin import credentials, firestore
import os
from services.marathon_agent import MarathonAgent
from dotenv import load_dotenv

# Load env vars
load_dotenv()

# Initialize Firebase (if not already, though MarathonAgent imports auth which does it)
# We need to make sure we don't double init if auth.py does it globally on import
# auth.py initializes it.
import auth

def run_manual():
    uid = "ns13zuz7arbfGKTDFdbSKLpLYLE3" # From logs
    print(f"Triggering agent for {uid}...")
    
    agent = MarathonAgent()
    agent.run_agent_cycle(uid)
    print("Done!")

if __name__ == "__main__":
    run_manual()
