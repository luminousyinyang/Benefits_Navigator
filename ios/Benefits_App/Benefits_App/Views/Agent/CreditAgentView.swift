import SwiftUI

struct CreditAgentView: View {
    @StateObject private var agentService = AgentService.shared
    @State private var newGoal: String = ""
    @State private var isStarting = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(hex: "0F172A"), Color(hex: "1E293B")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Credit Agent")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        if agentService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Button(action: {
                                Task { await agentService.refreshState() }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    if let state = agentService.state {
                        // Dashboard Mode
                        dashboardView(state: state)
                    } else {
                        // Onboarding Mode
                        onboardingView
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await agentService.startPolling()
            }
        }
    }
    
    // MARK: - Onboarding View
    
    var onboardingView: some View {
        VStack(spacing: 30) {
            Image(systemName: "brain.head.profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding()
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 140, height: 140)
                )
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text("Set Your Goal")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Tell the agent what you want to achieve (e.g., 'Business Class to Tokyo', 'Maximize Cash Back').")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter your goal...", text: $newGoal)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Button(action: startAgent) {
                HStack {
                    if isStarting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Agent")
                            .bold()
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(newGoal.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(16)
                .foregroundColor(.white)
            }
            .disabled(newGoal.isEmpty || isStarting)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1E293B").opacity(0.5))
        )
    }
    
    // MARK: - Dashboard View
    
    func dashboardView(state: AgentPublicState) -> some View {
        VStack(spacing: 20) {
            // Goal Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                    Text("CURRENT GOAL")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                Text(state.target_goal)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(state.progress_percentage ?? 0)%")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * (Double(state.progress_percentage ?? 0) / 100.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1E293B"))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            
            // Next Action Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("NEXT MOVE")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Spacer()
                    if let date = state.action_date {
                        Text(formatDate(date))
                            .font(.caption)
                            .padding(6)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                
                Text(state.next_action ?? "Analyzing...")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(nil)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1E293B"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Reasoning Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                    Text("AGENT REASONING")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(parseReasoning(state.reasoning_summary), id: \.self) { point in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                                .font(.body.bold())
                                .foregroundColor(.purple)
                            Text(point)
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1E293B"))
            )
            
            if state.status == "thinking" {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Agent is updating plan...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Actions
    
    func startAgent() {
        guard !newGoal.isEmpty else { return }
        isStarting = true
        Task {
            do {
                try await agentService.startAgent(goal: newGoal)
                isStarting = false
            } catch {
                print("Error: \(error)") // Handle error properly in real app
                isStarting = false
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        // Simple formatter, in real app use DateFormatter with ISO8601
        // Assuming YYYY-MM-DD
        return dateString
    }
    
    func parseReasoning(_ summary: String?) -> [String] {
        guard let summary = summary else { return [] }
        // Split by newline and clean up common bullet characters
        let lines = summary.components(separatedBy: "\n")
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return trimmed
                .replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "*", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
