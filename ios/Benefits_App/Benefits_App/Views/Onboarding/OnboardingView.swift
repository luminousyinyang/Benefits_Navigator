import SwiftUI

struct OnboardingCardsView: View {
    // MARK: - App Theme Colors (Aligned with Home Screen)
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)

    @EnvironmentObject var authManager: AuthManager
    
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var foundCard: Card?
    @State private var userCards: [UserCard] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showSuccessMessage = false
    
    // Autocomplete state
    @State private var suggestions: [String] = []
    @State private var allCardNames: [String] = [] // Cache for local search
    
    // For "Gemini Finding..." animation
    @State private var geminiThinking = false

    // Sign-on Bonus State
    @State private var hasBonus = false
    @State private var bonusAmount = ""
    @State private var bonusType = "Points"
    @State private var currentSpend = ""
    @State private var targetSpend = ""
    @State private var bonusDeadline = Date()

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Space
                Spacer().frame(height: 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Headline
                        VStack(spacing: 12) {
                            Text("Let's Optimize Your\nWallet")
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .lineSpacing(-2)
                            
                            Text("Add your cards to reveal hidden benefits.")
                                .font(.system(size: 16))
                                .foregroundColor(textSecondary)
                        }
                        .padding(.top, 30)
                        
                        // Search & Bonus Section (Unified)
                        VStack(spacing: 0) {
                            // 1. Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(textSecondary)
                                TextField("", text: $searchQuery, prompt: Text("Search for card (e.g. Chase Sapphire)").foregroundColor(textSecondary.opacity(0.7)))
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
                            
                            // 2. Suggestions (if any)
                            if !suggestions.isEmpty {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            searchQuery = suggestion
                                            suggestions = []
                                        }) {
                                            Text(suggestion)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(cardBackground) // Background matches container
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            
                            // 3. Bonus Toggle
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $hasBonus.animation()) {
                                Text("Track Sign-up Bonus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .tint(primaryBlue)
                            .padding()
                            
                            // 4. Bonus Inputs (if expanded)
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
                                                    .padding(.top, -20) // Adjusted upward
                                                    .padding(.leading, 4),
                                                alignment: .topLeading
                                            )
                                            .padding(.top, 8) // Extra top space for label
                                        
                                        Picker("Type", selection: $bonusType) {
                                            Text("Points").tag("Points")
                                            Text("Dollars ($)").tag("Dollars")
                                            Text("Miles").tag("Miles")
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.white)
                                        .padding(6)
                                        .frame(height: 44) // Match height roughly
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
                                    .padding(.horizontal, 4)
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
                        
                        // Added Cards List
                        if !userCards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YOUR WALLET")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(textSecondary)
                                
                                ForEach(userCards) { userCard in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(userCard.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(userCard.brand)
                                                .font(.system(size: 13))
                                                .foregroundColor(textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Tutorial Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APP FEATURES")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(textSecondary)
                                Spacer()
                                
                                // Gemini AI Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                    Text("GEMINI AI")
                                        .font(.system(size: 10, weight: .black))
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(primaryBlue.opacity(0.15))
                                .foregroundColor(primaryBlue)
                                .cornerRadius(20)
                                .overlay(Capsule().stroke(primaryBlue.opacity(0.3), lineWidth: 1))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    TutorialCard(
                                        icon: "doc.text.fill",
                                        title: "AI-Powered Analysis",
                                        description: "Gemini reads the fine print so you don't have to, identifying complex reward structures.",
                                        iconColor: primaryBlue,
                                        cardBg: cardBackground
                                    )
                                    
                                    TutorialCard(
                                        icon: "globe.americas.fill",
                                        title: "Hidden Perks",
                                        description: "We automatically find unused travel credits, insurance, and purchase protections.",
                                        iconColor: .purple,
                                        cardBg: cardBackground
                                    )
                                    
                                    TutorialCard(
                                        icon: "creditcard.fill",
                                        title: "Smart Wallet",
                                        description: "Manage all your cards in one place and track spending progress.",
                                        iconColor: .green,
                                        cardBg: cardBackground
                                    )
                                    
                                    TutorialCard(
                                        icon: "location.fill",
                                        title: "Location Alerts",
                                        description: "Get notified of the best card to use when you enter a store.",
                                        iconColor: .orange,
                                        cardBg: cardBackground
                                    )
                                    
                                    TutorialCard(
                                        icon: "brain.head.profile",
                                        title: "Credit Agent",
                                        description: "AI-driven roadmap to help you maximize your credit score and rewards.",
                                        iconColor: .pink,
                                        cardBg: cardBackground
                                    )
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            
            // Fixed Footer
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Button(action: { completeOnboarding() }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .foregroundColor(backgroundDark)
                            .cornerRadius(14)
                    }
                    
                    Button(action: { completeOnboarding() }) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(backgroundDark.opacity(0.8).background(.ultraThinMaterial).ignoresSafeArea())
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
             Task {
                 do {
                     // Prefetch all cards for local search
                     let cards = try await APIService.shared.fetchAllCards()
                     DispatchQueue.main.async {
                         self.allCardNames = cards
                     }
                 } catch {
                     print("Error fetching all cards: \(error)")
                 }
             }
        }
    }
    
    func updateSuggestions(query: String) {
        // Local Filter
        guard query.count > 2 else {
            suggestions = []
            return
        }
        
        // If we have local cards, filter them
        if !allCardNames.isEmpty {
            let lowerQuery = query.lowercased()
             suggestions = allCardNames.filter { 
                let name = $0.lowercased()
                return name.contains(lowerQuery) && name != lowerQuery
             }
             // Limit to 10
             if suggestions.count > 10 {
                 suggestions = Array(suggestions.prefix(10))
             }
        } else {
            // Fallback to API if local cache empty (though it should be populated)
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
        suggestions = [] // Hide suggestions
        
        Task {
            do {
                // 1. Search
                let card = try await APIService.shared.searchCard(query: searchQuery)
                
                // 2. Add immediately
                await addCardToWallet(card: card)
                
            } catch {
                DispatchQueue.main.async {
                    self.geminiThinking = false
                    self.errorMessage = "Card not found. Please try a different name." // User friendly error
                    // self.showingError = true // Don't show alert, show inline red text
                }
            }
        }
    }
    
    func addCardToWallet(card: Card) async {
        guard authManager.currentUserUID != nil else { return }
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
                self.userCards.append(userCard)
                self.searchQuery = "" // Reset search
                
                // Reset Bonus State
                self.hasBonus = false
                self.bonusAmount = ""
                self.currentSpend = ""
                self.targetSpend = ""
                
                withAnimation {
                    self.showSuccessMessage = true
                }
                
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        // Only hide if it hasn't been hidden by typing already
                        // We can just set it false here, it's fine.
                        self.showSuccessMessage = false
                    }
                }
            }
        } catch {
            print("Error adding card: \(error)")
            DispatchQueue.main.async {
                self.geminiThinking = false
                self.errorMessage = "Failed to add card. Please try again."
            }
        }
    }
    
    func completeOnboarding() {
        guard authManager.currentUserUID != nil else { return }
        Task {
            do {
                try await APIService.shared.completeOnboarding()
                DispatchQueue.main.async {
                    authManager.completeOnboarding()
                }
            } catch {
                print("Error completing onboarding: \(error)")
                // Proceed anyway locally so user isn't stuck
                DispatchQueue.main.async {
                    authManager.completeOnboarding()
                }
            }
        }
    }
}

struct TutorialCard: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    let cardBg: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(iconColor)
            }
            Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 157/255, green: 168/255, blue: 185/255))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 280, height: 180, alignment: .topLeading)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

struct OnboardingCardsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCardsView()
    }
}
