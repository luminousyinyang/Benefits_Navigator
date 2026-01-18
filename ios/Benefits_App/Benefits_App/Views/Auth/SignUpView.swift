import SwiftUI

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    @State private var passwordMessage: String?
    @State private var confirmPasswordMessage: String?
    @State private var emailMessage: String? // Added for inline email error
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, password, confirmPassword
    }
    
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
                    
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(emailMessage != nil ? Color.red : Color.white.opacity(0.1), lineWidth: 1))
                            .onChange(of: email) { _ in emailMessage = nil }
                        
                        if let msg = emailMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 5)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(passwordMessage != nil ? Color.red : Color.white.opacity(0.1), lineWidth: 1))
                        
                        if let msg = passwordMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 5)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.gray))
                            .focused($focusedField, equals: .confirmPassword)
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(confirmPasswordMessage != nil ? Color.red : Color.white.opacity(0.1), lineWidth: 1))
                        
                        if let msg = confirmPasswordMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 5)
                        }
                    }
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
        .onChange(of: focusedField) { newValue in
            if newValue != .password && !password.isEmpty {
                if password.count < 6 {
                    passwordMessage = "Password must be at least 6 characters"
                } else {
                    passwordMessage = nil
                }
            }
            
            if newValue != .confirmPassword && !confirmPassword.isEmpty {
                if confirmPassword != password {
                    confirmPasswordMessage = "Passwords do not match"
                } else {
                    confirmPasswordMessage = nil
                }
            }
        }
    }
    
    func signup() {
        passwordMessage = nil
        confirmPasswordMessage = nil
        emailMessage = nil
        
        if password.count < 6 {
            passwordMessage = "Password must be at least 6 characters"
            return
        }
        
        if password != confirmPassword {
            confirmPasswordMessage = "Passwords do not match"
            return
        }
        
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
                let errorMsg = error.localizedDescription.lowercased()
                if errorMsg.contains("taken") || errorMsg.contains("exists") || errorMsg.contains("already") {
                    emailMessage = "Email is already taken"
                } else {
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
