import SwiftUI

struct RoadmapPathView: View {
    let milestones: [Milestone]
    let onSelect: (Milestone) -> Void
    
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let amplitude = (width / 2) - 90 // Increased margin to 90 to keep nodes away from edges
            
            ZStack(alignment: .top) {
                // Draw the Path Line with Gradient
                RoadmapPath(milestoneCount: milestones.count, amplitude: amplitude)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue, .gray, .gray],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [10, 5])
                    )
                    .frame(height: totalHeight)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // Place Nodes
                VStack(spacing: 0) {
                    ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                        MilestoneNodeView(milestone: milestone, index: index)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .offset(x: getXOffset(for: index, amplitude: amplitude))
                            .onTapGesture {
                                onSelect(milestone)
                            }
                    }
                }
            }
            .padding(.vertical, 40)
        }
        .frame(height: totalHeight + 80) // Add padding buffer
    }
    
    var totalHeight: CGFloat {
        max(CGFloat(milestones.count * 180), 400)
    }
    
    // ZigZag Logic
    func getXOffset(for index: Int, amplitude: CGFloat) -> CGFloat {
        if index == 0 { return 0 } // Start center
        // Alternating: 1 -> Right, 2 -> Left, 3 -> Right
        return (index % 2 == 1) ? amplitude : -amplitude
    }
}


struct RoadmapPath: Shape {
    let milestoneCount: Int
    let amplitude: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard milestoneCount > 1 else { return path }
        
        let spacing: CGFloat = 180 // Vertical space
        let midX = rect.midX
        
        // Helper for offset
        func getX(i: Int) -> CGFloat {
            if i == 0 { return midX }
            let offset = (i % 2 == 1) ? amplitude : -amplitude
            return midX + offset
        }
        
        // Start at first node
        let startX = getX(i: 0)
        let startY: CGFloat = 90 // Center of first node (180/2)
        
        path.move(to: CGPoint(x: startX, y: startY))
        
        for i in 1..<milestoneCount {
            let nextY = startY + (CGFloat(i) * spacing)
            let nextX = getX(i: i)
            
            // Previous point
            let prevY = startY + (CGFloat(i-1) * spacing)
            let prevX = getX(i: i-1)
            
            // Control points for smooth vertical entry/exit
            let controlY1 = prevY + (spacing * 0.5)
            let controlY2 = nextY - (spacing * 0.5)
            
            // Keep control X vertical to the node to ensure smooth stacking
            // This creates the "S" curve shape
            path.addCurve(to: CGPoint(x: nextX, y: nextY),
                          control1: CGPoint(x: prevX, y: controlY1),
                          control2: CGPoint(x: nextX, y: controlY2))
        }
        
        return path
    }
}

struct MilestoneNodeView: View {
    let milestone: Milestone
    let index: Int
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon Circle
            ZStack {
                // Pulse Effect for Current Node
                if milestone.status == "current" {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.5)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                isPulsing = true
                            }
                        }
                }
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: statusColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Active Ring
                if milestone.status == "current" {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 74, height: 74)
                }
                
                Image(systemName: milestone.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay(
                // Locked State Overlay
                milestone.status == "locked" ?
                Circle()
                    .fill(Color.black.opacity(0.4))
                : nil
            )
            
            // Label
            VStack(spacing: 4) {
                Text(milestone.title)
                    .font(.caption.bold())
                    .foregroundColor(.white) // Always white for better contrast against dark/colored bg
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1) // Strong shadow
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4)) // Semi-transparent backing
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                    .frame(width: 140) // Slightly wider
                
                if milestone.status == "current" {
                    Text("Current Step")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
        }
    }
    
    var statusColor: Color {
        switch milestone.status {
        case "completed": return Color.green
        case "current": return Color.blue
        case "locked": return Color.gray
        default: return Color.gray
        }
    }
}
