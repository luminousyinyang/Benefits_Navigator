import Foundation
import Combine

struct Transaction: Codable, Identifiable {
    var id: String?
    let date: String
    let retailer: String
    let amount: Double
    let card_name: String? // Added field
    let cashback_earned: Double
    let source_file: String?
    
    // Helper for formatting
    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
    
    var formattedCashback: String {
        return String(format: "+$%.2f", cashback_earned)
    }
}

class TransactionService: ObservableObject {
    static let shared = TransactionService()
    
    @Published var transactions: [Transaction] = []
    
    // In-memory array IS the source of truth, backed by UserDefaults
    // private var transactionCache: [Transaction] = [] // Removed, using UserDefaults instead
    
    // Adjust to your actual backend URL if different
    // Using the same base URL logic as APIService might be cleaner, but hardcoding for now as per previous
    private let baseURL = "http://10.126.172.26:8000" 
    
    // Keys
    private let cacheKey = "cached_transactions"
    
    // MARK: - API Calls
    
    private init() {
        loadFromCache()
    }
    
    func fetchTransactions(forceRefresh: Bool = false) async throws {
        // Return from memory cache if available and not forced
        if !forceRefresh && !transactions.isEmpty {
            // No need to dispatch, already set from init/memory
            return
        }
        
        guard let url = URL(string: "\(baseURL)/transactions/") else { return }
        
        // Use APIService to get a VALID token (refreshes if needed)
        guard let token = await APIService.shared.getValidToken() else { 
            throw URLError(.userAuthenticationRequired) 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedTransactions = try JSONDecoder().decode([Transaction].self, from: data)
        
        await MainActor.run {
            self.transactions = decodedTransactions
            self.saveToCache(decodedTransactions)
        }
    }
    
    // Fetch all transactions without updating the main list or cache
    // This is for search functionality only
    func fetchAllTransactions() async throws -> [Transaction] {
        guard let url = URL(string: "\(baseURL)/transactions/?limit=-1") else { return [] }
        
        guard let token = await APIService.shared.getValidToken() else { 
            throw URLError(.userAuthenticationRequired) 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Transaction].self, from: data)
    }
    
    func uploadStatement(fileURL: URL) async throws {
        guard let url = URL(string: "\(baseURL)/transactions/upload") else { return }
        
        guard let token = await APIService.shared.getValidToken() else { 
            throw URLError(.userAuthenticationRequired) 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 240 // Increase timeout to 4 minutes for Gemini processing
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let fileName = fileURL.lastPathComponent
        guard let fileData = try? Data(contentsOf: fileURL) else {
            throw URLError(.cannotOpenFile)
        }
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Check for completed bonuses
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let bonuses = json["completed_bonuses"] as? [[String: Any]] {
            
            for bonus in bonuses {
                if let cardName = bonus["card_name"] as? String,
                   let earned = bonus["earned"] as? Double,
                   let type = bonus["type"] as? String {
                    
                    NotificationManager.shared.sendBonusCompletionNotification(cardName: cardName, earned: earned, type: type)
                }
            }
        }
        
        // Invalidate cache so next fetch gets new data
        // Refresh transactions to update the UI immediately
        try? await fetchTransactions(forceRefresh: true) 
    }
    
    // MARK: - Cache Management
    
    private func saveToCache(_ transactions: [Transaction]) {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            self.transactions = decoded
        }
    }
    
    func clearCache() {
        DispatchQueue.main.async {
            self.transactions = []
            UserDefaults.standard.removeObject(forKey: self.cacheKey)
        }
    }
}
