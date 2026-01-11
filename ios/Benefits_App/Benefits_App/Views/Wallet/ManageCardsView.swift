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
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                // Custom header removed as per user request to use system navigation or simpler UI.
                VStack(spacing: 8) {
                    Text("My Wallet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 12)
                }
                
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
                                            deleteCard(card)
                                        },
                                        benefits: card.benefits
                                    )
                                    .contentShape(Rectangle()) // Make full row tappable
                                    .onTapGesture {
                                        selectedCard = card
                                    }
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
        .sheet(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }
    
    func fetchCards() {
        Task {
            await authManager.refreshData()
        }
    }
    
    func deleteCard(_ card: UserCard) {
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
    
    // Autocomplete state
    @State private var suggestions: [String] = []
    
    var body: some View {
        ZStack {
            Color(red: 16/255, green: 24/255, blue: 34/255).ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("Add Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                TextField("Search card...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onSubmit { performSearch() }
                    .onChange(of: searchQuery) { newValue in
                        updateSuggestions(query: newValue)
                    }
                
                // Suggestions List
                if !suggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    searchQuery = suggestion
                                    suggestions = [] // Hide suggestions
                                    // Optional: Perform search immediately
                                    // performSearch() 
                                }) {
                                    Text(suggestion)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.05))
                                }
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(red: 28/255, green: 32/255, blue: 39/255))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                if geminiThinking {
                    ProgressView().tint(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                
                if let card = foundCard {
                     Button(action: {
                         addCard(card)
                     }) {
                         VStack {
                             Text(card.name).bold()
                             Text(card.brand)
                         }
                         .padding()
                         .frame(maxWidth: .infinity)
                         .background(Color.blue)
                         .cornerRadius(10)
                         .foregroundColor(.white)
                     }
                     .padding()
                }
                
                Spacer()
            }
        }
    }
    
    func updateSuggestions(query: String) {
        guard query.count > 2 else {
            suggestions = []
            return
        }
        
        Task {
            do {
                // Debounce could be added here if needed, but for now simple async is fine
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
        geminiThinking = true
        foundCard = nil
        suggestions = [] // Hide suggestions on search
        
        Task {
            do {
                let card = try await APIService.shared.searchCard(query: searchQuery)
                DispatchQueue.main.async {
                    self.foundCard = card
                    self.geminiThinking = false
                }
            } catch {
                print(error)
                geminiThinking = false
            }
        }
    }
    
    func addCard(_ card: Card) {
        // guard let uid = authManager.currentUserUID else { return }
        let userCard = UserCard(card: card)
        Task {
            do {
                try await APIService.shared.addUserCard(card: userCard)
                DispatchQueue.main.async {
                    onAdd()
                    isPresented = false
                }
            } catch {
                print(error)
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


