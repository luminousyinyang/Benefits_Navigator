import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
