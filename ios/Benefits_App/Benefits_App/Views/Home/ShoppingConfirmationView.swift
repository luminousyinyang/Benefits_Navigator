import SwiftUI

struct ShoppingConfirmationView: View {
    let storeName: String
    let onConfirm: (String?) -> Void // Updated to pass back category
    let onDeny: () -> Void
    
    @State private var selectedCategory: ActionCenterView.Category? = nil
    
    // Custom Colors
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    let primaryBlue = Color(red: 19/255, green: 109/255, blue: 236/255)
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "cart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "F59E0B")) // Gold
                    .padding()
                    .background(Color(hex: "F59E0B").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(spacing: 12) {
                    Text("Shopping Detected")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Are you shopping at")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Text(storeName)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Priority Picker
                Menu {
                    Button(action: { selectedCategory = nil }) {
                        if selectedCategory == nil { Label("Maximize Rewards (Default)", systemImage: "checkmark") }
                        else { Text("Maximize Rewards (Default)") }
                    }
                    
                    Divider()
                    
                    ForEach(ActionCenterView.Category.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            if selectedCategory == category { Label(category.rawValue, systemImage: "checkmark") }
                            else { Text(category.rawValue) }
                        }
                    }
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(primaryBlue.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: selectedCategory?.icon ?? "star.circle.fill")
                                .foregroundColor(primaryBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedCategory?.rawValue ?? "Maximize Rewards")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(selectedCategory == nil ? "Finding the highest value card" : "Prioritizing this benefit")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                HStack(spacing: 20) {
                    Button(action: onDeny) {
                        Text("No")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                    
                    Button(action: {
                        onConfirm(selectedCategory?.rawValue)
                    }) {
                        Text("Yes")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "F59E0B"))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
    }
}
