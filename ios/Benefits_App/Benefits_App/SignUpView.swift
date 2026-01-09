import SwiftUI

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    // Inject AuthManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            BackgroundWavesView()
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
                TextField("", text: $name, prompt: Text("Name").foregroundColor(.white.opacity(0.4)))
                TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.4)))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.4)))
            }
            .padding()
            .background(Color(white: 1.0, opacity: 0.05))
            .cornerRadius(10)
            .foregroundColor(.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.bottom, 15)

            Button(action: {
                signup()
            }) {
                Text("Create Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding(.top, 10)

            Spacer()
        }
        .padding(.horizontal)
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
                let uid = try await APIService.shared.signup(email: email, password: password)
                print("Signed up successfully: \(uid)")
                isLoading = false
                
                // Update global state to log in
                DispatchQueue.main.async {
                    authManager.login()
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
