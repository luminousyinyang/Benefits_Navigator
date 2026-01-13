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
            
            For each transaction, return a JSON object with:
            - "date": "YYYY-MM-DD" (The transaction date)
            - "retailer": "String" (The merchant name, cleaned up if possible)
            - "amount": Number (The transaction amount, positive for purchases, negative for credits/payments)
            - "card_name": "String" (The specific card product name, e.g., "Chase Sapphire Reserve", "Amex Gold", "Apple Card". Infer from the statement header or footer if not on every line. If unknown, use "Credit Card")
            
            Calculate "cashback_earned" based on the retailer category (assume 1% base if unknown, 3% for dining, 5% for travel).
            
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
                model='gemini-3-pro-preview',
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
                    response_mime_type='application/json'
                )
            )

            # Parse Response
            text = response.text.strip()
            # Handle markdown code blocks if present
            if text.startswith("```json"): text = text[7:]
            if text.endswith("```"): text = text[:-3]
            
            data = json.loads(text)
            return data.get("transactions", [])

        except Exception as e:
            print(f"❌ Gemini Processing Error: {e}")
            raise e
