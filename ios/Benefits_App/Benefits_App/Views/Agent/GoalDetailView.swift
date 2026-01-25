import SwiftUI

struct GoalDetailView: View {
    let goalText: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header (Like SideQuestsView)
                HStack {
                    Text("Your Goal")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                
                ScrollView {
                    Text(goalText)
                        .font(.body)
                        .foregroundColor(.white) // Using standard white instead of gray for better readability
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}
