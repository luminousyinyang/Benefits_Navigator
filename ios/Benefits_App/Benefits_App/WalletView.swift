import SwiftUI

struct WalletView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    Text("Wallet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                    }
                }
                .padding(.horizontal)

                // Card Carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        CreditCardView(cardName: "CHASE SAPPHIRE", cardNumber: "**** **** **** 4242", cardHolder: "ALEXANDER DOE", cardBrand: "VISA", isPrimary: true)
                        CreditCardView(cardName: "GOLD CARD", cardNumber: "", cardHolder: "", cardBrand: "AMEX", isPrimary: false)
                        CreditCardView(cardName: "APPLE CARD", cardNumber: "", cardHolder: "", cardBrand: "Mastercard", isPrimary: false)
                    }
                    .padding()
                }

                // Tabs
                HStack {
                    TabButton(title: "All", isSelected: true)
                    TabButton(title: "Perks")
                    TabButton(title: "Offers")
                    TabButton(title: "Insights", hasIcon: true)
                }
                .padding(.horizontal)

                // Gemini Insights
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "auto_awesome")
                        Text("Gemini Insights").font(.headline)
                    }.foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))

                    InsightCard(
                        title: "Purchase Protection",
                        recommendation: "RECOMMENDED",
                        description: "You're browsing laptops. Use this card to get an extra year of warranty and 120 days of theft protection automatically.",
                        icon: "shield.lock.fill"
                    )
                    
                    InsightCard(
                        title: "Upcoming Travel",
                        description: "Detected flight booking to Tokyo. This card offers No Foreign Transaction Fees.",
                        icon: "airplane"
                    )
                }
                .padding()
                
                // Active Offers & Standard Perks would continue here...
            }
        }.background(Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
    }
}

struct TabButton: View {
    let title: String
    var isSelected: Bool = false
    var hasIcon: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack {
                if hasIcon {
                    Image(systemName: "auto_awesome")
                }
                Text(title)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(10)
            .foregroundColor(isSelected ? .blue : .gray)
        }
    }
}

struct CreditCardView: View {
    var cardName: String
    var cardNumber: String
    var cardHolder: String
    var cardBrand: String
    var isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(cardName)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "wifi")
            }
            Spacer()
            Text(cardNumber)
            HStack {
                Text(cardHolder)
                Spacer()
                Text(cardBrand)
                    .italic()
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .background(isPrimary ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(20)
    }
}

struct InsightCard: View {
    var title: String
    var recommendation: String? = nil
    var description: String
    var icon: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let recommendation = recommendation {
                    Text(recommendation)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Text(title)
                    .fontWeight(.bold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct OfferCard: View {
    var store: String
    var offer: String
    var progress: Double? = nil
    var expiresIn: String? = nil
    var isActive: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(store)
                    .fontWeight(.bold)
                Spacer()
                if let expiresIn = expiresIn {
                    Text(expiresIn)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            Text(offer)
            if let progress = progress {
                ProgressView(value: progress)
                Text("$\(Int(progress * 20))/$20 Spend goal met")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct PerkItem: View {
    var icon: String
    var title: String
    var subtitle: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.semibold)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}
