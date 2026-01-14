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
                        
                        // MARK: - Optimizer Banner
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(primaryBlue)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Gemini Optimizer Active")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Your wallet is synced. \(authManager.userCards.count) cards are currently optimized for maximum rewards based on your location and spending habits.")
                                        .font(.system(size: 13))
                                        .foregroundColor(textSecondary)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(primaryBlue.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
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
                        
                        // MARK: - Scan Prompt
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 32))
                                .foregroundColor(textSecondary.opacity(0.5))
                            
                            Text("Scan card to add instantly")
                                .font(.system(size: 13))
                                .foregroundColor(textSecondary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
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
                    
                    HStack(spacing: 30) {
                        BottomAction(icon: "viewfinder", label: "Scan")
                        BottomAction(icon: "magnifyingglass", label: "Search")
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
    
    // Autocomplete state
    @State private var suggestions: [String] = []
    
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
                        // Search Bar Section
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(textSecondary)
                                TextField("", text: $searchQuery, prompt: Text("Search for card (e.g. Amex Gold)").foregroundColor(textSecondary.opacity(0.7)))
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        performSearch()
                                    }
                                    .onChange(of: searchQuery) { _, newValue in
                                        updateSuggestions(query: newValue)
                                    }
                                
                                if !searchQuery.isEmpty {
                                    Button(action: { performSearch() }) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(primaryBlue)
                                            .font(.system(size: 24))
                                    }
                                }
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            
                            // Suggestions List
                            if !suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            searchQuery = suggestion
                                            suggestions = [] // Hide suggestions
                                            // performSearch() // Optional auto-search
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
                                .padding(.top, 4)
                                .cornerRadius(8)
                            }
                        }
                        
                        if geminiThinking {
                            HStack(spacing: 8) {
                                ProgressView().tint(primaryBlue)
                                Text("Gemini is analyzing...")
                                    .font(.system(size: 14))
                                    .foregroundColor(primaryBlue)
                            }
                        }
                        
                        // Search Result (Found Card)
                        if let card = foundCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FOUND CARD")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(primaryBlue)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(card.name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(card.brand)
                                                .font(.system(size: 14))
                                                .foregroundColor(textSecondary)
                                        }
                                        Spacer()
                                    }
                                    
                                    // Sign-on Bonus Toggle
                                    Toggle(isOn: $hasBonus.animation()) {
                                        Text("Track Sign-up Bonus")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .tint(primaryBlue)
                                    
                                    if hasBonus {
                                        VStack(spacing: 12) {
                                            // Amount & Type
                                            HStack {
                                                TextField("Bonus Amount", text: $bonusAmount)
                                                    .keyboardType(.numberPad)
                                                    .padding(10)
                                                    .background(Color.black.opacity(0.3))
                                                    .cornerRadius(8)
                                                    .foregroundColor(.white)
                                                    .overlay(
                                                        Text("Amount")
                                                            .font(.caption)
                                                            .foregroundColor(textSecondary)
                                                            .padding(.top, -18)
                                                            .padding(.leading, 4),
                                                        alignment: .topLeading
                                                    )
                                                
                                                Picker("Type", selection: $bonusType) {
                                                    Text("Points").tag("Points")
                                                    Text("Dollars ($)").tag("Dollars")
                                                    Text("Miles").tag("Miles")
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                                .accentColor(.white)
                                                .padding(6)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(8)
                                            }
                                            
                                            // Target Spend Goal
                                            TextField("Target Spend Goal ($)", text: $targetSpend)
                                                .keyboardType(.decimalPad)
                                                .padding(10)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Text("Target Spend ($)")
                                                        .font(.caption)
                                                        .foregroundColor(textSecondary)
                                                        .padding(.top, -18)
                                                        .padding(.leading, 4),
                                                    alignment: .topLeading
                                                )
                                            
                                            // Already Spent
                                            TextField("Amount Contributed ($)", text: $currentSpend)
                                                .keyboardType(.decimalPad)
                                                .padding(10)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Text("Already Spent ($)")
                                                        .font(.caption)
                                                        .foregroundColor(textSecondary)
                                                        .padding(.top, -18)
                                                        .padding(.leading, 4),
                                                    alignment: .topLeading
                                                )
                                            
                                            // Deadline
                                            DatePicker("Offer Ends", selection: $bonusDeadline, displayedComponents: .date)
                                                .colorScheme(.dark)
                                                .accentColor(primaryBlue)
                                                .padding(4)
                                        }
                                        .padding(.top, 4)
                                    }
                                    
                                    Button(action: { addCard(card) }) {
                                        Text("Add Card")
                                            .font(.system(size: 14, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(primaryBlue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(primaryBlue.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert(isPresented: $showingError) {
             Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
    
    func updateSuggestions(query: String) {
        guard query.count > 2 else {
            suggestions = []
            return
        }
        
        Task {
            do {
                let results = try await APIService.shared.fetchCardSuggestions(query: query)
                DispatchQueue.main.async {
                    self.suggestions = results
                }
            } catch {
                print("Suggestion error: \(error)")
            }
        }
    }
    
    func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        geminiThinking = true
        foundCard = nil
        errorMessage = nil
        suggestions = [] // Hide suggestions on search
        
        // Reset Bonus State
        hasBonus = false
        bonusAmount = ""
        currentSpend = ""
        targetSpend = ""
        
        Task {
            do {
                let card = try await APIService.shared.searchCard(query: searchQuery)
                DispatchQueue.main.async {
                    self.foundCard = card
                    self.geminiThinking = false
                }
            } catch {
                 DispatchQueue.main.async {
                    self.geminiThinking = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    func addCard(_ card: Card) {
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
        
        Task {
            do {
                try await APIService.shared.addUserCard(card: userCard)
                DispatchQueue.main.async {
                    onAdd()
                    isPresented = false
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to add card: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
}

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

struct BottomAction: View {
    let icon: String
    let label: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(red: 157/255, green: 168/255, blue: 185/255))
        }
    }
}


