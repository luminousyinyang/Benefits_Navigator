import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    // In a real app, check Keychain/UserDefaults on init
    init() {
        // Example: logic to check if user is already logged in
        // isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    func login() {
        // Save state
        isLoggedIn = true
    }
    
    func logout() {
        // Clear state
        isLoggedIn = false
    }
}
