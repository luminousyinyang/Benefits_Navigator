import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isOnboarded = false
    @Published var currentUserUID: String?
    @Published var userProfile: UserProfile?
    
    // In a real app, check Keychain/UserDefaults on init
    init() {}
    
    func login(uid: String) {
        // Save state
        isLoggedIn = true
        currentUserUID = uid
        // Create async task to check onboarding status
        Task {
            do {
                let profile = try await APIService.shared.fetchUser()
                DispatchQueue.main.async {
                    self.isOnboarded = profile.onboarded ?? false
                    self.userProfile = profile // Store the profile locally
                }
            } catch {
                print("Failed to fetch profile during login: \(error)")
            }
        }
    }
    
    func logout() {
        // Clear state
        isLoggedIn = false
        isOnboarded = false
        currentUserUID = nil
        APIService.shared.clearSession()
    }
    
    func completeOnboarding() {
        isOnboarded = true
    }
}
