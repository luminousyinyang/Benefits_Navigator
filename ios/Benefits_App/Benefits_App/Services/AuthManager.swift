import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isOnboarded = false
    @Published var currentUserUID: String?
    @Published var userProfile: UserProfile?
    @Published var isLoadingProfile = false
    @Published var userCards: [UserCard] = []
    
    // Keys for persistence
    private let kAuthToken = "auth_token"
    private let kRefreshToken = "refresh_token"
    private let kTokenExpiry = "token_expiry"
    private let kUserUID = "user_uid"
    private let kIsOnboarded = "is_onboarded"
    private let kCachedProfile = "cached_profile"
    private let kCachedCards = "cached_cards"
    
    init() {
        // Observe internal refreshes
        NotificationCenter.default.addObserver(self, selector: #selector(handleTokenRefresh), name: NSNotification.Name("TokenRefreshed"), object: nil)
        
        // Restore session
        if let token = UserDefaults.standard.string(forKey: kAuthToken),
           let uid = UserDefaults.standard.string(forKey: kUserUID) {
            self.isLoggedIn = true
            self.currentUserUID = uid
            // Restore onboarded state
            self.isOnboarded = UserDefaults.standard.bool(forKey: kIsOnboarded)
            
            // Restore Tokens
            let refreshToken = UserDefaults.standard.string(forKey: kRefreshToken)
            let expiryDate = UserDefaults.standard.object(forKey: kTokenExpiry) as? Date
            
            // Initialize Service
            APIService.shared.setFullSession(authToken: token, refreshToken: refreshToken, expiry: expiryDate)
            
            // Restore Profile
            if let data = UserDefaults.standard.data(forKey: kCachedProfile),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                self.userProfile = profile
            }
            
            // Restore Cards
            if let data = UserDefaults.standard.data(forKey: kCachedCards),
               let cards = try? JSONDecoder().decode([UserCard].self, from: data) {
                print("Loaded \(cards.count) cards from cache")
                self.userCards = cards
            }
            
            // Refresh data in background
            Task {
                await refreshData()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleTokenRefresh() {
        // APIService has refreshed the token internally. We need to save the new state.
        if let token = APIService.shared.authToken {
             UserDefaults.standard.set(token, forKey: kAuthToken)
        }
        if let refresh = APIService.shared.refreshTokenString {
             UserDefaults.standard.set(refresh, forKey: kRefreshToken)
        }
        if let expiry = APIService.shared.tokenExpiryDate {
             UserDefaults.standard.set(expiry, forKey: kTokenExpiry)
        }
        print("AuthManager: Persisted refreshed tokens.")
    }
    
    func login(uid: String, token: String) {
        // Save state
        isLoggedIn = true
        currentUserUID = uid
        isLoadingProfile = true // Start loading to prevent flash
        
        // Persist (APIService is already updated by login call, pull from there or just save what we have)
        // LoginView usually calls APIService.login which currently returns AuthToken but we only passed `token` string here?
        // Wait, LoginView likely calls AuthManager.login(uid, token).
        // If we want to persist refresh token, we need to pass it or read from APIService.
        // Better: Read from APIService since it holds the ground truth now.
        
        UserDefaults.standard.set(token, forKey: kAuthToken)
        UserDefaults.standard.set(uid, forKey: kUserUID)
        
        if let refresh = APIService.shared.refreshTokenString {
             UserDefaults.standard.set(refresh, forKey: kRefreshToken)
        }
        if let expiry = APIService.shared.tokenExpiryDate {
             UserDefaults.standard.set(expiry, forKey: kTokenExpiry)
        }
        
        Task {
            await refreshData()
            DispatchQueue.main.async {
                self.isLoadingProfile = false
            }
        }
    }
    
    func refreshData() async {
        do {
            // 1. Fetch Profile
            let profile = try await APIService.shared.fetchUser()
            
            // 2. Fetch Cards
            let cards = try await APIService.shared.fetchUserCards()
            
            DispatchQueue.main.async {
                // Update State
                self.isOnboarded = profile.onboarded ?? false
                self.userProfile = profile 
                self.userCards = cards
                
                // Persist State
                UserDefaults.standard.set(self.isOnboarded, forKey: self.kIsOnboarded)
                
                if let encodedProfile = try? JSONEncoder().encode(profile) {
                    UserDefaults.standard.set(encodedProfile, forKey: self.kCachedProfile)
                }
                
                if let encodedCards = try? JSONEncoder().encode(cards) {
                    UserDefaults.standard.set(encodedCards, forKey: self.kCachedCards)
                }
            }
        } catch {
            print("Failed to refresh data: \(error)")
        }
    }
    
    func updateProfile(firstName: String, lastName: String, email: String, financialDetails: String? = nil) async throws {
        // Check if email is changing
        let isEmailChanging = self.userProfile?.email != email
        
        // Perform update
        let updatedProfile = try await APIService.shared.updateProfile(firstName: firstName, lastName: lastName, email: email, financialDetails: financialDetails)
        
        DispatchQueue.main.async {
            self.userProfile = updatedProfile
            // Update cache
            if let encodedProfile = try? JSONEncoder().encode(updatedProfile) {
                UserDefaults.standard.set(encodedProfile, forKey: self.kCachedProfile)
            }
            
            // If email changed, force logout logic (but maybe delay slightly or let the UI handle the transition)
            if isEmailChanging {
                self.logout()
            }
        }
    }
    
    func logout() {
        // Clear state
        isLoggedIn = false
        isOnboarded = false
        currentUserUID = nil
        userProfile = nil
        userCards = []
        
        // Clear persistence
        UserDefaults.standard.removeObject(forKey: kAuthToken)
        UserDefaults.standard.removeObject(forKey: kRefreshToken)
        UserDefaults.standard.removeObject(forKey: kTokenExpiry)
        UserDefaults.standard.removeObject(forKey: kUserUID)
        UserDefaults.standard.removeObject(forKey: kIsOnboarded)
        UserDefaults.standard.removeObject(forKey: kCachedProfile)
        UserDefaults.standard.removeObject(forKey: kCachedCards)
        
        TransactionService.shared.clearCache()
        
        APIService.shared.clearSession()
        UserDefaults.standard.removeObject(forKey: "lastRecommendation") // Clear Gemini Home Insight
    }
    
    func completeOnboarding() {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: kIsOnboarded)
    }
}
