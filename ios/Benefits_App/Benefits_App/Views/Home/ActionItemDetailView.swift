import SwiftUI

struct ActionItemDetailView: View {
    @State var item: ActionItem
    @EnvironmentObject var actionManager: ActionManager
    
    @Environment(\.dismiss) var dismiss
    @State private var helpInput: String = ""
    @State private var isRequestingHelp = false
    @State private var helpError: String?
    @State private var isDeleting = false
    
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Details
                VStack(alignment: .leading, spacing: 12) {
                    Text(displayTitle)
                         .font(.largeTitle)
                         .fontWeight(.bold)
                         .foregroundColor(.white)
                    
                    HStack {
                         Text(formatDate(item.date))
                            .foregroundColor(.gray)
                         Spacer()
                        Text("$\(String(format: "%.2f", item.total))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Divider().background(Color.gray)
                    
                    Text("Card: \(item.card_name)")
                        .foregroundColor(.gray)
                    
                    if let car = item.car_rented { Text("Car: \(car)").foregroundColor(.gray) }
                    if let flight = item.flight_info { Text("Flight: \(flight)").foregroundColor(.gray) }
                    if let obj = item.item_bought { Text("Item: \(obj)").foregroundColor(.gray) }
                    if let phone = item.phone_bought { Text("Phone: \(phone)").foregroundColor(.gray) }
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(16)
                
                // Price Protection Section
                if item.category == "price_protection" {
                    VStack(alignment: .leading, spacing: 12) {
                        // Price Drop Banner
                        if let found = item.lowest_price_found, found < item.total {
                            VStack(spacing: 12) {
                                // Notification part
                                HStack {
                                    Image(systemName: "party.popper.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                            
                                    VStack(alignment: .leading) {
                                        Text("Price Drop Detected!")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        
                                        Text("You can save $\(String(format: "%.2f", item.total - found))")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                                
                                // Action part (The "Separate Box")
                                if let urlStr = item.lowest_price_url, let url = URL(string: urlStr) {
                                    Link(destination: url) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("New Lowest Price")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text("$\(String(format: "%.2f", found))")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Spacer()
                                            
                                            HStack {
                                                Text("View Deal")
                                                    .fontWeight(.semibold)
                                                Image(systemName: "arrow.up.right")
                                                    .font(.caption)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color.green)
                                            .foregroundColor(.black)
                                            .cornerRadius(8)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        Text("Price Monitoring")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Toggle("Monitor Daily", isOn: Binding(
                            get: { item.monitor_price ?? false },
                            set: { newVal in
                                toggleMonitor(newVal)
                            }
                        ))
                        .foregroundColor(.gray)
                        
                        if let low = item.lowest_price_found {
                             HStack {
                                 Text("Lowest Found:")
                                     .foregroundColor(.gray)
                                 Text("$\(String(format: "%.2f", low))")
                                     .fontWeight(.bold)
                                     .foregroundColor(low < item.total ? .green : .white)
                             }
                             if low < item.total {
                                 Text("You could save $\(String(format: "%.2f", item.total - low))!")
                                     .font(.caption)
                                     .foregroundColor(.green)
                             }
                        }
                        
                        if let checked = item.last_checked {
                            Text("Last checked: \(checked)") 
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(16)
                }
                
                // Gemini Help Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Gemini Help")
                            .font(.headline)
                    }
                    .foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                    
                    if let instructions = item.gemini_instructions, !instructions.isEmpty {
                        // Display Instructions - markdown enabled
                        Text(LocalizedStringKey(instructions))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            
                    } else {
                        // Request Form
                        Text("Describe your issue to get step-by-step help:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextEditor(text: $helpInput)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        
                        HStack {
                            Spacer()
                            Button(action: requestHelp) {
                                if isRequestingHelp {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                        Text("Gemini is Thinking...")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity) 
                                } else {
                                    Text("Get Help")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .background(Color(red: 19/255, green: 109/255, blue: 236/255))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(helpInput.isEmpty || isRequestingHelp)
                            .frame(maxWidth: isRequestingHelp ? 250 : .infinity) // Animate width change if possible, or just set it
                            .animation(.spring(), value: isRequestingHelp)
                            Spacer()
                        }

                        
                        if let err = helpError {
                            Text(err).foregroundColor(.red).font(.caption)
                        }
                    }
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(16)
                
                // MARK: - Delete Button
                Button(action: {
                    deleteItem()
                }) {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    } else {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Record")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .disabled(isDeleting)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(backgroundDark.ignoresSafeArea())
        .navigationTitle("Details")
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    func deleteItem() {
        isDeleting = true
        Task {
            do {
                if let id = item.id {
                    try await actionManager.deleteItem(category: item.category, itemId: id)
                    dismiss()
                }
            } catch {
                print("Error deleting item: \(error)")
                isDeleting = false
            }
        }
    }
    
    func formatDate(_ dateStr: String) -> String {
        return dateStr 
    }
    
    var displayTitle: String {
        if ["warranty_benefits", "price_protection", "guaranteed_returns"].contains(item.category) {
            return item.item_bought ?? item.retailer
        } else if item.category == "cell_phone_protection" {
             return item.phone_bought ?? item.retailer
        }
        return item.retailer
    }
    
    func toggleMonitor(_ val: Bool) {
        // Optimistic update
        var updated = item
        updated.monitor_price = val
        item = updated
        actionManager.refreshItem(updated)
        
        Task {
            do {
                try await APIService.shared.togglePriceMonitor(
                    category: item.category, 
                    itemId: item.id ?? "", 
                    monitor: val
                )
            } catch {
                print("Error toggling: \(error)")
                // Revert
                var reverted = item
                reverted.monitor_price = !val
                item = reverted
                actionManager.refreshItem(reverted)
            }
        }
    }
    
    func requestHelp() {
        isRequestingHelp = true
        helpError = nil
        Task {
            do {
                let instructions = try await APIService.shared.getActionHelp(
                    category: item.category,
                    itemId: item.id ?? "",
                    notes: helpInput
                )
                DispatchQueue.main.async {
                    var updated = item
                    updated.gemini_instructions = instructions
                    self.item = updated
                    self.isRequestingHelp = false
                    actionManager.refreshItem(updated)
                }
            } catch {
                DispatchQueue.main.async {
                    self.helpError = error.localizedDescription
                    self.isRequestingHelp = false
                }
            }
        }
    }
}
