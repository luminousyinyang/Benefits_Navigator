import SwiftUI

struct WalletView: View {
    // MARK: - Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    @EnvironmentObject var authManager: AuthManager
    
    @State private var selectedCardId: String? = nil
    @State private var editingBonusCard: UserCard?
    @State private var selectedCategory: WalletCategory = .insights
    
    enum WalletCategory {
        case insights, perks
    }
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            
                            // Card Carousel
                            cardCarousel
                            
                            // Tabs
                            tabSection(proxy: proxy)
                            
                            VStack(alignment: .leading, spacing: 30) {
                                // Gemini Insights
                                geminiInsightsSection
                                    .id(WalletCategory.insights)
                                
                                // Benefits (Bonus + Standard)
                                cardBenefitsSection
                                    .id(WalletCategory.perks)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100) // Space for FAB
                        }
                    }
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(primaryBlue)
                            .clipShape(Circle())
                            .shadow(color: primaryBlue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            fetchCards()
        }
        .sheet(item: $editingBonusCard) { card in
             // We need to re-verify the bonus exists on this card instance or handling it safely
             if let bonus = card.sign_on_bonus {
                BonusEditView(card: card, bonus: bonus, parentView: self)
                    .presentationDetents([.fraction(0.45)])
                    .presentationDragIndicator(.visible)
             } else {
                 Text("Error: No bonus data found.")
                    .presentationDetents([.medium])
             }
        }
    }
    

    // MARK: - Bonus Management Actions
    func performBonusUpdate(cardId: String, amount: Double) async {
        do {
            try await APIService.shared.updateCardBonus(cardId: cardId, currentSpend: amount)
            await authManager.refreshData()
            // Editing state clears automatically when sheet dismisses, 
            // but we can ensure refresh happens.
        } catch {
            print("Error updating bonus: \(error)")
        }
    }
    
    func performBonusDelete(cardId: String) async {
        do {
            try await APIService.shared.deleteCardBonus(cardId: cardId)
            await authManager.refreshData()
        } catch {
            print("Error deleting bonus: \(error)")
        }
    }

    func fetchCards() {

        if !authManager.isLoggedIn { return }
        
        Task {
            await authManager.refreshData()
            
            DispatchQueue.main.async {
                if self.selectedCardId == nil, let first = authManager.userCards.first {
                    self.selectedCardId = first.card_id ?? first.id
                }
            }
        }
    }
    
    private var headerView: some View {

        HStack {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(backgroundDark, lineWidth: 2))
                }
                
                Text("Wallet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 20))
                    .foregroundColor(textSecondary)
                    .padding(10)
                    .background(cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var cardCarousel: some View {

        TabView(selection: $selectedCardId) {
            if authManager.userCards.isEmpty {
                 // Empty state
                 RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackground)
                    .frame(width: 320, height: 200)
                    .overlay(Text("No cards found. Add one in 'My Wallet'.").foregroundColor(textSecondary))
                    .tag(Optional<String>.none) // Handle nil tag for empty
            } else {
                ForEach(authManager.userCards) { card in
                    VStack(alignment: .leading, spacing: 12) {
                        // Card Visual
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(colors: [primaryBlue, secondaryBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(card.name.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Utilize available space
                                        
                                    Image(systemName: "wave.3.right")
                                        .font(.system(size: 14))
                                        .layoutPriority(1) // Keep icon visible
                                }
                                
                                Spacer()
                                Image(systemName: "cpu.fill")
                                    .font(.title)
                                    .rotationEffect(.degrees(90))
                                Spacer()
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading) {
                                        Text("**** **** **** ****")
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Text(authManager.userProfile?.first_name.uppercased() ?? "USER")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(card.brand.uppercased())
                                        .font(.title3)
                                        .italic()
                                        .fontWeight(.black)
                                }
                            }
                            .padding(25)
                            .foregroundColor(.white)
                        }
                        .frame(width: 320, height: 200) // Constraint is on the container now
                    }
                    .tag(Optional(card.card_id ?? card.id)) // Tag for selection, use card_id or id
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 280) // Constrain height for TabView
    }

    private func tabSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            tabItem(title: "Insights", category: .insights, icon: "sparkles", proxy: proxy)
            tabItem(title: "Benefits", category: .perks, proxy: proxy)
        }
        .padding(.horizontal)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1), alignment: .bottom
        )
    }
    
    private func tabItem(title: String, category: WalletCategory, icon: String? = nil, proxy: ScrollViewProxy) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
                proxy.scrollTo(category, anchor: .top)
            }
        }) {
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.caption)
                    }
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(selectedCategory == category ? primaryBlue : textSecondary)
                
                Rectangle()
                    .fill(selectedCategory == category ? primaryBlue : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var geminiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Gemini Insights", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.white)
            
            // Recommended Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(primaryBlue.opacity(0.2))
                            .foregroundColor(primaryBlue)
                            .cornerRadius(4)
                        
                        Text("Purchase Protection")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("You're browsing laptops. Use this card to get an extra year of warranty and 120 days of theft protection automatically.")
                            .font(.footnote)
                            .foregroundColor(textSecondary)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "shield.checkered")
                        .font(.title2)
                        .foregroundColor(primaryBlue)
                        .frame(width: 40, height: 40)
                        .background(primaryBlue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Text("View Policy Details")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [primaryBlue.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
        }
    }
    
    private var cardBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Benefits")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let selectedId = selectedCardId,
                   let card = authManager.userCards.first(where: { ($0.card_id ?? $0.id) == selectedId }) {
                    
                    // --- Sign Up Bonus Section ---
                    if let bonus = card.sign_on_bonus {
                        signUpBonusView(bonus: bonus)
                            .padding(.bottom, 8)
                    }
                    
                    // --- Standard Benefits ---
                    if let benefits = card.benefits, !benefits.isEmpty {
                        ForEach(benefits, id: \.title) { benefit in
                            BenefitRowView(benefit: benefit)
                        }
                    } else {
                        Text("No other benefits listed.")
                            .font(.subheadline)
                            .foregroundColor(textSecondary)
                            .italic()
                            .padding(.top, 8)
                    }
                    
                } else {
                    Text("Select a card to view benefits")
                        .foregroundColor(textSecondary)
                        .italic()
                }
            }
        }
    }
    
    private func signUpBonusView(bonus: SignOnBonus) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(primaryBlue)
                Text("Sign Up Bonus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                
                // Manage Button (Top Right)
                Button(action: {
                    if let selectedId = selectedCardId,
                       let card = authManager.userCards.first(where: { ($0.card_id ?? $0.id) == selectedId }) {
                        self.editingBonusCard = card
                    }
                }) {
                    Text("Manage")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(primaryBlue.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            .padding()
            .background(primaryBlue.opacity(0.1))
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("Earn \(Int(bonus.bonus_value)) \(bonus.bonus_type)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("$\(Int(bonus.current_spend)) spent")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("$\(Int(bonus.target_spend)) goal")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [primaryBlue, secondaryBlue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(min(bonus.current_spend / bonus.target_spend, 1.0)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                HStack {
                    Text("Spend $\(Int(max(0, bonus.target_spend - bonus.current_spend))) more to qualify.")
                        .font(.caption2)
                        .foregroundColor(textSecondary)
                    
                    Spacer()
                    
                    Text("Ends \(formattedDate(bonus.end_date))")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(primaryBlue.opacity(0.2))
                        .foregroundColor(primaryBlue)
                        .cornerRadius(4)
                }
            }
            .padding()
        }
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(primaryBlue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper for date
    func formattedDate(_ dateStr: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = inputFormatter.date(from: dateStr) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MM-dd-yyyy"
            return outputFormatter.string(from: date)
        }
        
        return dateStr
    }
}



// MARK: - Preview
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}
