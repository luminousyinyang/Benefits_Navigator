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
    
    // In-memory cache
    private var transactionCache: [Transaction] = []
    
    // Adjust to your actual backend URL if different
    // Using the same base URL logic as APIService might be cleaner, but hardcoding for now as per previous
    private let baseURL = "http://10.126.172.26:8000" 
    
    // MARK: - API Calls
    
    func fetchTransactions(forceRefresh: Bool = false) async throws {
        // Return from cache if available and not forced
        if !forceRefresh && !transactionCache.isEmpty {
            DispatchQueue.main.async {
                self.transactions = self.transactionCache
            }
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
        
        DispatchQueue.main.async {
            self.transactionCache = decodedTransactions
            self.transactions = decodedTransactions
        }
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
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Invalidate cache so next fetch gets new data
        // Refresh transactions to update the UI immediately
        try? await fetchTransactions(forceRefresh: true) 
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        DispatchQueue.main.async {
            self.transactionCache = []
            self.transactions = []
        }
    }
}
