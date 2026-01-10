import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserUID: String? = nil
    
    // In a real app, check Keychain/UserDefaults on init
    init() {
        // Example: logic to check if user is already logged in
        // isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    func login(uid: String) {
        // Save state
        isLoggedIn = true
        currentUserUID = uid
    }
    
    func logout() {
        // Clear state
        isLoggedIn = false
        currentUserUID = nil
    }
}
