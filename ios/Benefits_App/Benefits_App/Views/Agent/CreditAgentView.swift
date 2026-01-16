import SwiftUI

struct CreditAgentView: View {
    @StateObject private var agentService = AgentService.shared
    @State private var newGoal: String = ""
    @State private var isStarting = false
    @State private var selectedMilestone: Milestone? = nil
    @State private var isNewGoalPresented = false
    
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
                                isNewGoalPresented = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                    Text("New Goal")
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
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
        .sheet(isPresented: $isNewGoalPresented) {
            NewGoalView(agentService: agentService)
        }
    }
    
    // ... Onboarding View remains unchanged ...
    
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
            // Goal Header
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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1E293B"))
            )
            
            // Roadmap
            if let roadmap = state.roadmap, !roadmap.isEmpty {
                RoadmapPathView(milestones: roadmap) { selected in
                    self.selectedMilestone = selected
                }
            } else {
                // Fallback for old state or empty roadmap
                Text("Refresh to see your Roadmap!")
                    .foregroundColor(.gray)
                    .padding()
            }
            
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
        .sheet(item: $selectedMilestone) { milestone in
            MilestoneDetailView(milestone: milestone, reasoning: (milestone.status == "current") ? state.reasoning_summary : nil, agentService: agentService)
                .presentationDetents([.medium, .large])
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
}

// Separate View for New Goal Sheet
struct NewGoalView: View {
    @ObservedObject var agentService: AgentService
    @State private var goal: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set New Goal")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top)
            
            TextField("e.g. Maximize Chase Points", text: $goal)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            
            Button(action: {
                Task {
                    try? await agentService.startAgent(goal: goal)
                    dismiss()
                }
            }) {
                Text("Start Planning")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            .disabled(goal.isEmpty)
            
            Spacer()
        }
        .padding()
        .background(Color(hex: "0F172A").ignoresSafeArea())
    }
}

struct MilestoneDetailView: View {
    let milestone: Milestone
    let reasoning: String?
    @ObservedObject var agentService: AgentService
    
    @State private var notes: String = ""
    @State private var isNotesEditing = false
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Image
                VStack(spacing: 16) {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 50))
                        .foregroundColor(statusColor)
                        .padding(.top, 20)
                    
                    VStack(spacing: 6) {
                        Text(milestone.title)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(milestone.status.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Action Button (Mark Complete)
                        if milestone.status == "current" {
                            Button(action: {
                                Task { await agentService.updateMilestone(milestone, manualCompletion: true) }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Complete")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Progress Bar Section
                        if let goal = milestone.spending_goal, goal > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Spending Progress")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                let current = milestone.spending_current ?? 0
                                let progress = min(current / goal, 1.0)
                                
                                ProgressView(value: progress)
                                    .tint(.blue)
                                    .scaleEffect(x: 1, y: 3, anchor: .center)
                                    .frame(height: 12)
                                    .padding(.vertical, 4)
                                
                                HStack {
                                    Text("$\(Int(current))")
                                    Spacer()
                                    Text("$\(Int(goal))")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text(milestone.description)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // Reasoning
                        if let reasoning = reasoning {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Agent Strategy")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                
                                ForEach(parseReasoning(reasoning), id: \.self) { point in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("•").foregroundColor(.purple)
                                        Text(point).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("My Notes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(isNotesEditing ? "Save" : "Edit") {
                                    if isNotesEditing {
                                        Task { await agentService.updateMilestone(milestone, notes: notes) }
                                    }
                                    isNotesEditing.toggle()
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                            }
                            
                            if isNotesEditing {
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white) // Added foreground color for text editor
                            } else {
                                Text(notes.isEmpty ? "Add your own notes here..." : notes)
                                    .font(.body)
                                    .foregroundColor(notes.isEmpty ? .gray : .white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .onAppear {
            self.notes = milestone.user_notes ?? ""
        }
    }
    
    // ... Helpers (statusColor, parseReasoning) remain same ...
    var statusColor: Color {
        switch milestone.status {
        case "completed": return Color.green
        case "current": return Color.blue
        case "locked": return Color.gray
        default: return Color.gray
        }
    }
    
    func parseReasoning(_ summary: String) -> [String] {
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
 
// Helper for Hex Colors (unchanged)
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
