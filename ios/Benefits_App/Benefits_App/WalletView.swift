import SwiftUI

struct WalletView: View {
    // MARK: - Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Card Carousel
                        cardCarousel
                        
                        // Tabs
                        tabSection
                        
                        VStack(alignment: .leading, spacing: 30) {
                            // Gemini Insights
                            geminiInsightsSection
                            
                            // Active Offers
                            activeOffersSection
                            
                            // Standard Perks
                            standardPerksSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for FAB
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
    }
    
    // MARK: - Subviews
    
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Main Chase Card
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [primaryBlue, secondaryBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 320, height: 200)
                    .overlay(
                        VStack(alignment: .leading) {
                            HStack {
                                Text("CHASE SAPPHIRE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                Spacer()
                                Image(systemName: "wave.3.right")
                            }
                            Spacer()
                            Image(systemName: "cpu.fill")
                                .font(.title)
                                .rotationEffect(.degrees(90))
                            Spacer()
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("**** **** **** 4242")
                                        .font(.system(.body, design: .monospaced))
                                    Text("ALEXANDER DOE")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                Spacer()
                                Text("VISA")
                                    .font(.title3)
                                    .italic()
                                    .fontWeight(.black)
                            }
                        }
                        .padding(25)
                        .foregroundColor(.white)
                    )
                
                // Secondary Gold Card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 320, height: 200)
                    .opacity(0.4)
            }
            .padding(.horizontal)
        }
    }
    
    private var tabSection: some View {
        HStack(spacing: 0) {
            tabItem(title: "All", isActive: false)
            tabItem(title: "Perks", isActive: false)
            tabItem(title: "Offers", isActive: false)
            tabItem(title: "Insights", isActive: true, icon: "sparkles")
        }
        .padding(.horizontal)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1), alignment: .bottom
        )
    }
    
    private func tabItem(title: String, isActive: Bool, icon: String? = nil) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(isActive ? primaryBlue : textSecondary)
            
            Rectangle()
                .fill(isActive ? primaryBlue : Color.clear)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
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
    
    private var activeOffersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Offers")
                .font(.headline)
                .foregroundColor(.white)
            
            // Uber Eats Card
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 100)
                    
                    HStack {
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white)
                        Text("Uber Eats")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text("EXPIRES IN 3 DAYS")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Free Delivery + 5% Back")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                                Capsule().fill(Color.green).frame(width: 120, height: 6)
                            }
                            Text("$15/$20 Spend goal met")
                                .font(.system(size: 10))
                                .foregroundColor(textSecondary)
                        }
                    }
                    Spacer()
                    Button("Activate") {}
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .background(cardBackground)
            }
            .cornerRadius(16)
        }
    }
    
    private var standardPerksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Standard Perks")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                perkRow(icon: "fork.knife", title: "3x Points on Dining", sub: "Worldwide", color: .blue)
                perkRow(icon: "airplane", title: "5x Points on Travel", sub: "Booked through Chase", color: .purple)
                perkRow(icon: "dollarsign.circle", title: "No Foreign Transaction Fees", sub: nil, color: .green)
            }
        }
    }
    
    private func perkRow(icon: String, title: String, sub: String?, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                if let sub = sub {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}
