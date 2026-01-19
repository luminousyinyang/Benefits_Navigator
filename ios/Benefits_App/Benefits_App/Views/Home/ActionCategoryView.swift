import SwiftUI

struct ActionCategoryView: View {
    let category: ActionCenterView.Category
    @EnvironmentObject var actionManager: ActionManager
    @State private var showingAddSheet = false
    
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    
    var items: [ActionItem] {
        actionManager.itemsByCategory[category.backendValue] ?? []
    }
    
    var isLoading: Bool {
        actionManager.loadingStatus[category.backendValue] ?? false
    }
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack {
                if items.isEmpty && !isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No claims or items yet.")
                            .foregroundColor(.gray)
                        Button("Add Your First") {
                            showingAddSheet = true
                        }
                        .foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink(destination: ActionItemDetailView(item: item)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(getItemTitle(for: item))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(formatDate(item.date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("$\(String(format: "%.2f", item.total))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                        
                                        if category == .priceProtection, let low = item.lowest_price_found, low < item.total {
                                            Text("Found: $\(String(format: "%.2f", low))")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                }
                            }
                            .listRowBackground(Color(red: 28/255, green: 32/255, blue: 39/255))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        actionManager.fetchItems(for: category.backendValue, force: true)
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemView(category: category)
        }
        .onAppear {
            actionManager.fetchItems(for: category.backendValue, force: true)
        }
    }
    
    func formatDate(_ dateStr: String) -> String {
        return dateStr
    }
    
    func getItemTitle(for item: ActionItem) -> String {
        switch category {
        case .warranty, .priceProtection, .returns:
            return item.item_bought ?? item.retailer
        case .cellPhone:
            return item.phone_bought ?? item.retailer
        default:
            return item.retailer
        }
    }
}
