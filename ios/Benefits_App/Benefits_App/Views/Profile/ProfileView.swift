import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var transactionService = TransactionService.shared
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    @Binding var showSettings: Bool
    

    
    // Computed Properties for Display
    var totalCashback: String {
        let val = authManager.userProfile?.total_cashback ?? 0.0
        return String(format: "$%.2f", val)
    }
    
    var topRetailer: String {
        return authManager.userProfile?.top_retailer ?? "N/A"
    }
    
    var recentTransactions: [Transaction] {
        return Array(transactionService.transactions.prefix(3))
    }
    
    var transactionsLastMonth: Int {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // Date formatter for parsing transaction dates (ISO 8601 YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return transactionService.transactions.filter { tx in
            if let date = formatter.date(from: tx.date) {
                return date >= oneMonthAgo
            }
            return false
        }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // MARK: - Header
                    ZStack {
                        Text("Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack {
                            Spacer()
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            
                            // MARK: - Greeting Section
                            VStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                
                                Text("Hi \(authManager.userProfile?.first_name ?? "User")!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(authManager.userProfile?.email ?? "")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            // MARK: - Stats Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Benefits Earned", value: totalCashback, icon: "dollarsign.circle.fill", color: .green)
                                StatCard(title: "Cards Active", value: "\(authManager.userCards.count)", icon: "creditcard.fill", color: .blue)
                                StatCard(title: "Top Merchant", value: topRetailer, icon: "cart.fill", color: .orange)
                                StatCard(title: "Transactions Last Month", value: "\(transactionsLastMonth)", icon: "calendar", color: .purple)
                            }
                            .padding(.horizontal, 24)
                            
                            // MARK: - Recent Activity
                            if !recentTransactions.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recent Activity")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(recentTransactions) { tx in
                                            ActivityRow(
                                                title: tx.retailer,
                                                subtitle: "\(tx.card_name ?? "Credit Card")",
                                                amount: tx.formattedCashback,
                                                date: tx.date
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await loadData(forceRefresh: true)
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }
    
    func loadData(forceRefresh: Bool = false) async {
        // Fetch fresh profile and cards for stats
        await authManager.refreshData()
        
        // Fetch transactions for list
        do {
            try await transactionService.fetchTransactions(forceRefresh: forceRefresh)
        } catch {
            print("Profile fetch error: \(error)")
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    // Theme colors
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let date: String
    
    // Theme colors
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}
