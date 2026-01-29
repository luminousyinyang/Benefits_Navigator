import sys
import os
from unittest.mock import MagicMock, patch

# Ensure core app is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# 1. SETUP MOCKS BEFORE IMPORTING
mock_auth_module = MagicMock()
mock_auth_module.db = MagicMock()
mock_auth_module.auth = MagicMock()
sys.modules['auth'] = mock_auth_module

from services.marathon_agent import MarathonAgent

# Patch os.getenv to return a dummy key so Agent initializes
with patch.dict(os.environ, {"GEMINI_API_KEY": "dummy_key"}):
    
    # Mock Gemini Client
    with patch('google.genai.Client') as MockClient:
        
        # Intercept generate_content
        mock_generate = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "{}" 
        mock_generate.return_value = mock_response
        MockClient.return_value.models.generate_content = mock_generate
        
        # Instantiate Agent (now has key)
        agent = MarathonAgent()
        
        # Patch Auth DB for context
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"financial_details": "Test User"}
        mock_auth_module.db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_agent_doc = MagicMock()
        mock_agent_doc.exists = False
        mock_auth_module.db.collection.return_value.document.return_value.get.side_effect = [
            mock_user_doc, 
            mock_agent_doc, 
            MagicMock(exists=False)
        ]
        
        mock_auth_module.get_user_cards.return_value = [{"name": "Test Card"}]
        
        # Run Cycle
        print("Running Agent Cycle with Mocked Context & Key...")
        try:
            agent.run_agent_cycle("test_uid")
        except Exception as e:
            pass
            
        # Extract prompt
        call_args = mock_generate.call_args
        if call_args:
            kwargs = call_args[1]
            contents = kwargs.get('contents')
            print("\n----- GENERATED PROMPT SNIPPET -----\n")
            if "PROPORTIONALITY & SANITY CHECK" in contents:
                print("✅ Found 'PROPORTIONALITY & SANITY CHECK' section!")
                start_index = contents.find("PROPORTIONALITY & SANITY CHECK")
                end_index = contents.find("OUTPUT RULES", start_index)
                print(contents[start_index:end_index])
            else:
                print("❌ 'PROPORTIONALITY & SANITY CHECK' NOT FOUND in prompt.")
        else:
            print("❌ generate_content was not called.")
