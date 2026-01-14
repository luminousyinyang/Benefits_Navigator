import SwiftUI
import Combine

class ActionManager: ObservableObject {
    @Published var itemsByCategory: [String: [ActionItem]] = [:]
    @Published var loadingStatus: [String: Bool] = [:]
    
    private let cacheKey = "cached_action_items"
    
    init() {
        loadFromCache()
    }
    
    func fetchItems(for category: String, force: Bool = false) {
        // If we have items and not forced, wait for potential background update but don't block UI if cache exists
        if let existing = itemsByCategory[category], !existing.isEmpty, !force {
            // Already showing cached data
            return
        }
        
        // If already loading, skip
        if loadingStatus[category] == true { return }
        
        loadingStatus[category] = true
        
        Task {
            do {
                let fetched = try await APIService.shared.fetchActionItems(category: category)
                await MainActor.run {
                    self.itemsByCategory[category] = fetched
                    self.loadingStatus[category] = false
                    self.saveToCache()
                }
            } catch {
                print("Error fetching items for \(category): \(error)")
                await MainActor.run {
                     self.loadingStatus[category] = false
                }
            }
        }
    }
    
    func addItem(category: String, item: ActionItem) async throws {
        try await APIService.shared.addActionItem(category: category, item: item)
        // Force Refresh to get the real ID from server (or just refetch)
        // fetchItems(for: category, force: true) -> async, might not update immediately for UI
        // Let's rely on fetchItems(force: true)
        
        // Better: trigger fetch but don't await it here if we just want to close the sheet
        Task {
            // Delay slightly to allow firestore propagation if needed
            try? await Task.sleep(nanoseconds: 500_000_000) 
            fetchItems(for: category, force: true)
        }
    }
    
    func refreshItem(_ item: ActionItem) {
        // Find and replace item in the list if it exists
        let category = item.category
        if var list = itemsByCategory[category], let index = list.firstIndex(where: { $0.id == item.id }) {
            list[index] = item
            itemsByCategory[category] = list
            saveToCache()
        }
    }
    
    // MARK: - Persistence
    
    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(itemsByCategory) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: [ActionItem]].self, from: data) {
            self.itemsByCategory = decoded
        }
    }
}
