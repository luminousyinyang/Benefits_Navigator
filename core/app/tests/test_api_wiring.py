import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch, MagicMock
from models import AgentStartRequest

# Initialize Client
client = TestClient(app)

# Mock Auth Dependency
async def mock_get_current_user():
    return {"uid": "test_user_123", "email": "test@example.com"}

# Override dependency
# Note: In main.py, get_current_user is used. And in routers/agent.py request also uses it.
# We need to override it in the app.dependency_overrides
from routers.agent import get_current_user as agent_get_user
from routers.actions import get_current_user as actions_get_user
from main import get_current_user as main_get_user

app.dependency_overrides[agent_get_user] = mock_get_current_user
app.dependency_overrides[actions_get_user] = mock_get_current_user
app.dependency_overrides[main_get_user] = mock_get_current_user

def test_start_agent():
    print("Testing POST /agent/start...")
    
    with patch("routers.agent.MarathonAgent") as MockAgent, \
         patch("routers.agent.auth.db") as mock_db: # Mock DB to avoid Firestore calls
        
        # Setup Mock Agent
        mock_instance = MockAgent.return_value
        mock_instance.run_agent_cycle = MagicMock()
        
        # Setup Mock DB
        mock_user_ref = MagicMock()
        mock_public_ref = MagicMock()
        mock_db.collection.return_value.document.return_value = mock_user_ref
        mock_user_ref.collection.return_value.document.return_value = mock_public_ref
        
        response = client.post("/agent/start", json={"goal": "Fly to Tokyo"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "started"
        print("✅ /agent/start success")
        
        # Verify Background Task was added (TestClient runs bg tasks synchronously unless configured otherwise? 
        # TestClient actually executes background tasks).
        # But we patched MarathonAgent class.
        # Wait, inside `start_agent`:
        # agent = MarathonAgent()
        # background_tasks.add_task(agent.run_agent_cycle, uid)
        
        # Verify instantiation
        MockAgent.assert_called_once()
        # Verify run_agent_cycle calls
        # Since TestClient executes bg tasks, it should have been called.
        mock_instance.run_agent_cycle.assert_called_with("test_user_123")
        print("✅ Background task triggered")

def test_trigger_agent_debug():
    print("\nTesting POST /actions/trigger-agent...")
    
    with patch("routers.actions.MarathonAgent") as MockAgent:
         mock_instance = MockAgent.return_value
         mock_instance.run_agent_cycle = MagicMock()
         
         response = client.post("/actions/trigger-agent")
         
         assert response.status_code == 200
         mock_instance.run_agent_cycle.assert_called_with("test_user_123")
         print("✅ /trigger-agent success")

if __name__ == "__main__":
    test_start_agent()
    test_trigger_agent_debug()
    print("\n🎉 All API Tests Passed!")
