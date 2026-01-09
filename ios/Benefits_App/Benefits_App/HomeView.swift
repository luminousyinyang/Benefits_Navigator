import SwiftUI

struct HomeView: View {
    @State private var searchIsActive = false
    @State private var prioritizeWarranty = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("Alex")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Spacer()
                        Button(action: {}) {
                            HStack {
                                Text("Sign Out")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Image(systemName: "logout")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Headline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximize your rewards today.")
                            .font(.system(size: 32, weight: .bold))
                        Text("Let Gemini find the best card for your purchase.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                        TextField("Where are you shopping?", text: .constant(""))
                        Image(systemName: "mic.fill")
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    
                    // Warranty Toggle
                    Toggle(isOn: $prioritizeWarranty) {
                        HStack {
                            Image(systemName: "security.fill")
                                .foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                            VStack(alignment: .leading) {
                                Text("Prioritize Warranty")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Highlight cards with extended protection")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .tint(Color(red: 19/255, green: 109/255, blue: 236/255))
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        NavigationLink(destination: WalletView()) {
                            ActionCard(icon: "visibility", title: "Benefits", subtitle: "View at a glance")
                        }
                        NavigationLink(destination: ManageCardsView()) {
                            ActionCard(icon: "credit_card", title: "My Wallet", subtitle: "Manage cards")
                        }
                    }
                    
                    // Gemini Insight
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "auto_awesome")
                            Text("Gemini Insight")
                                .font(.system(size: 12, weight: .bold))
                        }.foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                        
                        Text("Based on your location, you are near Whole Foods. Use your Amex Gold for 4x points on groceries.")
                            .font(.system(size: 14))
                    }
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color(white: 0.2), Color(white: 0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.all))
            .foregroundColor(.white)
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .foregroundColor(.white)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
