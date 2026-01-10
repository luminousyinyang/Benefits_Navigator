import SwiftUI

struct AuthView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Animated Background
                BackgroundWavesView()

                // MARK: - Original Layout (Untouched)
                VStack {
                    Spacer()

                    // Icon
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    
                    // Text Content
                    Text("Maximize Every Swipe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
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
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .ignoresSafeArea()
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 1.0, opacity: 0.1)) // Darker transparent look
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        VStack { Divider().background(Color.gray) }
                        Text("Or continue with")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        VStack { Divider().background(Color.gray) }
                    }
                    .padding()

                    // Social Buttons
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Image(systemName: "applelogo")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 1.0, opacity: 0.05))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }

                        Button(action: {}) {
                            Image(systemName: "g.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 1.0, opacity: 0.05))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)

                    // Footer
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
