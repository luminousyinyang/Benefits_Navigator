import SwiftUI

struct ManageCardsView: View {
    // MARK: - Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddCardSheet = false
    @State private var selectedCard: UserCard? = nil
    
    // Delete Confirmation State
    @State private var cardToDelete: UserCard?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
            // ... (Header and scroll view logic is fine, no changes needed inside)
                // MARK: - Navigation Bar
                ZStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold)) // Matches system back button weight often
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                        }
                        Spacer()
                    }
                    
                    Text("My Wallet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        

                        
                        // MARK: - Linked Cards Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LINKED CARDS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(textSecondary.opacity(0.8))
                                .padding(.leading, 4)
                            
                            VStack(spacing: 12) {
                                ForEach(authManager.userCards) { card in
                                    CardRow(
                                        name: card.name,
                                        benefit: card.brand, // Fallback if no benefits
                                        lastFour: "••••",
                                        icon: "creditcard.fill",
                                        iconColor: primaryBlue,
                                        gradient: [Color.blue, Color.purple],
                                        onDelete: {
                                            confirmDelete(card)
                                        },
                                        benefits: card.benefits
                                    )
                                    .contentShape(Rectangle()) // Make full row tappable
                                    // Removed onTapGesture to disable benefit view details
                                }
                                
                                if authManager.userCards.isEmpty {
                                    Text("No cards linked yet.")
                                        .foregroundColor(textSecondary)
                                        .padding()
                                }
                            }
                        }
                        

                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                // MARK: - Bottom Bar
                VStack(spacing: 12) {
                    Button(action: { showingAddCardSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add New Card")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    

                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .background(backgroundDark.opacity(0.95).blur(radius: 0.5))
            }
        }
        .onAppear {
            fetchCards()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
             Task {
                 do {
                      // Fetch for the sheet's cache
                      let cards = try await APIService.shared.fetchAllCards()
                      // We need to pass this to the sheet or the sheet fetches it itself?
                      // The sheet is a separate struct. We should probably let the sheet fetch it on appear.
                      // But the sheet view modifier (.sheet) creates the struct.
                      // Let's modify AddCardSheet to fetch on its own appear.
                 } catch {}
             }
        }
        .sheet(isPresented: $showingAddCardSheet) {
            AddCardSheet(isPresented: $showingAddCardSheet, onAdd: { 
                fetchCards() // Refresh after adding
            })
            .environmentObject(authManager)
        }
        .navigationBarHidden(true) // Hide default nav bar to use custom one for consistent style
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Card?"),
                message: Text("Are you sure you want to delete \(cardToDelete?.name ?? "this card")? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let card = cardToDelete {
                        performDelete(card)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func fetchCards() {
        Task {
            await authManager.refreshData()
        }
    }
    
    func confirmDelete(_ card: UserCard) {
        cardToDelete = card
        showingDeleteAlert = true
    }
    
    func performDelete(_ card: UserCard) {
        guard let cardId = card.card_id else { return }
        Task {
            do {
                try await APIService.shared.removeUserCard(cardId: cardId)
                fetchCards()
            } catch {
                print("Error deleting card: \(error)")
            }
        }
    }
}

struct AddCardSheet: View {
    @Binding var isPresented: Bool
    var onAdd: () -> Void
    @EnvironmentObject var authManager: AuthManager
    
    @State private var searchQuery = ""
    @State private var geminiThinking = false
    @State private var foundCard: Card?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showSuccessMessage = false
    
    // Autocomplete state
    @State private var suggestions: [String] = []
    @State private var allCardNames: [String] = [] // Cache
    
    // Sign-on Bonus State
    @State private var hasBonus = false
    @State private var bonusAmount = ""
    @State private var bonusType = "Points"
    @State private var currentSpend = ""
    @State private var targetSpend = ""
    @State private var bonusDeadline = Date()
    
    // Theme Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Add New Card")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(textSecondary)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search Bar & Bonus (Unified)
                        VStack(spacing: 0) {
                            // 1. Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(textSecondary)
                                TextField("", text: $searchQuery, prompt: Text("Search for card (e.g. Amex Gold)").foregroundColor(textSecondary.opacity(0.7)))
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        searchAndAddCard()
                                    }
                                    .onChange(of: searchQuery) { _, newValue in
                                        updateSuggestions(query: newValue)
                                        // Clear messages on typing
                                        if !newValue.isEmpty {
                                            withAnimation {
                                                showSuccessMessage = false
                                                errorMessage = nil
                                                showingError = false
                                            }
                                        }
                                    }
                                
                                if !searchQuery.isEmpty {
                                    Button(action: { searchAndAddCard() }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(primaryBlue)
                                            .font(.system(size: 24))
                                    }
                                }
                            }
                            .padding()
                            
                            // 2. Suggestions List
                            if !suggestions.isEmpty {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            searchQuery = suggestion
                                            suggestions = [] // Hide suggestions
                                            // Optional auto-search
                                        }) {
                                            Text(suggestion)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(cardBackground)
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            
                            // 3. Sign-on Bonus Toggle
                            Divider().background(Color.white.opacity(0.1))
                            Toggle(isOn: $hasBonus.animation()) {
                                Text("Track Sign-up Bonus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .tint(primaryBlue)
                            .padding()
                            
                            // 4. Bonus Inputs
                            if hasBonus {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(spacing: 12) {
                                    // Amount & Type
                                    HStack {
                                        TextField("Bonus Amount", text: $bonusAmount)
                                            .keyboardType(.numberPad)
                                            .padding(.vertical, 12) // Increased padding
                                            .padding(.horizontal, 10)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Amount")
                                                    .font(.caption)
                                                    .foregroundColor(textSecondary)
                                                    .padding(.top, -20)
                                                    .padding(.leading, 4),
                                                alignment: .topLeading
                                            )
                                            .padding(.top, 8)
                                        
                                        Picker("Type", selection: $bonusType) {
                                            Text("Points").tag("Points")
                                            Text("Dollars ($)").tag("Dollars")
                                            Text("Miles").tag("Miles")
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.white)
                                        .padding(6)
                                        .frame(height: 44)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                        .padding(.top, 8)
                                    }
                                    
                                    // Target Spend Goal
                                    TextField("Target Spend Goal ($)", text: $targetSpend)
                                        .keyboardType(.decimalPad)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 10)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .overlay(
                                            Text("Target Spend ($)")
                                                .font(.caption)
                                                .foregroundColor(textSecondary)
                                                .padding(.top, -20)
                                                .padding(.leading, 4),
                                            alignment: .topLeading
                                        )
                                        .padding(.top, 8)
                                    
                                    // Already Spent
                                    TextField("Amount Contributed ($)", text: $currentSpend)
                                        .keyboardType(.decimalPad)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 10)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .overlay(
                                            Text("Already Spent ($)")
                                                .font(.caption)
                                                .foregroundColor(textSecondary)
                                                .padding(.top, -20)
                                                .padding(.leading, 4),
                                            alignment: .topLeading
                                        )
                                        .padding(.top, 8)
                                    
                                    // Deadline
                                    HStack {
                                        Text("Offer Ends")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        DatePicker("", selection: $bonusDeadline, displayedComponents: .date)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                            .accentColor(primaryBlue)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding()
                            }
                        }
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        if showSuccessMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Card Added Successfully")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                         if let error = errorMessage {
                             Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }

                        if geminiThinking {
                            HStack(spacing: 8) {
                                ProgressView().tint(primaryBlue)
                                Text("Gemini is analyzing...")
                                    .font(.system(size: 14))
                                    .foregroundColor(primaryBlue)
                            }
                        }
                        
                        // Search Result Block Removed
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert(isPresented: $showingError) {
             Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            Task {
                do {
                    let cards = try await APIService.shared.fetchAllCards()
                    DispatchQueue.main.async {
                        self.allCardNames = cards
                    }
                } catch {
                    print("Error fetching cards in sheet: \(error)")
                }
            }
        }
    }
    
    func updateSuggestions(query: String) {
        guard query.count > 2 else {
            suggestions = []
            return
        }
        
        if !allCardNames.isEmpty {
             let lowerQuery = query.lowercased()
             suggestions = allCardNames.filter { 
                let name = $0.lowercased()
                return name.contains(lowerQuery) && name != lowerQuery
             }
             if suggestions.count > 10 {
                 suggestions = Array(suggestions.prefix(10))
             }
        } else {
            Task {
                do {
                    let results = try await APIService.shared.fetchCardSuggestions(query: query)
                    DispatchQueue.main.async {
                        self.suggestions = results.filter { $0.lowercased() != query.lowercased() }
                    }
                } catch {
                     print("Suggestion error: \(error)")
                }
            }
        }
    }
    
    func searchAndAddCard() {
        guard !searchQuery.isEmpty else { return }
        
        geminiThinking = true
        foundCard = nil
        errorMessage = nil
        showSuccessMessage = false
        suggestions = [] // Hide suggestions on search
        
        Task {
            do {
                // 1. Search
                let card = try await APIService.shared.searchCard(query: searchQuery)
                
                // 2. Add
                await addCard(card)
            } catch {
                 DispatchQueue.main.async {
                    self.geminiThinking = false
                    self.errorMessage = "Card not found. Please try a different name."
                    // self.showingError = true
                }
            }
        }
    }
    
    func addCard(_ card: Card) async {
        var userCard = UserCard(card: card)
        
        if hasBonus {
            let amount = Double(bonusAmount) ?? 0.0
            let spent = Double(currentSpend) ?? 0.0
            let target = Double(targetSpend) ?? 0.0
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate] // YYYY-MM-DD
            let dateStr = formatter.string(from: bonusDeadline)
            
            // If user spent > 0, assume it covers history up to today.
            // If they spent 0, leave nil so backend scans all history.
            let todayStr = formatter.string(from: Date())
            let lastUpdated = spent > 0 ? todayStr : nil
            
            userCard.sign_on_bonus = SignOnBonus(
                bonus_value: amount,
                bonus_type: bonusType,
                current_spend: spent,
                target_spend: target,
                end_date: dateStr,
                last_updated: lastUpdated
            )
        }
        
        do {
            try await APIService.shared.addUserCard(card: userCard)
            DispatchQueue.main.async {
                self.geminiThinking = false
                self.searchQuery = "" // Reset Search
                
                // Reset Bonus State
                self.hasBonus = false
                self.bonusAmount = ""
                self.currentSpend = ""
                self.targetSpend = ""
                
                onAdd()
                // isPresented = false // Don't close immediately, let them see success?
                // actually, user might want to add multiple cards. 
                // Or if it's "Search -> Add", maybe we don't close.
                // But for "Add Card Sheet", maybe closing is expected?
                // The user said: "one search to add a card". 
                // Usually "Add" button closes the sheet if successful.
                
                withAnimation {
                    self.showSuccessMessage = true
                }
                
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        self.showSuccessMessage = false
                    }
                }
            }
        } catch {
            print(error)
            DispatchQueue.main.async {
                self.geminiThinking = false
                self.errorMessage = "Failed to add card: \(error.localizedDescription)"
                // self.showingError = true
            }
        }
    }
} // End AddCardSheet

// MARK: - Subviews
struct CardRow: View {
    let name: String
    let benefit: String
    let lastFour: String
    let icon: String
    let iconColor: Color
    let gradient: [Color]
    var onDelete: (() -> Void)? = nil
    
    // New: Accept full benefits list
    var benefits: [Benefit]? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Mini Card Art
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 58, height: 36)
                
                Text(lastFour)
                    .font(.system(size: 6, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                // Smart Benefits Display
                if let benefits = benefits, !benefits.isEmpty {
                     // Take the first benefit to show as preview
                     let benefitText = benefits.prefix(1).map { $0.title }.joined(separator: ", ")
                     HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(benefitText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 157/255, green: 168/255, blue: 185/255))
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 10))
                            .foregroundColor(iconColor)
                        Text(benefit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 157/255, green: 168/255, blue: 185/255))
                    }
                }
            }
            
            Spacer()
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            } else {
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(red: 28/255, green: 32/255, blue: 39/255))
        .cornerRadius(14)
    }
}




