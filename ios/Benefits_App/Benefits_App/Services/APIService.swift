import Foundation

class APIService {
    static let shared = APIService()
    
    // Configuration
    // Use "http://127.0.0.1:8000" for iOS Simulator
    // Use your machine's IP address (e.g. "http://192.168.1.5:8000") for physical device
    private let baseURL = "http://10.126.172.26:8000"

    private init() {}

    private(set) var authToken: String?
    private(set) var refreshTokenString: String?
    private(set) var tokenExpiryDate: Date?
    
    func clearSession() {
        self.authToken = nil
        self.refreshTokenString = nil
        self.tokenExpiryDate = nil
    }
    
    func setSession(_ token: AuthToken) {
        self.authToken = token.id_token
        self.refreshTokenString = token.refresh_token
        
        if let expiresInStr = token.expires_in, let seconds = Double(expiresInStr) {
            self.tokenExpiryDate = Date().addingTimeInterval(seconds)
        } else {
            // Default 1 hour if missing
             self.tokenExpiryDate = Date().addingTimeInterval(3600)
        }
    }
    
    // Legacy support (rename or keep)
    func setToken(_ token: String) {
        self.authToken = token
    }
    
    func setFullSession(authToken: String, refreshToken: String?, expiry: Date?) {
        self.authToken = authToken
        self.refreshTokenString = refreshToken
        self.tokenExpiryDate = expiry
    }
    
    // MARK: - Auth

    func signup(email: String, password: String, firstName: String, lastName: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/signup") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "first_name": firstName,
            "last_name": lastName
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 201 {
             if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let uid = json["uid"] as? String {
                 return uid
             }
             return "Success"
        } else {
             // Try to parse error message
             if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let detail = json["detail"] as? String {
                 throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
             }
            throw URLError(.badServerResponse)
        }
    }

    func login(email: String, password: String) async throws -> AuthToken {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 200 {
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            self.setSession(token) // Use unified session setter
            return token
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - User
    
    func fetchUser() async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/me") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func completeOnboarding() async throws {
        guard let url = URL(string: "\(baseURL)/me/onboarding") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Cards
    
    func searchCard(query: String) async throws -> Card {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/cards/search?query=\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                throw NSError(domain: "APIService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card not found. Please try a different name."])
            }
            if httpResponse.statusCode == 503 {
                throw NSError(domain: "APIService", code: 503, userInfo: [NSLocalizedDescriptionKey: "AI Service Unavailable. Please check your Backend GEMINI_API_KEY."])
            }
            if httpResponse.statusCode != 200 {
                 // Try to decode error message
                 if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let detail = json["detail"] as? String {
                     throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
                 }
                 throw URLError(.badServerResponse)
            }
        }
        
