import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var actionManager = ActionManager()
    
    // Notification State
    struct ShoppingAlert: Identifiable {
        let id = UUID()
        let storeName: String
    }
    struct RecommendationRequest: Identifiable {
        let id = UUID()
        let storeName: String
    }
    
    @State private var shoppingAlert: ShoppingAlert?
    @State private var recommendationRequest: RecommendationRequest?
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                if authManager.isLoadingProfile {
                    ZStack {
                        Color(red: 16/255, green: 24/255, blue: 34/255).ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                } else if !authManager.isOnboarded {
                     OnboardingCardsView()
                } else {
                    MainTabView()
                }
            } else {
                NavigationView {
                    AuthView()
                }
            }
        }
        .environmentObject(authManager)
        .environmentObject(actionManager)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingDetection"))) { notification in
            if let store = notification.userInfo?["store"] as? String {
                self.shoppingAlert = ShoppingAlert(storeName: store)
            }
        }
        .fullScreenCover(item: $shoppingAlert) { alert in
            ShoppingConfirmationView(
                storeName: alert.storeName,
                onConfirm: {
                    self.shoppingAlert = nil
                    // Delay slightly to allow dismiss, then present recommendation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.recommendationRequest = RecommendationRequest(storeName: alert.storeName)
                    }
                },
                onDeny: {
                    self.shoppingAlert = nil
                }
            )
        }
        .fullScreenCover(item: $recommendationRequest) { request in
             RecommendationView(storeName: request.storeName, prioritizeCategory: nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
