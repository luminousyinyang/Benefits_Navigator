import SwiftUI

struct BenefitRowView: View {
    let benefit: Benefit
    @State private var isExpanded = false
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let textSecondary = Color(red: 157/255, green: 168/255, blue: 185/255)
    
    var iconName: String {
        switch benefit.category.lowercased() {
        case "travel": return "airplane"
        case "dining": return "fork.knife"
        case "shopping": return "bag.fill"
        case "protection": return "shield.fill"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch benefit.category.lowercased() {
        case "travel": return .purple
        case "dining": return .orange
        case "shopping": return .pink
        case "protection": return .green
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(benefit.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(benefit.description)
                            .font(.system(size: 13))
                            .foregroundColor(textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    if benefit.details != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .background(cardBackground.opacity(0.5))
            
            if isExpanded, let details = benefit.details {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                        Text("DETAILS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(textSecondary)
                    }
                    .padding(.top, 8)
                    
                    Text(details)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(cardBackground.opacity(0.5))
            }
        }
        .cornerRadius(12)
    }
}
