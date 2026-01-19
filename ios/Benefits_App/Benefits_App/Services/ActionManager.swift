import SwiftUI
import UIKit
import Combine

class ActionManager: ObservableObject {
    static let shared = ActionManager()
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
                    // Notification Logic: Check for NEW price drops compared to existing cache
                    if category == "price_protection" {
                        self.checkForPriceDrops(newItems: fetched, oldItems: self.itemsByCategory[category] ?? [])
                    }
                    
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
    
    private func checkForPriceDrops(newItems: [ActionItem], oldItems: [ActionItem]) {
        // If we have no old items, this is likely an initial fetch or fresh login.
        // We should NOT notify for existing price drops in this case.
        if oldItems.isEmpty {
            return
        }
        
        for newItem in newItems {
            // Check if this item has a drop
            if let low = newItem.lowest_price_found, low < newItem.total {
                // Check if we already knew about this drop (to avoid spam)
                if let oldItem = oldItems.first(where: { $0.id == newItem.id }) {
                    // If old item already had this price (or lower), don't notify
                    if let oldLow = oldItem.lowest_price_found, oldLow <= low + 0.01 {
                        continue
                    }
                } else {
                    // Item is new to our list, but if we have other items (oldItems is not empty),
                    // this represents a newly added item during an active session.
                    // If a user ADDS an item and it immediately has a drop, maybe we should notify?
                    // User says "only send... on new price drop alerts... found after user has logged in".
                    // If I add an item, I see the screen. I don't need a notification.
                    // So, if the item wasn't in the old list, we probably shouldn't notify either,
                    // UNLESS we are sure it's a *new* drop.
                    // But effectively, preventing notification on "newly added items" is safer to avoid spam.
                    continue
                }
                
                // Notify!
                NotificationManager.shared.sendPriceDropNotification(
                    item: newItem.item_bought ?? newItem.retailer,
                    saved: newItem.total - low,
                    foundPrice: low
                )
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
    
    func deleteItem(category: String, itemId: String) async throws {
        try await APIService.shared.deleteActionItem(category: category, itemId: itemId)
        
        await MainActor.run {
            if var list = itemsByCategory[category] {
                list.removeAll { $0.id == itemId }
                itemsByCategory[category] = list
                saveToCache()
            }
        }
    }
        func performBackgroundFetch() async -> UIBackgroundFetchResult {
        let category = "price_protection"
        do {
            let fetched = try await APIService.shared.fetchActionItems(category: category)
            
            // Check drops
            var newDropFound = false
            let oldItems = self.itemsByCategory[category] ?? []
            
            await MainActor.run {
                // Determine if we found something new before updating
                // Only check for drops if we had a baseline (oldItems is not empty)
                if !oldItems.isEmpty {
                    for newItem in fetched {
                         if let low = newItem.lowest_price_found, low < newItem.total {
                             // Check if OLD item already knew this
                             if let oldItem = oldItems.first(where: { $0.id == newItem.id }) {
                                 if let oldLow = oldItem.lowest_price_found, oldLow <= low + 0.01 {
                                     continue
                                 }
                                 // Found a drop on an EXISTING item that is lower than before
                                 newDropFound = true
                                 NotificationManager.shared.sendPriceDropNotification(
                                    item: newItem.item_bought ?? newItem.retailer,
                                    saved: newItem.total - low,
                                    foundPrice: low
                                 )
                             }
                             // If item is new (not in oldItems), we skip notification (same logic as checkForPriceDrops)
                         }
                    }
                }
                
                self.itemsByCategory[category] = fetched
                self.saveToCache()
            }
            return newDropFound ? .newData : .noData
        } catch {
            print("Background fetch failed: \(error)")
            return .failed
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
    
    func clearCache() {
        itemsByCategory = [:]
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}