        return try JSONDecoder().decode(Card.self, from: data)
    }
    
    func fetchCardSuggestions(query: String) async throws -> [String] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/cards/auto?query=\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let suggestions = json["suggestions"] as? [String] {
            return suggestions
        }
        return []
    }
    
    func fetchUserCards() async throws -> [UserCard] {
        guard let url = URL(string: "\(baseURL)/me/cards") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([UserCard].self, from: data)
    }
    
    func addUserCard(card: UserCard) async throws {
        guard let url = URL(string: "\(baseURL)/me/cards") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(card)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
             throw URLError(.badServerResponse)
        }
    }
    
    func removeUserCard(cardId: String) async throws {
        // Encode the cardId since it may contain spaces (e.g., "The Platinum Card...")
        guard let encodedCardId = cardId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/me/cards/\(encodedCardId)") else {
            throw URLError(.badURL)
        }
        
        try await performRequest(url: url, method: "DELETE")
    }
    
    // MARK: - Recommendation
    
    func getRecommendation(storeName: String, prioritizeWarranty: Bool, userCards: [UserCard]) async throws -> RecommendationResponse {
        guard let url = URL(string: "\(baseURL)/recommend") else {
            throw URLError(.badURL)
        }
        
        let body = RecommendationRequest(
            store_name: storeName,
            prioritize_warranty: prioritizeWarranty,
            user_cards: userCards
        )
        
        let jsonData = try JSONEncoder().encode(body)
        
        // Use performRequest to handle token refresh and auth headers automatically
        let (data, response) = try await performRequest(url: url, method: "POST", body: jsonData)
        
        if let str = String(data: data, encoding: .utf8) {
            print("RAW RECOMMENDATION JSON: \(str)")
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
             if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let detail = json["detail"] as? String {
                 throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
             }
             throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(RecommendationResponse.self, from: data)
    }
    
    // MARK: - Internal Helper
    
    private func performRequest(url: URL, method: String = "GET", body: Data? = nil) async throws -> (Data, URLResponse) {
        // check expiry
        await checkTokenExpiry()
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
             // Second chance: Try to refresh if we haven't already
             print("401 received. Attempting refresh...")
             if await refreshToken() {
                 return try await performRequest(url: url, method: method, body: body)
             }
        }
        
        return (data, response)
    }
    
    private func checkTokenExpiry() async {
        guard let expiryDate = tokenExpiryDate else { return }
        // Refresh if < 5 minutes remaining
        if Date().addingTimeInterval(300) > expiryDate {
            print("Token expiring soon. Refreshing...")
            _ = await refreshToken()
        }
    }
    
    func refreshToken() async -> Bool {
        guard let refresh = refreshTokenString,
              let url = URL(string: "\(baseURL)/refresh?refresh_token=\(refresh)") else {
            return false
        }
        
        // Use a clean request (no auth header needed potentially? or backend needs it? 
        // Backend endpoint: POST /refresh with refresh_token as query param (based on my python code: `refresh_token: str`) or body?
        // My python code: `@app.post("/refresh") def refresh_token(refresh_token: str):`
        // Query param is easiest. "POST /refresh?refresh_token=..." works with FastAPI default scalar.
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let token = try JSONDecoder().decode(AuthToken.self, from: data)
                self.setSession(token)
                // Need to notify AuthManager to persist... 
                // For this simple arch, let's assume AuthManager will re-read or we use a callback
                // But AuthManager persists. We should update AuthManager via Notification or shared state.
                // Simpler: Send Notification
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("TokenRefreshed"), object: nil)
                }
                return true
            }
        } catch {
            print("Refresh failed: \(error)")
        }
        return false
    }
}

// MARK: - Models

struct AuthToken: Codable {
    let id_token: String
    let local_id: String
    let email: String
    let refresh_token: String?
    let expires_in: String? // Firebase sometimes returns string seconds
}

// ... existing models ...

struct UserProfile: Codable {
    let email: String
    let first_name: String
    let last_name: String
    let onboarded: Bool?
}

struct Card: Codable, Identifiable {
    var id: String { name }
    let name: String
    let brand: String
    let benefits: [Benefit]
}

struct UserCard: Codable, Identifiable {
    var id: String { card_id ?? UUID().uuidString }
    let card_id: String?
    let name: String
    let brand: String
    let benefits: [Benefit]?
    var sign_on_bonus: SignOnBonus? // Added
    
    init(card: Card) {
        self.card_id = UUID().uuidString
        self.name = card.name
        self.brand = card.brand
        self.benefits = card.benefits
        self.sign_on_bonus = nil
    }
}

struct SignOnBonus: Codable {
    let bonus_value: Double
    let bonus_type: String // "Points" or "Dollars"
    let current_spend: Double // User input for how much they already spent
    let target_spend: Double // Added for progress bar
    let end_date: String // ISO String YYYY-MM-DD
}

    struct Benefit: Codable {
    let category: String
    let title: String
    let description: String
    let details: String?
}

struct RecommendationRequest: Codable {
    let store_name: String
    let prioritize_warranty: Bool
    let user_cards: [UserCard]
}

struct RecommendationResponse: Codable {
    let best_card_id: String
    let reasoning: [String]
    let estimated_return: String
    let runner_up_id: String?
    let runner_up_reasoning: [String]?
    let runner_up_return: String?
}
