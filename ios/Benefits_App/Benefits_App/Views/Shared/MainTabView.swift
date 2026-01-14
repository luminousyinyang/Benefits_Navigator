import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Int = 0
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    init() {
        // Customize Tab Bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 16/255, green: 24/255, blue: 34/255, alpha: 1.0)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        itemAppearance.selected.iconColor = UIColor(red: 19/255, green: 109/255, blue: 236/255, alpha: 1.0)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 19/255, green: 109/255, blue: 236/255, alpha: 1.0)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            NavigationStack {
                WalletView()
            }
                .tabItem {
                    Label("Cards", systemImage: "wallet.pass.fill")
                }
                .tag(1)
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "doc.text.magnifyingglass")
                }
                .tag(2)
            
            ProfileView(showSettings: .constant(false))
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(primaryBlue)
    }
}
