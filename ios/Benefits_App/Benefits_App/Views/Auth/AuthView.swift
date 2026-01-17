import SwiftUI

struct AuthView: View {
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Animated Background
                BackgroundWavesView()
                
                // Dark Overlay to match theme but keep waves visible
                backgroundDark.opacity(0.7).ignoresSafeArea()

                // MARK: - Original Layout (Untouched)
                VStack {
                    Spacer()

                    // Icon
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(primaryBlue)
                        .padding(20)
                        .background(cardBackground)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(primaryBlue.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: primaryBlue.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    // Text Content
                    Text("Maximize Every Swipe")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    Text("Optimize your credit card benefits instantly with Gemini AI. Smart rewards, made simple.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 5)

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 15) {
                        NavigationLink(destination: SignUpView()) {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(cardBackground)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            //.navigationBarHidden(true) // Deprecated, but sticking to existing pattern if needed
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
