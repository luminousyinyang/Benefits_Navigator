import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    // Inject AuthManager
    @EnvironmentObject var authManager: AuthManager

    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)

    var body: some View {
        ZStack {
            BackgroundWavesView()
            
            // Dark Overlay
            backgroundDark.opacity(0.85).ignoresSafeArea()
            
            VStack {
                Text("Log In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .padding(.bottom, 30)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding()
                }

                Group {
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .foregroundColor(.white)
                .padding(.bottom, 15)

                Button(action: {
                    login()
                }) {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }

    func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let token = try await APIService.shared.login(email: email, password: password)
                print("Logged in successfully: \(token)")
                isLoading = false
                
                // Update global state
                DispatchQueue.main.async {
                    authManager.login(uid: token.local_id, token: token.id_token)
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
