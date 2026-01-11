import google.generativeai as genai
from google.generativeai import protos
import os

def test_tool_config():
    print("Testing Tool instantiation...")
    
    t = protos.Tool()
    
    # Check what fields are actually present on the instance
    # Usually printing the object shows empty fields or we can try setting them
    
    try:
        t.google_search = protos.GoogleSearch()
        print("✅ t.google_search assigned successfully.")
    except Exception as e:
        print(f"❌ Failed to assign t.google_search: {e}")
        
    try:
        t.google_search_retrieval = protos.GoogleSearchRetrieval()
        print("✅ t.google_search_retrieval assigned successfully.")
    except Exception as e:
        print(f"❌ Failed to assign t.google_search_retrieval: {e}")

    # Inspect the keys in the proto wrapper
    print(f"Proto fields keys: {t}")

if __name__ == "__main__":
    test_tool_config()
