import Foundation

class APIService {
    static let shared = APIService()
    
    // Configuration
    // Use "http://127.0.0.1:8000" for iOS Simulator
    // Use your machine's IP address (e.g. "http://192.168.1.5:8000") for physical device
    private let baseURL = "http://192.168.68.64:8000"

    private init() {}

    private var authToken: String?
    
    func clearSession() {
        self.authToken = nil
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
            self.authToken = token.id_token // Store token
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
    
    func fetchUserCards() async throws -> [UserCard] {
        guard let url = URL(string: "\(baseURL)/me/cards") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
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
        guard let url = URL(string: "\(baseURL)/me/cards/\(cardId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Models

struct AuthToken: Codable {
    let id_token: String
    let local_id: String
    let email: String
}

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
    let benefits: [String: String]
}

struct UserCard: Codable, Identifiable {
    var id: String { card_id ?? UUID().uuidString }
    let card_id: String?
    let name: String
    let brand: String
    let benefits: [String: String]?
    
    init(card: Card) {
        self.card_id = UUID().uuidString
        self.name = card.name
        self.brand = card.brand
        self.benefits = card.benefits
    }
}
