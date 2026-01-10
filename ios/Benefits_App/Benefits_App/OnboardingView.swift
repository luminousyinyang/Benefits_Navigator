import SwiftUI

struct OnboardingCardsView: View {
    // MARK: - App Theme Colors (Aligned with Home Screen)
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let secondaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Progress
                VStack(spacing: 8) {
                    Text("STEP 2 OF 4")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(1.2)
                        .foregroundColor(textSecondary)
                    
                    HStack(spacing: 6) {
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4).frame(width: 32, height: 6).foregroundColor(primaryBlue)
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                        Circle().frame(width: 6, height: 6).foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Headline
                        VStack(spacing: 12) {
                            Text("Let's Optimize Your\nWallet")
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .lineSpacing(-2)
                            
                            Text("Add your cards to reveal hidden benefits.")
                                .font(.system(size: 16))
                                .foregroundColor(textSecondary)
                        }
                        .padding(.top, 30)
                        
                        // Scan Button
                        Button(action: {}) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("Scan Physical Card")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: primaryBlue.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.horizontal, 4)
                        
                        // Divider
                        HStack {
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            Text("OR")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textSecondary)
                                .padding(.horizontal, 8)
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                        }
                        
                        // Search Bar (Using your cardBackground)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(textSecondary)
                            TextField("", text: .constant(""), prompt: Text("Search for card (e.g. Chase Sapphire)").foregroundColor(textSecondary.opacity(0.7)))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        // Tutorial Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APP TUTORIAL")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(textSecondary)
                                Spacer()
                                
                                // Gemini AI Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                    Text("GEMINI AI")
                                        .font(.system(size: 10, weight: .black))
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(primaryBlue.opacity(0.15))
                                .foregroundColor(primaryBlue)
                                .cornerRadius(20)
                                .overlay(Capsule().stroke(primaryBlue.opacity(0.3), lineWidth: 1))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    TutorialCard(
                                        icon: "doc.text.fill",
                                        title: "AI-Powered Analysis",
                                        description: "Gemini reads the fine print so you don't have to, identifying complex reward structures.",
                                        iconColor: primaryBlue,
                                        cardBg: cardBackground
                                    )
                                    
                                    TutorialCard(
                                        icon: "globe.americas.fill",
                                        title: "Hidden Perks",
                                        description: "We automatically find unused travel credits, insurance, and purchase protections.",
                                        iconColor: .purple,
                                        cardBg: cardBackground
                                    )
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            
            // Fixed Footer
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Button(action: {}) {
                        Text("Next Step")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .foregroundColor(backgroundDark)
                            .cornerRadius(14)
                    }
                    
                    Button(action: {}) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(backgroundDark.opacity(0.8).background(.ultraThinMaterial).ignoresSafeArea())
            }
        }
        .navigationBarHidden(true)
    }
}

struct TutorialCard: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    let cardBg: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(iconColor)
            }
            Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 157/255, green: 168/255, blue: 185/255))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 280, height: 180, alignment: .topLeading)
        .background(cardBg)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

struct OnboardingCardsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCardsView()
    }
}
