import Foundation

class APIService {
    static let shared = APIService()
    
    // Configuration
    // Use "http://127.0.0.1:8000" for iOS Simulator
    // Use your machine's IP address (e.g. "http://192.168.1.5:8000") for physical device
    private let baseURL = "http://10.126.172.26:8000"

    private init() {}

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
    
    func fetchUser(uid: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/me?uid=\(uid)") else {
             throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
             throw URLError(.badServerResponse)
        }
        
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)
        return profile
    }
}

// MARK: - Models

struct AuthToken: Codable {
    let id_token: String
    let local_id: String
    let email: String
}

struct UserProfile: Codable {
    let first_name: String
    let last_name: String
    let email: String
}
