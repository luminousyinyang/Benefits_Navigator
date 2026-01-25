# Benefits Navigator 💳 ✨

**Benefits Navigator** is an AI-powered financial assistant designed to help you strictly maximize your credit card rewards, discover hidden benefits, and achieve your financial goals with personalized "Agentic" roadmaps.

Built with **SwiftUI** for a premium iOS experience and **FastAPI** + **Google Gemini 3.0 Flash** for intelligent backend processing.

---

## 🚀 Features

### 🧠 AI Card Intelligence
- **Instant Recognition**: Search for any credit card (e.g., "Amex Gold", "Sapphire Reserve"), and the app uses **Google Gemini + Google Search** to find the latest official benefits, earning rates, and perks.

### 💡 Smart Recommendations
- **Context-Aware Suggestions**: Buying coffee? Booking a flight? The app analyzes your specific wallet to recommend the *single best card* to use.
- **Strategy Modes**:
    - **Maximize Value**: Pure math (highest points/cashback multiplier).
    - **Category Priority**: "I need Flight Insurance" or "Extended Warranty" takes precedence over points.

### 🤖 Financial Agent
- **Goal Roadmaps**: Tell the Agent "I want a trip to Japan" or "I want to maximize cashback." It builds a step-by-step **Roadmap** (Milestones) to get you there (e.g., "Open Card X", "Hit Spend Requirement Y").
- **Active Tracking**: Tracks your sign-on bonuses and spending goals in real-time.

### 🛡️ Action Center
- **Price Protection**: Monitors price drops for recent purchases.
- **Warranty Manager**: Keeps track of extended warranty coverage.

---

## 🏗️ Architecture

```mermaid
graph TD
    User[📱 iOS User] -->|HTTPS / JSON| Client[iOS App (SwiftUI)]
    
    subgraph "Backend Services"
        Client -->|REST API| API[FastAPI Server]
        API -->|Background Jobs| Scheduler[APScheduler]
        API -->|Database & Auth| FB[(Firebase Firestore & Auth)]
    end
    
    subgraph "AI & External"
        API -->|GenAI Operations| Gemini[Google Gemini 3.0 Flash]
        Gemini -->|Grounding| Search[Google Search]
    end
```

---

## 🛠️ Project Structure

- **`/core`**: Python FastAPI Backend.
    - `app/main.py`: API Entry point and Routes.
    - `app/auth.py`: Firebase Authentication & Database logic.
    - `app/services/`: Business logic.
    - `Dockerfile`: Configuration for Google Cloud Run deployment.
- **`/ios`**: native iOS Client.
    - `Benefits_App/`: Main source code.
    - `Services/`: Networking layer (APIService, AgentService).
    - `Views/`: SwiftUI Views (MVVM architecture).

---

## ⚡ Getting Started

### Prerequisites

- **Backend**: Python 3.11+
- **Frontend**: macOS with Xcode 15+ (Targeting iOS 18+)
- **Cloud**: 
    - [Firebase Project](https://firebase.google.com/) (Auth & Firestore enabled)
    - [Google Cloud Project](https://console.cloud.google.com/) (Gemini API access)

### 🐍 Backend Setup (Core)

1.  **Navigate to the core directory**:
    ```bash
    cd core
    ```

2.  **Create and Activate Virtual Environment**:
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # Windows: venv\Scripts\activate
    ```

3.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configuration**:
    Create a `.env` file in `core/` with the following secrets:
    ```ini
    # Path to your Firebase Admin SDK JSON file
    FIREBASE_SERVICE_ACCOUNT_PATH=/absolute/path/to/serviceAccountKey.json
    
    # Firebase Web API Key (Project Settings > General)
    FIREBASE_WEB_API_KEY=AIzaSy...
    
    # Google Gemini API Key (aistudio.google.com)
    GEMINI_API_KEY=AIzaSy...
    ```
    > **Note**: You must download a `serviceAccountKey.json` from Firebase Console (Project Settings > Service Accounts) and place it in the `core/` folder or referenced path.

5.  **Run Locally**:
    ```bash
    cd app
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
    ```
    The API will be available at `http://localhost:8000`. API Docs at `http://localhost:8000/docs`.

### 🍎 iOS App Setup

1.  **Open Project**:
    Double-click `ios/Benefits_App/Benefits_App.xcodeproj` to open in Xcode.

2.  **Firebase Config**:
    - Download `GoogleService-Info.plist` from your Firebase Console (iOS App setup).
    - Drag and drop it into the `ios/Benefits_App/Benefits_App/Resources` folder in Xcode.
    - **Ensure "Copy items if needed" is checked.**

3.  **Configure API Endpoint**:
    - Open `ios/Benefits_App/Benefits_App/Services/APIService.swift`.
    - Modify the `baseURL` variable to point to your local backend for testing:
      ```swift
      // For Simulator
      static let baseURL = "http://127.0.0.1:8000" 
      // For Physical Device (same Wi-Fi)
      // static let baseURL = "http://192.168.1.5:8000"
      ```

4.  **Build & Run**:
    - Select a Simulator (e.g., iPhone 15 Pro) and press **Cmd+R**.

---

## 🚢 Deployment

### Docker & Cloud Run

The backend is containerized for easy deployment to **Google Cloud Run**.

1.  **Build & Submit**:
    ```bash
    cd core
    chmod +x deploy.sh
    ./deploy.sh [YOUR_PROJECT_ID]
    ```
    *Note: Ensure you have `gcloud` CLI installed and authenticated.*

2.  **Verify**:
    The script deploys to Cloud Run and outputs the public URL. Update your iOS `APIService.swift` with this URL for production usage.

---

## 📦 Tech Stack Details

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Backend** | Python 3.11 / FastAPI | High-performance async API framework. |
| **Database** | Firebase Firestore | NoSQL real-time database for user data/cards. |
| **Auth** | Firebase Auth | Secure email/password & social login. |
| **AI Model** | Gemini 3.0 Flash | Used for "Grounding" (Search) and Agent logic. |
| **Scheduling** | APScheduler | Handles background tasks. |
| **iOS** | Swift / SwiftUI | Modern reactive UI framework. |

---

## ⚠️ Troubleshooting

- **"AI Service Unavailable"**: Ensure `GEMINI_API_KEY` is set in your `.env` and the API key has access to `gemini-3-flash-preview` (or change model name in `main.py`).
- **Firebase Auth Errors**: Check that the `FIREBASE_WEB_API_KEY` matches the project in your `serviceAccountKey.json`.
- **iOS Connection Refused**: If running on Simulator, use `127.0.0.1`. If on a real device, ensure your Mac and iPhone are on the same Wi-Fi and use your Mac's local IP.

