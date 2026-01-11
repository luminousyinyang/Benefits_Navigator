import SwiftUI

struct CardDetailView: View {
    let card: UserCard
    @Environment(\.presentationMode) var presentationMode
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // Card Image Visual
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 200)
                        
                        VStack {
                            Spacer()
                            HStack {
                                Text(card.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .padding(25)
                    }
                    .padding(.horizontal)
                    
                    // Benefits List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rich Benefits")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        if let benefits = card.benefits, !benefits.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(benefits, id: \.title) { benefit in
                                    BenefitRowView(benefit: benefit)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No benefits data available.")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
