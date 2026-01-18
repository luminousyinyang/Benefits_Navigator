# Benefits Navigator 💳🚀

**Benefits Navigator** is an AI-powered financial assistant designed to help you maximize your credit card rewards, discover hidden perks, and achieve long-term financial goals. Built for the **Gemini 3 Hackathon**, it leverages Google's latest **Gemini 3 models** with **Google Search Grounding** to provide real-time, accurate financial advice.

## 🌟 Key Features

*   **🧠 AI-Powered Card Search**: Instantly find detailed benefits, earning rates, and multipliers for *any* credit card. Gemini acts as a researcher, finding the official "Guide to Benefits" to ensure accuracy rather than relying on generic data.
*   **🛍️ Smart Recommendations**: Not sure which card to use at checkout? The app analyzes your specific wallet and the store you're visiting (e.g., "Whole Foods", "Delta Airlines") to recommend the single best card. It considers:
    *   **Value**: Highest cashback or points multiplier.
    *   **Protection**: Purchase protection, extended warranty, or travel insurance if relevant.
    *   **User Goals**: Prioritizes miles vs. cash back based on your preferences.
*   **🏃‍♂️ Marathon Agent**: A background "strategist" agent that monitors your progress. It:
    *   Creates a dynamic **Financial Roadmap** (e.g., "Apply for Card X", "Spend $4k in 3 months").
    *   Tracks sign-up bonus progress.
    *   Updates plans based on new offers or life changes.
*   **📱 Native iOS Experience**: A sleek, dark-themed SwiftUI application to manage your wallet, view the roadmap, and get quick recommendations.

---

## 🏗️ Architecture

The project consists of a Python FastAPI backend and a native iOS frontend.

### 🐍 Backend (`core/`)
*   **Framework**: FastAPI
*   **Database**: Firebase Firestore (User data, Wallet, Agent State)
*   **Auth**: Firebase Authentication
*   **AI Engine**: Google Gemini 3 Pro Preview (via `google-genai` SDK)
*   **Key Services**:
    *   `marathon_agent.py`: The long-running loop that acts as your financial strategist.
    *   `main.py`: REST API for the iOS app.
    *   `gemini_service.py`: Wrappers for robust AI interactions.

### 🍎 iOS App (`ios/`)
*   **Framework**: SwiftUI
*   **Architecture**: MVVM
*   **Features**:
    *   **Wallet View**: Digital representation of your cards.
    *   **Agent View**: Visual roadmap of your financial journey.
    *   **Scanner/Search**: Input for getting card recommendations.

---

## 🚀 Getting Started

### Prerequisites
*   Python 3.10+
*   Xcode 15+ (for iOS App)
*   Firebase Project (with Firestore and Auth enabled)
*   Google Gemini API Key

### 1. Backend Setup
Navigate to the `core` directory:

```bash
cd core
```

Create a virtual environment and install dependencies:

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Set up environment variables:
Create a `.env` file in `core/` with:
```bash
GEMINI_API_KEY=your_gemini_api_key_here
```
*Also place your Firebase `serviceAccountKey.json` in the `core/` directory.*

Run the server:
```bash
python app/main.py
```
*The server will start at `http://0.0.0.0:8000`*

### 2. iOS App Setup
1.  Open `ios/Benefits_App/Benefits_App.xcodeproj` in Xcode.
2.  Ensure you have your `GoogleService-Info.plist` (Firebase config) added to the project.
3.  Update the `APIService.swift` (or relevant network file) to point to your local backend IP if testing on a physical device, or `localhost` for simulator.
4.  Build and run!

### 3. Firestore Indexes
For the Price Protection monitoring job to work, you must create a **Collection Group Index**.
*   **Collection ID**: `price_protection`
*   **Field**: `monitor_price`
*   **Mode**: Ascending

If you see a "requires a COLLECTION_GROUP_ASC index" error in your server logs, click the link provided in the error message to automatically create this index in the Firebase Console.

---

## 🤖 AI Logic (The "Magic")

### Card Search Prompting
We don't just ask "What are the benefits?". We use **Chain of Thought** prompting to force Gemini to:
1.  Identify the card issuer.
2.  Search for the *PDF Guide to Benefits*.
3.  Extract specific multipliers (e.g., "4x on Dining").
4.  Group benefits logically.

### Marathon Agent
The agent follows a **Wake -> Think -> Act -> Sleep** cycle:
1.  **Wake**: Loads user state and "Thought Signature" (memory of previous reasoning).
2.  **Think**: Uses Gemini to analyze the user's progress against the roadmap. It can "lock" future steps or "complete" current ones.
3.  **Act**: Updates the Firestore database with the new public plan.
4.  **Sleep**: Schedules the next check-in.

---

## 📄 License
Created for the Gemini 3 Hackathon.
