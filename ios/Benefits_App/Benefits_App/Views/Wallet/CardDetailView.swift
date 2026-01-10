import SwiftUI

struct CardDetailView: View {
    let card: UserCard
    @Environment(\.presentationMode) var presentationMode
    
    // Colors (reused)
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 6)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Card Title
                VStack(spacing: 8) {
                    Text(card.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(card.brand)
                        .font(.subheadline)
                        .foregroundColor(textSecondary)
                }
                .padding(.bottom, 30)
                
                // Benefits List
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Card Benefits")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        
                        if let benefits = card.benefits, !benefits.isEmpty {
                            ForEach(benefits.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack(alignment: .top, spacing: 15) {
                                    ZStack {
                                        Circle()
                                            .fill(primaryBlue.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "star.fill") // Generic icon for now
                                            .foregroundColor(primaryBlue)
                                            .font(.system(size: 14))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(key)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(value)
                                            .font(.system(size: 14))
                                            .foregroundColor(textSecondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(16)
                            }
                        } else {
                            Text("No specific benefits listed for this card.")
                                .foregroundColor(textSecondary)
                                .italic()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
