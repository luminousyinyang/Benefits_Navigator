import SwiftUI

struct ActionCenterView: View {
    let backgroundDark = Color(red: 16/255, green: 24/255, blue: 34/255)
    let cardBackground = Color(red: 28/255, green: 32/255, blue: 39/255)
    
    // Enumerating categories exactly as requested
    enum Category: String, CaseIterable {
        case carRental = "Car Rental Insurance Benefit"
        case airport = "Airport Benefits"
        case warranty = "Warranty Benefits"
        case priceProtection = "Price Protection Benefits"
        case returns = "Guaranteed Returns Benefit"
        case cellPhone = "Cell Phone Protection Benefit"
        
        var icon: String {
            switch self {
            case .carRental: return "car.fill"
            case .airport: return "airplane"
            case .warranty: return "shield.lefthalf.filled"
            case .priceProtection: return "chart.line.downtrend.xyaxis"
            case .returns: return "arrow.uturn.backward.circle.fill"
            case .cellPhone: return "iphone"
            }
        }
        
        var backendValue: String {
            switch self {
            case .carRental: return "car_rental_insurance"
            case .airport: return "airport_benefits"
            case .warranty: return "warranty_benefits"
            case .priceProtection: return "price_protection"
            case .returns: return "guaranteed_returns"
            case .cellPhone: return "cell_phone_protection"
            }
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text("Action Center")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Category.allCases, id: \.self) { category in
                            NavigationLink(destination: ActionCategoryView(category: category)) {
                                VStack(spacing: 16) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(red: 19/255, green: 109/255, blue: 236/255))
                                    
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .frame(height: 140)
                                .frame(maxWidth: .infinity)
                                .background(cardBackground)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
