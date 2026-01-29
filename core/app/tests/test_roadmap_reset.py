import sys
import os
from unittest.mock import MagicMock

# 1. SETUP MOCKS BEFORE IMPORTING APP
# We must mock 'auth' because importing 'main' triggers 'import auth',
# which triggers Firebase initialization that fails in test env.

# Create a mock auth module
mock_auth_module = MagicMock()
# Mock db for Firestore
mock_auth_module.db = MagicMock()
# Mock auth for Firebase Auth
mock_auth_module.auth = MagicMock()
# Mock other functions used in main.py to prevent AttributeErrors on import or usage
mock_auth_module.create_user = MagicMock()
mock_auth_module.verify_password = MagicMock()
mock_auth_module.refresh_access_token = MagicMock()
mock_auth_module.get_user_profile = MagicMock()
mock_auth_module.update_user_profile = MagicMock()
mock_auth_module.set_onboarded = MagicMock()
mock_auth_module.get_card_suggestions = MagicMock()
mock_auth_module.get_all_card_names = MagicMock()
mock_auth_module.get_global_card = MagicMock()
mock_auth_module.save_global_card = MagicMock()
mock_auth_module.get_user_cards = MagicMock()
mock_auth_module.add_user_card = MagicMock()
mock_auth_module.remove_user_card = MagicMock()

# Explicitly ensure models are available if they were imported FROM auth (unlikely but safe)
# Looking at code, models are imported from 'models.py', so we are good.

# Inject into sys.modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.modules['auth'] = mock_auth_module
# Also mock router.agent.auth which might allow refined patching if needed,
# but since we infect sys.modules['auth'], any 'import auth' gets this mock.

# 2. NOW IMPORT APP
from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch

# Initialize Client
client = TestClient(app)

# Mock Auth Dependency
async def mock_get_current_user():
    return {"uid": "test_user_123", "email": "test@example.com"}

# Override dependency
# We need to import the exact function objects referenced in the routers to override them
from routers.agent import get_current_user as agent_get_user
from routers.actions import get_current_user as actions_get_user
from main import get_current_user as main_get_user

app.dependency_overrides[agent_get_user] = mock_get_current_user
app.dependency_overrides[actions_get_user] = mock_get_current_user
app.dependency_overrides[main_get_user] = mock_get_current_user

def test_start_agent_resets_roadmap():
    print("Testing POST /agent/start resets roadmap...")
    
    # We can rely on our global mock_auth_module or patch specifically for this test
    # Let's clean up the mock for this test run
    mock_auth_module.db.reset_mock()
    
    # Setup Mock DB Chain: db.collection().document().collection().document()
    mock_user_ref = MagicMock()
    mock_public_ref = MagicMock()
    
    # db.collection('users').document(uid)
    start_doc = MagicMock()
    mock_auth_module.db.collection.return_value.document.return_value = start_doc
    # .collection('public_agent_state').document('main')
    start_doc.collection.return_value.document.return_value = mock_public_ref
    
    # Patch MarathonAgent to avoid actual AI/Background calls
    with patch("routers.agent.MarathonAgent") as MockAgent:
        
        mock_instance = MockAgent.return_value
        mock_instance.run_agent_cycle = MagicMock()
        
        response = client.post("/agent/start", json={"goal": "Fly to Tokyo"})
        
        assert response.status_code == 200
        assert response.json()["status"] == "started"
        
        # Verify that set was called with empty lists for roadmap and optional_tasks
        mock_public_ref.set.assert_called_with({
            "target_goal": "Fly to Tokyo",
            "status": "thinking",
            "error_message": None,
            "roadmap": [],
            "progress_percentage": 0,
            "reasoning_summary": "Agent is starting...",
            "optional_tasks": []
        }, merge=True)
        
        print("✅ Roadmap reset verified")

if __name__ == "__main__":
    test_start_agent_resets_roadmap()
    print("\n🎉 Verification Test Passed!")
