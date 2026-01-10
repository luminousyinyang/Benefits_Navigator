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
    
    @State private var userCards: [UserCard] = []
    @State private var showingAddCardSheet = false
    @State private var selectedCard: UserCard? = nil
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("My Wallet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(primaryBlue)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
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
                                    
                                    Text("Your wallet is synced. \(userCards.count) cards are currently optimized for maximum rewards based on your location and spending habits.")
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
                                ForEach(userCards) { card in
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
                                
                                if userCards.isEmpty {
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
                        BottomAction(icon: "center.focus.strong", label: "Scan")
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
        guard let uid = authManager.currentUserUID else { return }
        Task {
            do {
                let cards = try await APIService.shared.fetchUserCards(uid: uid)
                DispatchQueue.main.async {
                    self.userCards = cards
                }
            } catch {
                print("Error fetching cards: \(error)")
            }
        }
    }
    
    func deleteCard(_ card: UserCard) {
        guard let uid = authManager.currentUserUID, let cardId = card.card_id else { return }
        Task {
            do {
                try await APIService.shared.removeUserCard(uid: uid, cardId: cardId)
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
    
    var body: some View {
        ZStack {
            Color(red: 16/255, green: 24/255, blue: 34/255).ignoresSafeArea()
            VStack {
                Text("Add Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                TextField("Search card...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit { performSearch() }
                
                if geminiThinking {
                    ProgressView().tint(.white)
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
                         .background(Color.blue)
                         .cornerRadius(10)
                         .foregroundColor(.white)
                     }
                }
                
                Spacer()
            }
        }
    }
    
    func performSearch() {
        geminiThinking = true
        foundCard = nil
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
        guard let uid = authManager.currentUserUID else { return }
        let userCard = UserCard(card: card)
        Task {
            do {
                try await APIService.shared.addUserCard(uid: uid, card: userCard)
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
    
    // New: Accept full benefits dictionary
    var benefits: [String: String]? = nil
    
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
                     // Take the first 1-2 benefits to show
                     let benefitText = benefits.values.prefix(1).joined(separator: ", ")
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

#Preview {
    ManageCardsView()
}
