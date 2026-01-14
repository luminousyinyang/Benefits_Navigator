import SwiftUI
import UniformTypeIdentifiers

struct TransactionsView: View {
    @StateObject private var transactionService = TransactionService.shared
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isImporting = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var isProcessing = false
    @State private var searchText = ""
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return transactionService.transactions
        } else {
            return transactionService.transactions.filter { $0.retailer.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                
                if isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(primaryBlue)
                        Text("Processing Statements...\nThis feature relies on Gemini 3 Pro")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .zIndex(1)
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Transactions")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Button(action: {
                            isImporting = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(primaryBlue)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Search Bar
                    HStack {
                         Image(systemName: "magnifyingglass")
                             .foregroundColor(.gray)
                         TextField("Search transactions", text: $searchText)
                             .foregroundColor(.white)
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    if filteredTransactions.isEmpty && !isProcessing {
                        // Empty State
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                            Text("No transactions yet")
                            .font(.title3)
                            .foregroundColor(.white)
                            Text("Import your credit card statements (PDF) to see your spending and rewards.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        // Transaction List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTransactions) { transaction in
                                    TransactionRow(transaction: transaction)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .refreshable {
                            await loadData(forceRefresh: true)
                        }
                    }
                }
                .blur(radius: isProcessing ? 5 : 0) // Blur content when processing
            }
            .disabled(isProcessing)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData(forceRefresh: Bool = false) async {
        // No longer need to fetch token here, Service handles it
        do {
            try await transactionService.fetchTransactions(forceRefresh: forceRefresh)
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            isProcessing = true
            
            Task {
                var errorCount = 0
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else {
                        errorCount += 1
                        continue
                    }
                    
                    do {
                        // No longer need token here
                        try await transactionService.uploadStatement(fileURL: url)
                    } catch {
                        print("Failed to upload \(url.lastPathComponent): \(error)")
                        errorCount += 1
                    }
                    
                    url.stopAccessingSecurityScopedResource()
                }
                
                // Refresh list
                await loadData()
                
                DispatchQueue.main.async {
                    isProcessing = false
                    if errorCount > 0 {
                        importErrorMessage = "Failed to import \(errorCount) file(s)."
                        showImportError = true
                    }
                }
            }
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    // Theme colors
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.retailer)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(transaction.date)
                    Text("•")
                    Text(transaction.card_name ?? "Credit Card")
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                
                Text(transaction.formattedCashback)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
}
