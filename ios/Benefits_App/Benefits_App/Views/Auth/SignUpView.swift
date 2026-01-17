import SwiftUI

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
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
                Text("Create Account")
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
                    HStack {
                        TextField("", text: $firstName, prompt: Text("First Name").foregroundColor(.gray))
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        TextField("", text: $lastName, prompt: Text("Last Name").foregroundColor(.gray))
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
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
                    signup()
                }) {
                    Text("Create Account")
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
        .onTapGesture {
            hideKeyboard()
        }
        .alert(isPresented: $showAlert) {
             Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
    
    func signup() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Create Account
                let _ = try await APIService.shared.signup(email: email, password: password, firstName: firstName, lastName: lastName)
                
                // 2. Auto Login to get Token
                let token = try await APIService.shared.login(email: email, password: password)
                print("Signed up and logged in successfully")
                
                isLoading = false
                
                // 3. Update global state
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

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
