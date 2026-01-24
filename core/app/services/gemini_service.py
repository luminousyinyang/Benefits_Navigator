import os
import json
import base64
from typing import List, Dict, Any
from google import genai
from google.genai import types

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            print("⚠️ GEMINI_API_KEY not set. Gemini features will fail.")
        self.client = genai.Client(api_key=self.api_key)

    def process_statement(self, pdf_bytes: bytes) -> List[Dict[str, Any]]:
        """
        Uploads PDF bytes to Gemini and extracts transaction data.
        """
        try:
            # Optimize: Upload the file contents directly if supported or pass as inline data
            # For 'gemini-3-pro-preview', passing bytes directly as inline data is often efficient for reasonable sizes.
            
            prompt = """
            Analyze this credit card statement PDF.
            Extract ALL individual transactions from the statement period.
            
            1. **IDENTIFY CARD**: First, identify the exact credit card name from the statement (e.g., "Chase Sapphire Reserve", "Amex Gold").
            2. **RESEARCH BENEFITS**: Use Google Search to find the OFFICIAL reward structure for this specific card (e.g. "Chase Sapphire Reserve current points multipliers"). Look for categories like Dining, Travel, Grocery, etc.
            3. **EXTRACT TRANSACTIONS**: For each transaction:
               - "date": "YYYY-MM-DD" (The transaction date)
               - "retailer": "String" (CLEAN THE RETAILER NAME. e.g. "CHIPOTLE MEX GR ONLINE" -> "Chipotle", "UBER *RIDE" -> "Uber". If the name is already clean or ambiguous, keep it.)
               - "amount": Number (The transaction amount, positive for purchases, negative for credits/payments).
               - "card_name": "String" (The specific card product name, e.g., "Chase Sapphire Reserve", "Amex Gold". Infer from the statement content. If unknown, use "Credit Card")
               - "cashback_earned": Number. **CRITICAL**: Calculate this using the RESEARCHED reward structure if the cashback per transaction isn't explicitly stated in the statement. Determine the retailer's category (e.g. Chipotle = Dining) and apply the correct multiplier (e.g. 3x or 3%). If the category is 1x/1%, calculate 1%.
            
            Return the result as a strictly formatted JSON object with a "transactions" key containing the list.
            Example:
            {
                "transactions": [
                    {
                        "date": "2023-10-15",
                        "retailer": "Starbucks",
                        "amount": 5.40,
                        "card_name": "Chase Sapphire Preferred",
                        "cashback_earned": 0.16
                    }
                ]
            }
            """

            response = self.client.models.generate_content(
                model='gemini-3-flash-preview',
                contents=[
                    types.Content(
                        parts=[
                            types.Part(text=prompt),
                            types.Part(
                                inline_data=types.Blob(
                                    mime_type='application/pdf',
                                    data=pdf_bytes
                                )
                            )
                        ]
                    )
                ],
                config=types.GenerateContentConfig(
                    tools=[types.Tool(google_search=types.GoogleSearch())],
                    response_mime_type='application/json'
                )
            )

            # Parse Response
            text = response.text.strip()
            
            # Robust JSON extraction: Find the first '{' and last '}'
            import re
            
            # Try to find a JSON code block first
            match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
            if match:
                json_str = match.group(1)
            else:
                # Fallback: Find outermost braces
                start = text.find('{')
                end = text.rfind('}') + 1
                if start != -1 and end != 0:
                    json_str = text[start:end]
                else:
                     # Last resort: just try the whole text
                    json_str = text

            try:
                data = json.loads(json_str)
                return data.get("transactions", [])
            except json.JSONDecodeError:
                print(f"❌ JSON Decode Error. Raw text: {text}")
                return []

        except Exception as e:
            print(f"❌ Gemini Processing Error: {e}")
            raise e
