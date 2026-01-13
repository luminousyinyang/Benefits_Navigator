import SwiftUI

struct CustomTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }
            
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(8)
                .scrollContentBackground(.hidden) // Needed for custom background
                .background(Color(red: 28/255, green: 32/255, blue: 39/255))
                .cornerRadius(8)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
