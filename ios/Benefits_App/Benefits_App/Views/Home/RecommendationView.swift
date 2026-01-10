import SwiftUI

struct RecommendationView: View {
    // Exact colors from your configuration
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Top App Bar
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("Recommendation")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 20, height: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Headline Text
                    VStack(spacing: 6) {
                        Text("Based on your purchase")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Optimized for your recent $120 dining expense")
                            .font(.system(size: 15))
                            .foregroundColor(textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    
                    // Hero Card Section
                    HeroCardView(primaryBlue: primaryBlue, secondaryBlue: secondaryBlue, cardBackground: cardBackground, textSecondary: textSecondary)
                        .padding(.horizontal)
                    
                    // Benefits Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WHY THIS CARD?")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textSecondary)
                            .tracking(1)
                        
                        BenefitRow(icon: "banknote.fill", iconColor: .green, title: "3% Cash Back", subtitle: "On Dining (Matches 'Dinner' category)", cardBackground: cardBackground)
                        
                        SignUpBonusCard(cardBackground: cardBackground, primaryBlue: primaryBlue, textSecondary: textSecondary)
                        
                        BenefitRow(icon: "shield.fill", iconColor: .purple, title: "Purchase Protection", subtitle: "Extended Warranty included automatically", cardBackground: cardBackground)
                    }
                    .padding(.horizontal)
                    
                    // Runner Up
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
                                Text("Capital One Savor")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("3% on Dining, no annual fee")
                                    .font(.system(size: 12))
                                    .foregroundColor(textSecondary)
                            }
                            Spacer()
                            Text("$12.50")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 120)
                }
            }
            
            // Sticky Footer CTA
            VStack {
                Spacer()
                Button(action: {}) {
                    HStack {
                        Text("Use this Card")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(primaryBlue)
                    .cornerRadius(14)
                    .shadow(color: primaryBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(gradient: Gradient(colors: [backgroundDark.opacity(0), backgroundDark]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            }
        }
    }
}

struct HeroCardView: View {
    let primaryBlue: Color
    let secondaryBlue: Color
    let cardBackground: Color
    let textSecondary: Color
    
    var body: some View {
        ZStack {
            // Glow Effect
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [primaryBlue.opacity(0.6), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blur(radius: 10)
                .padding(-2)
            
            VStack(spacing: 0) {
                // Card Visual
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [Color(white: 0.12), Color(white: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .aspectRatio(1.6, contentMode: .fit)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.04))
                        )
                    
                    // Best Value Badge
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                        Text("BEST VALUE")
                            .font(.system(size: 10, weight: .black))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(secondaryBlue) // Using secondaryBlue for high-visibility badge
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(14)
                }
                
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("ESTIMATED RETURN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textSecondary)
                            .tracking(0.5)
                        
                        Text("$15.40")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("Chase Sapphire Reserve")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Gemini AI Pill
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("POWERED BY GEMINI AI")
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
            }
            Spacer()
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}

struct SignUpBonusCard: View {
    let cardBackground: Color
    let primaryBlue: Color
    let textSecondary: Color
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(primaryBlue.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: "flag.fill").foregroundColor(primaryBlue).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign-up Bonus").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text("Progress toward $600 bonus").font(.system(size: 14)).foregroundColor(textSecondary)
                }
                Spacer()
                Text("60%").font(.system(size: 11, weight: .bold)).padding(.horizontal, 8).padding(.vertical, 4).background(Color.white.opacity(0.08)).foregroundColor(textSecondary).cornerRadius(6)
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 8)
                        Capsule().fill(primaryBlue).frame(width: geo.size.width * 0.6, height: 8)
                    }
                }.frame(height: 8)
                Text("$4,000 spend remaining").font(.system(size: 11, weight: .medium)).foregroundColor(textSecondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    RecommendationView()
}
