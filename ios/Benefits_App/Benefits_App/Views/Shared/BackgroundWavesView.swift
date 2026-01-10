import SwiftUI

// 1. The custom Wave Shape for the background animation
struct Wave: Shape {
    var offset: Angle
    var percent: Double
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lowThreshold = rect.height * percent
        let waveHeight: CGFloat = 20
        
        path.move(to: CGPoint(x: 0, y: lowThreshold))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset.radians)
            let y = lowThreshold + (sine * waveHeight)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct BackgroundWavesView: View {
    @State private var waveOffset = Angle(degrees: 0)
    
    var body: some View {
        ZStack {
            // Deep dark base
            Color(red: 0.05, green: 0.08, blue: 0.1)
                .edgesIgnoringSafeArea(.all)
            
            ZStack {
                Wave(offset: waveOffset, percent: 0.6)
                    .fill(Color.blue.opacity(0.15))
                    .offset(y: 50)
                
                Wave(offset: waveOffset + Angle(degrees: 180), percent: 0.65)
                    .fill(Color.cyan.opacity(0.1))
                    .offset(y: 100)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                waveOffset = Angle(degrees: 360)
            }
        }
    }
}
