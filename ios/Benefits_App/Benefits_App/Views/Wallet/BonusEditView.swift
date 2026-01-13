
import SwiftUI

struct BonusEditView: View {
    let card: UserCard
    let bonus: SignOnBonus
    var parentView: WalletView
    
    @Environment(\.presentationMode) var presentationMode
    @State private var spendInput: String = ""
    @State private var showingDeleteAlert = false
    
    // Colors (copied for consistency)
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    var body: some View {
        ZStack {
            cardBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Edit Bonus for \(card.name)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CURRENT SPEND")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    TextField("Amount", text: $spendInput)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Button(action: save) {
                    Text("Update Progress")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: { showingDeleteAlert = true }) {
                    Text("Delete Bonus")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 24)
                
                Spacer()
            }
        }
        .onAppear {
            spendInput = String(format: "%.2f", bonus.current_spend)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Bonus?"),
                message: Text("Are you sure you want to delete this Sign Up Bonus? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    performDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func save() {
        guard let amount = Double(spendInput) else { return }
        Task {
            await parentView.performBonusUpdate(cardId: card.card_id ?? card.id, amount: amount)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func performDelete() {
        Task {
            await parentView.performBonusDelete(cardId: card.card_id ?? card.id)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
