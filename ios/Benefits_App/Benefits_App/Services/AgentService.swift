import SwiftUI
import Combine

class AgentService: ObservableObject {
    static let shared = AgentService()
    
    @Published var state: AgentPublicState?
    @Published var isLoading = false
    
    private let kCachedAgentState = "cached_agent_state"
    private var ignoreStaleErrors = true // Default to true on app launch
    
    init() {
        loadCache()
    }
    
    @MainActor
    func refreshState() async {
        isLoading = true
        do {
            let fetched = try await APIService.shared.fetchAgentState()
            
            // Check for stale error on launch
            if ignoreStaleErrors {
                ignoreStaleErrors = false // Only check once
                if let s = fetched, s.status == "error", (s.roadmap ?? []).isEmpty {
                    print("Suppressing stale error on launch")
                    self.state = nil
                    self.saveCache(nil)
                    self.isLoading = false
                    return
                }
            }
            
            self.state = fetched
            self.isLoading = false
            self.saveCache(fetched)
        } catch {
            print("AgentService Fetch Error: \(error)")
            self.isLoading = false
        }
    }
    
    func startAgent(goal: String) async throws {
        ignoreStaleErrors = false // User Initiated -> Show errors
        try await APIService.shared.startAgent(goal: goal)
        // Start polling for updates (non-blocking)
        Task { await startPolling() }
    }
    
    @MainActor
    func updateMilestone(_ milestone: Milestone, status: String? = nil, spendingCurrent: Double? = nil, notes: String? = nil, manualCompletion: Bool? = nil) async {
        do {
            try await APIService.shared.updateMilestone(id: milestone.id, status: status, spendingCurrent: spendingCurrent, notes: notes, manualCompletion: manualCompletion)
            // Start polling to catch the "thinking" -> "idle" transition and update UI
            Task { await startPolling() }
        } catch {
            print("Error updating milestone: \(error)")
        }
    }
    
    @MainActor
    func completeTask(_ taskId: String) async throws {
        try await APIService.shared.completeTask(taskId: taskId)
        Task { await startPolling() }
    }
    
    private var pollingTask: Task<Void, Never>?

    @MainActor
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    func startPolling() async {
        // Cancel existing
        stopPolling()
        
        pollingTask = Task {
            // Initial fetch
            await refreshState()
            
            // If explicit nil state (no agent running), stop immediately
            if self.state == nil {
                print("No active agent. Stopping poll.")
                return
            }
            
            // Poll while status is "thinking"
            var attempts = 0
            while attempts < 30 {
                if Task.isCancelled { break }
                
                if let currentState = self.state, currentState.status != "thinking" {
                    print("Agent finished thinking. Stopping poll.")
                    break
                }
                
                // Wait 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                if Task.isCancelled { break }
                
                // Refresh
                await refreshState()
                attempts += 1
            }
        }
        
        _ = await pollingTask?.result
    }
    
    private func saveCache(_ state: AgentPublicState?) {
        guard let state = state else { return }
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: kCachedAgentState)
        }
    }
    
    func clearState() {
        self.state = nil
        UserDefaults.standard.removeObject(forKey: kCachedAgentState)
    }
    
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: kCachedAgentState),
           let decoded = try? JSONDecoder().decode(AgentPublicState.self, from: data) {
            self.state = decoded
        }
    }
}
