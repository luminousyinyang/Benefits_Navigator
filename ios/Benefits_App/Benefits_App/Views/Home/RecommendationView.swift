import SwiftUI

struct RecommendationView: View {
    let storeName: String
    let prioritizeCategory: String?
    
    @State private var recommendation: RecommendationResponse?
    @State private var userCards: [UserCard] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isInvalidStore = false
    @State private var showingAddSheet = false
    
    @Environment(\.dismiss) var dismiss
    
    // Initializer for Mock Data Support (Preview)
    init(storeName: String, prioritizeCategory: String?, mockResponse: RecommendationResponse? = nil, mockCards: [UserCard]? = nil) {
        self.storeName = storeName
        self.prioritizeCategory = prioritizeCategory
        
        if let mock = mockResponse, let cards = mockCards {
            _recommendation = State(initialValue: mock)
            _userCards = State(initialValue: cards)
            _isLoading = State(initialValue: false)
        }
    }
    
    // Exact colors from your configuration
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundDark.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Gemini Thinking...\nLoading Card Recommendations\nfor your current shopping trip...")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if errorMessage == "NO_CARDS" {
                 // NO CARDS STATE
                 VStack(spacing: 20) {
                     Image(systemName: "creditcard.trianglebadge.exclamationmark")
                         .font(.system(size: 60))
                         .foregroundColor(textSecondary)
                     
                     Text("No Cards Found")
                         .font(.title2.bold())
                         .foregroundColor(.white)
                     
                     Text("We can't recommend a card because you haven't added any yet! Add your cards to start optimizing your rewards.")
                         .font(.body)
                         .multilineTextAlignment(.center)
                         .foregroundColor(textSecondary)
                         .padding(.horizontal, 40)
                     
                     Button(action: {
                         dismiss() // Go back to Home
                         // In a real app, maybe trigger navigation to Wallet tab via binding or notification
                     }) {
                         Text("Go Back & Add Cards")
                             .font(.headline)
                             .foregroundColor(.black)
                             .padding()
                             .background(Color.white)
                             .cornerRadius(12)
                     }
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    Text("Recommendation Failed")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(textSecondary)
                        .padding(.horizontal)
                    
                    if isInvalidStore {
                        Button("Go Back") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Button("Try Again") {
                            Task { await loadData() }
                        }
                        .padding()
                        .background(primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let rec = recommendation {
                ScrollView {
                    VStack(spacing: 24) {
                        // Top App Bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                            }
                            Spacer()
                            Text("Recommendation")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Color.clear.frame(width: 20, height: 20)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Headline Text
                        VStack(spacing: 6) {
                            Text("Best card for")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(textSecondary)
                            
                            Text(rec.corrected_store_name ?? storeName)
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(prioritizeCategory != nil ? "Optimized for \(prioritizeCategory!)" : "Optimized for Rewards")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(prioritizeCategory != nil ? Color.purple.opacity(0.2) : Color.green.opacity(0.2))
                                .foregroundColor(prioritizeCategory != nil ? .purple : .green)
                                .cornerRadius(20)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        
                        // Hero Card Section
                        if let bestCard = getCard(id: rec.best_card_id) {
                            HeroCardView(
                                primaryBlue: primaryBlue,
                                secondaryBlue: secondaryBlue,
                                cardBackground: cardBackground,
                                textSecondary: textSecondary,
                                cardName: bestCard.name.isEmpty ? "Unknown Card" : bestCard.name,
                                returnAmount: rec.estimated_return
                            )
                            .padding(.horizontal)
                        } else {
                            // Fallback if card not found
                             HeroCardView(
                                primaryBlue: primaryBlue,
                                secondaryBlue: secondaryBlue,
                                cardBackground: cardBackground,
                                textSecondary: textSecondary,
                                cardName: "Recommended Card",
                                returnAmount: rec.estimated_return
                            )
                            .padding(.horizontal)
                        }
                        
                        // Sign-on Bonus Display
                        if let bestCard = getCard(id: rec.best_card_id), let bonus = bestCard.sign_on_bonus {
                            SignOnBonusProgressView(bonus: bonus)
                                .padding(.horizontal)
                        }
                        
                        // Reasoning / "Why This Card?"
                        VStack(alignment: .leading, spacing: 16) {
                            Text("WHY THIS CARD?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(textSecondary)
                                .tracking(1)
                            
                            ForEach(rec.reasoning, id: \.self) { reason in
                                BenefitRow(
                                    icon: "checkmark.shield.fill", // Generic icon, could be dynamic
                                    iconColor: .green,
                                    title: "Benefit Match",
                                    subtitle: reason,
                                    cardBackground: cardBackground
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Runner Up
                        if let runnerUpId = rec.runner_up_id, let runnerUpCard = getCard(id: runnerUpId) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RUNNER UP")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(textSecondary)
                                    .tracking(1)
                                
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 32)
                                        .overlay(Image(systemName: "creditcard").font(.caption).foregroundColor(.white.opacity(0.4)))
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(runnerUpCard.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        if let reason = rec.runner_up_reasoning?.first {
                                            Text(reason)
                                                .font(.system(size: 12))
                                                .foregroundColor(textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if let ret = rec.runner_up_return {
                                        Text(ret)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Record to Action Center Button (Inline)
                    if let priority = prioritizeCategory, let category = matchCategory(priority) {
                        Button(action: { showingAddSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                Text("Record to Action Center: \(category.rawValue)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(primaryBlue)
                            .cornerRadius(16)
                            .shadow(radius: 10)
                        }
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity) // Center the button itself in the parent view
                    }
                }
            }


            
            // Floating "Record Transaction" Button (if applicable)

        }
        .sheet(isPresented: $showingAddSheet) {
            if let priority = prioritizeCategory, let category = matchCategory(priority) {
                AddItemView(
                    category: category,
                    initialRetailer: isInvalidStore ? storeName : (recommendation?.corrected_store_name ?? storeName),
                    initialCardId: recommendation?.best_card_id
                )
            }
        }
        .onAppear {
            if recommendation == nil {
                Task {
                    await loadData()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Helper to map loose priority strings to strict Action Categories
    func matchCategory(_ input: String) -> ActionCenterView.Category? {
        let lower = input.lowercased()
        
        if lower.contains("rental") || lower.contains("car") { return .carRental }
        if lower.contains("flight") || lower.contains("travel") || lower.contains("airport") { return .airport }
        
        // Specific protections first
        if lower.contains("price") { return .priceProtection }
        if lower.contains("return") { return .returns }
        
        // Generic catch-all for warranty/protection
        if lower.contains("warranty") || lower.contains("protect") { return .warranty }
        
        if lower.contains("phone") || lower.contains("cellular") { return .cellPhone }
        
        return nil
    }
    
    func loadData() async {
        // If we have mock data (from Preview), skip loading
        if recommendation != nil { return }
        
        do {
            isLoading = true
            errorMessage = nil
            
            // 1. Fetch user cards to have details for display
            self.userCards = try await APIService.shared.fetchUserCards()
            
            if self.userCards.isEmpty {
                await MainActor.run {
                    self.errorMessage = "NO_CARDS"
                    self.isLoading = false
                }
                return
            }
            
            // ... (rest of function) ...
            
            // 2. Get recommendation
            let result = try await APIService.shared.getRecommendation(
                storeName: storeName,
                prioritizeCategory: prioritizeCategory,
                userCards: self.userCards
            )
            
            await MainActor.run {
                // Check if store is valid
                if !result.is_valid_store {
                    self.errorMessage = "We couldn't identify a store with that name. Please check your spelling and try again."
                    self.isInvalidStore = true // Set flag for UI
                    self.isLoading = false
                    return
                }
                
                self.recommendation = result
                self.isLoading = false
                                
                // Use corrected name if available, otherwise original input
                let displayStoreName = result.corrected_store_name ?? self.storeName
                
                // Save to UserDefaults for Home Insight Card (Only if valid)
                if let bestCard = getCard(id: result.best_card_id) {
                    let record: [String: Any] = [
                        "store": displayStoreName,
                        "card": bestCard.name,
                        "reward": result.estimated_return,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    UserDefaults.standard.set(record, forKey: "lastRecommendation")
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func getCard(id: String) -> UserCard? {
        return userCards.first { $0.card_id == id || $0.name == id }
    }
}



struct HeroCardView: View {
    let primaryBlue: Color
    let secondaryBlue: Color
    let cardBackground: Color
    let textSecondary: Color
    let cardName: String
    let returnAmount: String
    
    var body: some View {
        ZStack {
            // Glow Effect
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [primaryBlue.opacity(0.6), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blur(radius: 20)
                .padding(-5)
            
            VStack(spacing: 0) {
                // Card Visual
                ZStack(alignment: .topLeading) {
                    // Card Face Background
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 20/255, green: 20/255, blue: 30/255), Color(red: 40/255, green: 40/255, blue: 60/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.586, contentMode: .fit) // Credit Card Aspect Ratio
                        .overlay(
                            ZStack {
                                // Abstract Background Pattern
                                Circle()
                                    .fill(LinearGradient(colors: [primaryBlue.opacity(0.1), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 300, height: 300)
                                    .offset(x: -100, y: -100)
                                    .blur(radius: 30)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                    
                    // Card Content
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            // Chip REMOVED as requested
                            Spacer()
                            
                            // Contactless Icon
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Card Number (Masked)
                        HStack(spacing: 12) {
                            ForEach(0..<4) { _ in
                                Text("••••")
                                    .font(.custom("Courier", size: 18))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.bottom, 16)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CARDHOLDER NAME")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                                    Text(cardName.uppercased())
                                    .font(.system(size: 20, weight: .black)) // Larger and bolder
                                    .foregroundColor(.white) // Full white opacity
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .lineLimit(2) // Allow wrapping if long
                            }
                            
                            Spacer()
                            

                        }
                    }
                    .padding(24)
                    
                    // Best Value Badge
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                        Text("BEST OPTION")
                            .font(.system(size: 10, weight: .black))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(secondaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(14)
                    .offset(x: -8, y: -8) // Slight adjustment to not overlap chip too much, or move it
                }
                
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("ESTIMATED RETURN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textSecondary)
                            .tracking(0.5)
                        
                        Text(returnAmount)
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .padding(.horizontal, 16)
                    }
                    
                    // Gemini AI Pill
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("POWERED BY GEMINI 3")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundColor(secondaryBlue)
                    .background(secondaryBlue.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(secondaryBlue.opacity(0.2), lineWidth: 1))
                }
                .padding(.vertical, 24)
            }
            .background(cardBackground)
            .cornerRadius(20)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let cardBackground: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(iconColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}


// MARK: - Previews & Mock Data

#Preview {
    let mockCard = UserCard(card: Card(name: "Chase Sapphire Reserve", brand: "Chase", benefits: []))
    // We need to conform UserCard to have an initializer for mocks or just creating it roughly
    // Since UserCard has a specific init(card:), we use that.
    
    let mockResponse = RecommendationResponse(
        best_card_id: mockCard.id, // ID matches name in basic Card init
        reasoning: ["3x Points on Dining", "Use points for 50% more value"],
        estimated_return: "4.5%",
        runner_up_id: "Amex Gold",
        runner_up_reasoning: ["4x Points on Dining", "Great value but lower redemption rate"],
        runner_up_return: "4.0%",
        corrected_store_name: "Whole Foods Market",
        is_valid_store: true
    )
    
    let mockRunnerUp = UserCard(card: Card(name: "Amex Gold", brand: "American Express", benefits: []))
    
    RecommendationView(
        storeName: "Whole Foods", 
        prioritizeCategory: nil,
        mockResponse: mockResponse,
        mockCards: [mockCard, mockRunnerUp]
    )
}

