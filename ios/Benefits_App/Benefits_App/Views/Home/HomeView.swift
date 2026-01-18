import SwiftUI

struct HomeView: View {
    // Custom Colors based on the wireframe
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    @State private var searchText = ""
    @State private var selectedCategory: ActionCenterView.Category? = nil
    @State private var navigateToRecommendation = false
    @State private var navigatedStoreName = "" // Preserves search text for navigation
    @State private var lastRecommendation: [String: Any]? = nil
    
    @EnvironmentObject var authManager: AuthManager
    @Binding var selectedTab: Int

    // Computed property for display
    var firstName: String {
        authManager.userProfile?.first_name ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack {
                        HStack(spacing: 12) {
                            Button(action: {
                                selectedTab = 4 // Switch to Profile Tab
                            }) {
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
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Welcome back,")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text(firstName.isEmpty ? "User" : firstName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack(spacing: 6) {
                                Text("Sign Out")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            
                            // MARK: - Headline
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Maximize your ")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.white)
                                + Text("rewards")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [primaryBlue, Color.blue.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                + Text(" today.")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.white)
                                
                                Text("Let Gemini find the best card for your purchase.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 24)
                            
                            // MARK: - Search & Toggle Section
                            VStack(spacing: 12) {
                                // Search Bar
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(primaryBlue)
                                        .font(.system(size: 20))
                                    
                                    TextField("", text: $searchText, prompt:
                                                Text("Where are you shopping?")
                                        .foregroundColor(Color.gray.opacity(0.8))
                                    )
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        if !searchText.isEmpty {
                                            navigatedStoreName = searchText // Capture text
                                            navigateToRecommendation = true
                                            hideKeyboard()
                                            searchText = ""
                                        }
                                    }
                                    
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            navigatedStoreName = searchText // Capture text
                                            navigateToRecommendation = true
                                            hideKeyboard()
                                            searchText = ""
                                        }) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(primaryBlue)
                                                .font(.system(size: 24))
                                        }
                                    }
                                    
                                    // Mic icon removed
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: primaryBlue.opacity(0.2), radius: 10, x: 0, y: 0)

                                // Prioritize Menu
                                Menu {
                                    Button(action: { selectedCategory = nil }) {
                                        if selectedCategory == nil { Label("Maximize Rewards (Default)", systemImage: "checkmark") }
                                        else { Text("Maximize Rewards (Default)") }
                                    }
                                    
                                    Divider()
                                    
                                    ForEach(ActionCenterView.Category.allCases, id: \.self) { category in
                                        Button(action: { selectedCategory = category }) {
                                            if selectedCategory == category { Label(category.rawValue, systemImage: "checkmark") }
                                            else { Text(category.rawValue) }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(primaryBlue.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: selectedCategory?.icon ?? "star.circle.fill")
                                                .foregroundColor(primaryBlue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(selectedCategory?.rawValue ?? "Maximize Rewards")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(selectedCategory == nil ? "Finding the highest value card" : "Prioritizing this benefit")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                    }
                                    .padding()
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.bottom, 24)
                            
                            // MARK: - Action Grid
                            HStack(spacing: 16) {
                                Button(action: {
                                    selectedTab = 1 // Switch to Wallet Tab
                                }) {
                                    ActionButton(icon: "creditcard.fill", title: "My Wallet", subtitle: "View Card Benefits", cardBg: cardBackground)
                                }
                                NavigationLink(destination: ActionCenterView()) {
                                    ActionButton(icon: "square.grid.2x2.fill", title: "Action Center", subtitle: "Track & Protect", cardBg: cardBackground)
                                }
                            }
                            .padding(.bottom, 32)
                            
                            //                        Spacer(minLength: 40)
                            
                            // MARK: - Gemini Insight Card
                            // Always show card (Persistent)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14))
                                    Text("GEMINI INSIGHT")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(primaryBlue)
                                
                                if let rec = lastRecommendation {
                                    let store = rec["store"] as? String ?? "your recent trip"
                                    let card = rec["card"] as? String ?? "Best Card"
                                    let reward = rec["reward"] as? String ?? "Rewards"
                                    
                                    Text("For your purchase at ")
                                        .foregroundColor(.gray)
                                    + Text(store)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    + Text(", you should use your ")
                                        .foregroundColor(.gray)
                                    + Text(card)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    + Text(" for ")
                                        .foregroundColor(.gray)
                                    + Text(reward)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    + Text(".")
                                        .foregroundColor(.gray)
                                } else {
                                    // Welcome Message for new users
                                    Text("Gemini is here to recommend the best card to use on your shopping trip. Start using the feature on our app today!")
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [cardBackground, Color.black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                    
 
                }
            }
            .navigationDestination(isPresented: $navigateToRecommendation) {
                RecommendationView(storeName: navigatedStoreName, prioritizeCategory: selectedCategory?.rawValue)
            }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
             // Refresh insight card data
             lastRecommendation = UserDefaults.standard.dictionary(forKey: "lastRecommendation")
        }
    }
    }
}


// MARK: - Subviews

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let cardBg: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let activeColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
            Text(title)
                .font(.system(size: 10, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(isActive ? activeColor : .gray)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .environmentObject(AuthManager())
    }
}
