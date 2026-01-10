import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                if !authManager.isOnboarded {
                     OnboardingCardsView()
                } else {
                    HomeView()
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
