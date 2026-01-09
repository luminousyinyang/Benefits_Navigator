import SwiftUI

struct ManageCardsView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                // Gemini Optimizer Active
                HStack {
                    Image(systemName: "auto_awesome")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Gemini Optimizer Active")
                            .fontWeight(.bold)
                        Text("Your wallet is synced. 3 cards are currently optimized...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                .padding()

                // Linked Cards
                VStack(alignment: .leading) {
                    Text("Linked Cards")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    CardRow(cardName: "Amex Gold", cardDescription: "Top Pick: Dining & Groceries", cardIcon: "creditcard.fill", isPrimary: true)
                    CardRow(cardName: "Chase Freedom Flex", cardDescription: "5% Rotating • Q3 Active", cardIcon: "creditcard.fill")
                    CardRow(cardName: "Citi Custom Cash", cardDescription: "5% on Top Category", cardIcon: "creditcard.fill")
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            
            // Add New Card Button
            VStack {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "add_circle")
                        Text("Add New Card")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                HStack {
                    Button("Scan") {}
                    Spacer()
                    Button("Search") {}
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.bottom))
        }
        .navigationBarTitle("My Wallet", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {}) { Image(systemName: "arrow.backward.ios.new") },
            trailing: Button("Done") {}
        )
    }
}

struct CardRow: View {
    var cardName: String
    var cardDescription: String
    var cardIcon: String
    var isPrimary: Bool = false

    var body: some View {
        HStack {
            Image(systemName: cardIcon)
                .font(.title)
                .frame(width: 60, height: 40)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(5)
            VStack(alignment: .leading) {
                Text(cardName)
                    .fontWeight(.semibold)
                HStack {
                    if isPrimary {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                    }
                    Text(cardDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ManageCardsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageCardsView()
    }
}
