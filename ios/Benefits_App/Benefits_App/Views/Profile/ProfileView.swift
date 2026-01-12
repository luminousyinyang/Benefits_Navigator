import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    @Binding var showSettings: Bool // Control navigation to settings if used as sheet or nav link depending on context
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // MARK: - Header
                    HStack {
                        Spacer()
                        
                        Text("Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            
                            // MARK: - Greeting Section
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Image(systemName: "pencil.circle.fill")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(primaryBlue)
                                        .background(Circle().fill(backgroundDark))
                                }
                                
                                Text("Hi \(authManager.userProfile?.first_name ?? "User")!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(authManager.userProfile?.email ?? "")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            // MARK: - Stats Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Benefits Earned", value: "$428", icon: "dollarsign.circle.fill", color: .green)
                                StatCard(title: "Cards Active", value: "3", icon: "creditcard.fill", color: .blue)
                                StatCard(title: "Credit Score", value: "780", icon: "chart.line.uptrend.xyaxis", color: .orange)
                                StatCard(title: "Next Reward", value: "2 Days", icon: "gift.fill", color: .purple)
                            }
                            .padding(.horizontal, 24)
                            
                            // MARK: - Recent Activity Placeholder
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Activity")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    ActivityRow(title: "Grocery Shopping", subtitle: "Amex Gold • 4x Points", amount: "+$4.20", date: "Today")
                                    ActivityRow(title: "Uber Ride", subtitle: "Chase Sapphire • 3x Points", amount: "+$2.15", date: "Yesterday")
                                    ActivityRow(title: "Netflix Subscription", subtitle: "Amex Platinum • Credit", amount: "$0.00", date: "Jan 10")
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    // Theme colors
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let date: String
    
    // Theme colors
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}
