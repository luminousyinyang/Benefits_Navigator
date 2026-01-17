import SwiftUI

struct AddItemView: View {
    let category: ActionCenterView.Category
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var actionManager: ActionManager
    
    // Form Fields
    @State private var retailer = ""
    @State private var total = ""
    @State private var date = Date()
    @State private var selectedCardId: String = ""
    
    // Dynamic Fields
    @State private var carRented = ""
    @State private var flightInfo = ""
    @State private var itemBought = ""
    @State private var phoneBought = ""
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Retailer Name", text: $retailer)
                    TextField("Total Amount ($)", text: $total)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    if !authManager.userCards.isEmpty {
                        Picker("Card Used", selection: $selectedCardId) {
                            Text("Select Card").tag("")
                            ForEach(authManager.userCards) { card in
                                Text(card.name).tag(card.card_id ?? card.id)
                            }
                        }
                    } else {
                        Text("No cards found in wallet")
                    }
                }
                
                Section(header: Text("Category Details")) {
                    if category == .carRental {
                        TextField("Car Rented (e.g. Ford Mustang)", text: $carRented)
                    } else if category == .airport {
                        TextField("Flight Info (e.g. DAL 123)", text: $flightInfo)
                    } else if category == .warranty || category == .priceProtection || category == .returns {
                        TextField("Item Bought", text: $itemBought)
                    } else if category == .cellPhone {
                        TextField("Phone Model", text: $phoneBought)
                    }
                }
                
                if category == .priceProtection {
                    Section(footer: Text("Gemini will check prices daily at midnight.")) {
                        Text("Price Monitoring will be enabled automatically.")
                    }
                }
            }
            .navigationTitle("Add \(category.rawValue)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveItem() }
                        .disabled(retailer.isEmpty || total.isEmpty || selectedCardId.isEmpty || isSubmitting)
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
             // Default selection
             if let first = authManager.userCards.first {
                 selectedCardId = first.card_id ?? first.id
             }
        }
    }
    
    func saveItem() {
        guard let totalVal = Double(total) else {
            errorMessage = "Invalid total amount"
            return
        }
        
        // Find card name
        let cardName = authManager.userCards.first(where: { ($0.card_id ?? $0.id) == selectedCardId })?.name ?? "Unknown Card"
        
        isSubmitting = true
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateStr = formatter.string(from: date)
        
        let item = ActionItem(
            id: nil,
            category: category.backendValue,
            card_id: selectedCardId,
            card_name: cardName,
            retailer: retailer,
            date: dateStr,
            total: totalVal,
            car_rented: category == .carRental ? carRented : nil,
            flight_info: category == .airport ? flightInfo : nil,
            item_bought: (category == .warranty || category == .priceProtection || category == .returns) ? itemBought : nil,
            phone_bought: category == .cellPhone ? phoneBought : nil,
            help_requested: false,
            gemini_instructions: nil,
            monitor_price: category == .priceProtection ? true : nil,
            lowest_price_found: nil,
            last_checked: nil
        )
        
        Task {
            do {
                try await actionManager.addItem(category: category.backendValue, item: item)
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}
