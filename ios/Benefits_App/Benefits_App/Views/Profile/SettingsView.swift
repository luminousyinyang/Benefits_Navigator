import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: - Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Hidden placeholder for alignment
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Account Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Information")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                CustomTextField(label: "First Name", text: $firstName)
                                CustomTextField(label: "Last Name", text: $lastName)
                                CustomTextField(label: "Email", text: $email)
                            }
                        }
                        
                        // MARK: - Actions
                        Button(action: {
                            // TODO: Implement update logic
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryBlue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.top, 24)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let user = authManager.userProfile {
                firstName = user.first_name
                lastName = user.last_name
                email = user.email
            }
        }
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            TextField("", text: $text)
                .padding()
                .background(Color(red: 28/255, green: 32/255, blue: 39/255))
                .cornerRadius(8)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
