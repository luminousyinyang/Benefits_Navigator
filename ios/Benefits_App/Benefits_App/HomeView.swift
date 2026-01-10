import SwiftUI

struct HomeView: View {
    // Custom Colors based on the wireframe
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    @State private var searchText = ""
    @State private var prioritizeWarranty = false
    @State private var firstName = ""
    
    @EnvironmentObject var authManager: AuthManager

    func fetchUserData() {
        guard let uid = authManager.currentUserUID else { return }
        
        Task {
            do {
                let profile = try await APIService.shared.fetchUser(uid: uid)
                DispatchQueue.main.async {
                    self.firstName = profile.first_name
                }
            } catch {
                print("Error fetching user profile: \(error)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header
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
                    .onAppear {
                        fetchUserData()
                    }
                    
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
                                    
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: primaryBlue.opacity(0.2), radius: 10, x: 0, y: 0)
                                
                                // Warranty Toggle
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(primaryBlue.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(primaryBlue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Prioritize Warranty")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Highlight cards with extended protection")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $prioritizeWarranty)
                                        .toggleStyle(SwitchToggleStyle(tint: primaryBlue))
                                        .labelsHidden()
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.bottom, 24)
                            
                            // MARK: - Action Grid
                            HStack(spacing: 16) {
                                NavigationLink(destination: WalletView()) {
                                    ActionButton(icon: "visibility", title: "Benefits", subtitle: "View at a glance", cardBg: cardBackground)
                                }
                                NavigationLink(destination: ManageCardsView()) {
                                    ActionButton(icon: "creditcard", title: "My Wallet", subtitle: "Manage cards", cardBg: cardBackground)
                                }
                            }
                            .padding(.bottom, 32)
                            
                            //                        Spacer(minLength: 40)
                            
                            // MARK: - Gemini Insight Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14))
                                    Text("GEMINI INSIGHT")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(primaryBlue)
                                
                                Text("Based on your location, you are near ")
                                    .foregroundColor(.gray)
                                + Text("Whole Foods")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                + Text(". Use your ")
                                    .foregroundColor(.gray)
                                + Text("Amex Gold")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                + Text(" for 4x points on groceries.")
                                    .foregroundColor(.gray)
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
                    
                    // MARK: - Bottom Tab Bar
                    VStack(spacing: 0) {
                        Divider().background(Color.gray.opacity(0.3))
                        HStack {
                            TabBarItem(icon: "house.fill", title: "Home", isActive: true, activeColor: primaryBlue)
                            TabBarItem(icon: "wallet.pass.fill", title: "Cards", isActive: false, activeColor: primaryBlue)
                            TabBarItem(icon: "safari.fill", title: "Discover", isActive: false, activeColor: primaryBlue)
                            TabBarItem(icon: "person.fill", title: "Profile", isActive: false, activeColor: primaryBlue)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                        .background(backgroundDark)
                    }
                }
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
            Image(systemName: icon == "visibility" ? "eye.fill" : "creditcard.fill")
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
        HomeView()
    }
}
