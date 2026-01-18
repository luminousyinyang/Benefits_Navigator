import SwiftUI

struct ShoppingConfirmationView: View {
    let storeName: String
    let onConfirm: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 16/255, green: 24/255, blue: 34/255).ignoresSafeArea()
            
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
                    
                    Button(action: onConfirm) {
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
