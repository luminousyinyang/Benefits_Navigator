import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch, MagicMock

client = TestClient(app)

# Mock Auth
async def mock_get_current_user():
    return {"uid": "test_user_123", "email": "test@example.com"}

from routers.actions import get_current_user as actions_get_user
app.dependency_overrides[actions_get_user] = mock_get_current_user

def test_debug():
    print("Debugging POST /actions/trigger-agent...")
    
    with patch("routers.actions.MarathonAgent") as MockAgent:
         mock_instance = MockAgent.return_value
         mock_instance.run_agent_cycle = MagicMock()
         
         response = client.post("/actions/trigger-agent")
         
         print(f"Status Code: {response.status_code}")
         print(f"Response Body: {response.json()}")
         
         if response.status_code != 200:
             print("❌ Failed")
         else:
             print("✅ Success")

if __name__ == "__main__":
    test_debug()
