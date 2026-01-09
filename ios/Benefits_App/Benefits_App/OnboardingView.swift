import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                // Progress Bar
                VStack {
                    Text("Step 2 of 4")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 5) {
                        Circle().frame(width: 5, height: 5).foregroundColor(.gray)
                        Rectangle().frame(width: 30, height: 5).foregroundColor(.blue)
                        Circle().frame(width: 5, height: 5).foregroundColor(.gray)
                        Circle().frame(width: 5, height: 5).foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Headline
                Text("Let's Optimize Your Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Add your cards to reveal hidden benefits.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                    
                // Scan Button & Search
                VStack(spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "photo_camera")
                            Text("Scan Physical Card")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Text("OR").foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search for card (e.g. Chase Sapphire)", text: .constant(""))
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                // App Tutorial Carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        TutorialCard(icon: "text_snippet", title: "AI-Powered Analysis", description: "Gemini reads the fine print so you don't have to, identifying complex reward structures instantly.")
                        TutorialCard(icon: "travel_explore", title: "Hidden Perks", description: "We automatically find unused travel credits, insurance benefits, and purchase protections.")
                        TutorialCard(icon: "savings", title: "Maximize Value", description: "Get real-time suggestions on which card to use for every purchase to maximize points.")
                    }
                    .padding()
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            
            // Footer
            VStack {
                Button(action: {}) {
                    Text("Next Step")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                Button("Skip for now") {}.foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 16/255, green: 24/255, blue: 34/255).edgesIgnoringSafeArea(.bottom))
        }
    }
}

struct TutorialCard: View {
    var icon: String
    var title: String
    var description: String

    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            Text(title)
                .fontWeight(.bold)
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 280)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
