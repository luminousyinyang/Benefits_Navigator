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
                        
                        VStack(spacing: 12) {
                            // 1. Sign-On Bonus (if active)
                            if let bonus = card.sign_on_bonus {
                                SignOnBonusProgressView(bonus: bonus)
                            }
                            
                            // 2. Regular Benefits
                            if let benefits = card.benefits, !benefits.isEmpty {
                                ForEach(benefits, id: \.title) { benefit in
                                    BenefitRowView(benefit: benefit)
                                }
                            } else if card.sign_on_bonus == nil {
                                Text("No benefits data available.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct SignOnBonusProgressView: View {
    let bonus: SignOnBonus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title + Expiry Badge
            HStack {
                Text("Sign-on Bonus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let days = daysUntil(bonus.end_date) {
                    Text(days < 0 ? "EXPIRED" : "EXPIRES IN \(days) DAYS")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(days < 0 ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Progress Bar Section (Only if we have spend data, otherwise just text)
            // User requested "progress bar like in this picture".
            // Since we removed 'spend_goal', we can't show a % bar unless we infer it or just show accumulated spend.
            // But the user *also* said "if they know how much they contributed...".
            // If we don't know the goal, a progress bar is impossible.
            // Wait, the user said "spend_goal... not necessary" but also wanted a progress bar.
            // This implies either 1) The goal is known by the system (Gemini?), or 2) The user thinks they entered it?
            // I'll show the "Current Spend" as a value. If I can't compute %, I'll just show the text.
            // But to make it look like the picture (Uber Eats + 5% Back), maybe I just show the visual style?
            // "Free Delivery + 5% Back" -> "Earn 50,000 Points"
            // "$15/$20 Spend goal met" -> "$2000 Spent"
            
            Text("Earn \(formattedValue(bonus.bonus_value)) \(bonus.bonus_type)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            // Progress Bar Visual
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Capsule()
                        .frame(width: geometry.size.width, height: 8)
                        .foregroundColor(Color.gray.opacity(0.3))
                    
                    // Filled Track
                    Capsule()
                        .frame(width: min(progressWidth(geometry_width: geometry.size.width, current: bonus.current_spend, target: bonus.target_spend), geometry.size.width), height: 8)
                        .foregroundColor(.green)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("$\(formattedValue(bonus.current_spend))/$\(formattedValue(bonus.target_spend)) Spend goal met")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Spacer()
                Text("Offer ends \(bonus.end_date)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(red: 28/255, green: 32/255, blue: 39/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    func progressWidth(geometry_width: CGFloat, current: Double, target: Double) -> CGFloat {
        guard target > 0 else { return 0 }
        let percentage = current / target
        return geometry_width * CGFloat(percentage)
    }
    
    func formattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    func daysUntil(_ dateStr: String) -> Int? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: dateStr) else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return components.day
    }
}
