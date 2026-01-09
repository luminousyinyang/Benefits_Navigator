import SwiftUI

struct RecommendationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack {
                    Text("Based on your purchase")
                        .font(.system(size: 24, weight: .bold))
                    Text("Optimized for your recent $120 dining expense")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(white: 0.3), Color(white: 0.2)]), startPoint: .top, endPoint: .bottom))
                            .frame(height: 200)
                        
                        HStack {
                            Image(systemName: "emoji_events")
                            Text("Best Value")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(18)
                        .padding()
                    }
                    
                    VStack(spacing: 16) {
                        VStack {
                            Text("Estimated Return")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Text("$15.40")
                                .font(.system(size: 40, weight: .bold))
                            Text("Chase Sapphire Reserve")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        HStack {
                            Image(systemName: "spark")
                            Text("POWERED BY GEMINI AI")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(18)
                    }
                    .padding()
                    .background(Color(white: 0.1))
                }
                .cornerRadius(20)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this card?").font(.headline).padding(.horizontal)
                    BenefitView(icon: "dollarsign.circle.fill", title: "3% Cash Back", description: "On Dining (Matches 'Dinner' category)")
                    BenefitView(icon: "flag.fill", title: "Sign-up Bonus", description: "Progress toward $600 bonus", progress: 0.6, remainingSpend: "$4,000 spend remaining")
                    BenefitView(icon: "shield.lefthalf.filled", title: "Purchase Protection", description: "Extended Warranty included automatically")
                }
                
                VStack(alignment: .leading) {
                    Text("Runner Up").font(.headline).padding(.horizontal)
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("Capital One Savor")
                                .fontWeight(.semibold)
                            Text("3% on Dining, no annual fee")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("$12.50")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
        .navigationBarTitle("Recommendation", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {}) { Image(systemName: "arrow.backward.ios.new") })
    }
}

struct BenefitView: View {
    var icon: String
    var title: String
    var description: String
    var progress: Double? = nil
    var remainingSpend: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                if let progress = progress {
                    ProgressView(value: progress)
                    if let remainingSpend = remainingSpend {
                        Text(remainingSpend)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct RecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationView()
    }
}
