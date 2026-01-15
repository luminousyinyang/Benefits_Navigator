import SwiftUI
import Combine

class AgentService: ObservableObject {
    static let shared = AgentService()
    
    @Published var state: AgentPublicState?
    @Published var isLoading = false
    
    private let kCachedAgentState = "cached_agent_state"
    
    init() {
        loadCache()
    }
    
    @MainActor
    func refreshState() async {
        isLoading = true
        do {
            let fetched = try await APIService.shared.fetchAgentState()
            self.state = fetched
            self.isLoading = false
            self.saveCache(fetched)
        } catch {
            print("AgentService Fetch Error: \(error)")
            self.isLoading = false
        }
    }
    
    func startAgent(goal: String) async throws {
        try await APIService.shared.startAgent(goal: goal)
        // Start polling for updates
        await startPolling()
    }
    
    @MainActor
    func startPolling() async {
        // Initial fetch
        await refreshState()
        
        // Poll while status is "thinking"
        // We limit to e.g. 60 seconds (30 attempts) to avoid infinite loops
        var attempts = 0
        while attempts < 30 {
            if let currentState = self.state, currentState.status != "thinking" {
                print("Agent finished thinking. Stopping poll.")
                break
            }
            
            // Wait 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Refresh
            await refreshState()
            attempts += 1
        }
    }
    
    private func saveCache(_ state: AgentPublicState?) {
        guard let state = state else { return }
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: kCachedAgentState)
        }
    }
    
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: kCachedAgentState),
           let decoded = try? JSONDecoder().decode(AgentPublicState.self, from: data) {
            self.state = decoded
        }
    }
}
