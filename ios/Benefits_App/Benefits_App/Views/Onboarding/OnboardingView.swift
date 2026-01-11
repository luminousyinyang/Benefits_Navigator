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
    
    // Autocomplete state
    @State private var suggestions: [String] = []
    
    // For "Gemini Finding..." animation
    @State private var geminiThinking = false

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Progress
                VStack(spacing: 8) {
                    Text("STEP 2 OF 4")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(1.2)
                        .foregroundColor(textSecondary)
                    
                    HStack(spacing: 6) {
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4).frame(width: 32, height: 6).foregroundColor(primaryBlue)
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.top, 20)
                
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
                        
                        // Search Bar Section
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(textSecondary)
                                TextField("", text: $searchQuery, prompt: Text("Search for card (e.g. Chase Sapphire)").foregroundColor(textSecondary.opacity(0.7)))
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        performSearch()
                                    }
                                    .onChange(of: searchQuery) { newValue in
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
                                            suggestions = []
                                            // Optional: performSearch()
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
                                    Button(action: { addCardToWallet(card: card) }) {
                                        Text("Add")
                                            .font(.system(size: 14, weight: .bold)) // Fixed font weight
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(primaryBlue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(primaryBlue.opacity(0.5), lineWidth: 1))
                            }
                        }
                        
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
                                Text("APP TUTORIAL")
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
                        Text("Next Step")
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
        suggestions = [] // Hide suggestions
        
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
    
    func addCardToWallet(card: Card) {
        guard let uid = authManager.currentUserUID else { return }
        let userCard = UserCard(card: card)
        
        Task {
            do {
                try await APIService.shared.addUserCard(card: userCard)
                DispatchQueue.main.async {
                    self.userCards.append(userCard)
                    self.foundCard = nil // Clear result after adding
                    self.searchQuery = ""
                }
            } catch {
                print("Error adding card: \(error)")
            }
        }
    }
    
    func completeOnboarding() {
        guard let uid = authManager.currentUserUID else { return }
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
