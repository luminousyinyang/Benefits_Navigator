import SwiftUI

struct CreditAgentView: View {
    @StateObject private var agentService = AgentService.shared
    @State private var newGoal: String = ""
    @State private var isStarting = false
    @State private var selectedMilestone: Milestone? = nil
    @State private var isNewGoalPresented = false
    @State private var showSideQuests = false
    @State private var showFullGoal = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(hex: "0F172A"), Color(hex: "1E293B")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) { // Main fixed container
                // FIXED Header
                HStack {
                    Text("Goal Roadmap")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if agentService.state != nil {
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
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Content Area
                if let state = agentService.state {
                    // Dashboard Mode (Fixed layout)
                    dashboardView(state: state)
                        .blur(radius: (state.status == "thinking") ? 10 : 0) // Blur content when thinking
                } else {
                    // Onboarding Mode (Scrollable)
                    ScrollView {
                        onboardingView
                            .padding()
                    }
                }
            }
            // Error Overlay
            if let state = agentService.state, state.status == "error" {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Planning Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(state.error_message ?? "Something went wrong. Please try again.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if let roadmap = state.roadmap, !roadmap.isEmpty {
                            // Dismiss error, show existing roadmap
                            var newState = state
                            newState.status = "idle"
                            agentService.state = newState
                        } else {
                            // No previous roadmap -> Go to start screen
                            agentService.clearState()
                        }
                    }) {
                        Text("Go Back")
                            .bold()
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .padding(40)
                .background(Color(hex: "1E293B"))
                .cornerRadius(20)
                .padding()
            }
            
            // Move Thinking Overlay to HERE (Top of ZStack) to cover everything including header
            if let state = agentService.state, state.status == "thinking" {
                Color.black.opacity(0.6).ignoresSafeArea() // Darker opacity
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    if let roadmap = state.roadmap, !roadmap.isEmpty {
                        Text("Re-evaluating Roadmap...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Analyzing new data to update your plan.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Building Your Roadmap...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Analyzing your goal to create a personalized strategy.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(40)
                .background(Color(hex: "0F172A").opacity(0.95))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .transition(.opacity) // Smooth transition
            }
        }
        .sheet(isPresented: $isNewGoalPresented) {
            NewGoalView(agentService: agentService)
        }
        .sheet(isPresented: $showFullGoal) {
            if let goal = agentService.state?.target_goal {
                GoalDetailView(goalText: goal)
                    .presentationDetents([.height(300), .medium]) // Smaller than half screen preferred, but expandable
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showSideQuests) {
            if let tasks = agentService.state?.optional_tasks {
                SideQuestsView(tasks: tasks)
                    .presentationDetents([.medium, .large])
            }
        }
    .onAppear {
        Task {
            await agentService.startPolling()
        }
    }
    .onDisappear {
        agentService.stopPolling()
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
            // FIXED Goal Header
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.blue)
                            Text("CURRENT GOAL")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                        }
                        
                        Text(state.target_goal)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .onTapGesture {
                        showFullGoal = true
                    }
                    Spacer()
                    
                    // Side Quests Button
                    if let tasks = state.optional_tasks, !tasks.isEmpty {
                            Button(action: { showSideQuests = true }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.bubble.fill")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "F59E0B")) // Premium Gold
                                    Text("Side Quests")
                                        .font(.caption2.bold())
                                        .foregroundColor(Color(hex: "F59E0B"))
                                }
                                .padding(8)
                                .background(Color(hex: "F59E0B").opacity(0.15))
                                .cornerRadius(12)
                            }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1E293B"))
            )
            .padding(.horizontal)
            
            // Scrollable Roadmap Panel
            ScrollView {
                VStack(spacing: 20) {
                    if let roadmap = state.roadmap, !roadmap.isEmpty {
                        RoadmapPathView(milestones: roadmap) { selected in
                            self.selectedMilestone = selected
                        }
                    } else {
                        // Fallback
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
                    
                    // Bottom padding for scroll
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(hex: "020617").opacity(0.3)) // Dark background for roadmap track
            .cornerRadius(24) // Rounded corners for the panel
            .padding(.horizontal)
            .padding(.bottom, 20)
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct MilestoneDetailView: View {
    let milestone: Milestone
    let reasoning: String?
    @ObservedObject var agentService: AgentService
    @Environment(\.dismiss) var dismiss
    
    @State private var notes: String = ""
    @State private var isNotesEditing = false
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Image
                VStack(spacing: 16) {
                    Image(systemName: (milestone.icon.isEmpty || milestone.icon == " ") ? "map.fill" : milestone.icon)
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
                                Task { 
                                    await agentService.updateMilestone(milestone, manualCompletion: true)
                                    dismiss()
                                }
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
                        
                        // Provide an Update Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Provide an update")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Stuck? Need a new strategy? Let the agent know.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                Task {
                                    await agentService.updateMilestone(milestone, notes: notes)
                                    // Dismiss popup immediately
                                    // Since this is inside MilestoneDetailView presented via sheet(item: $selectedMilestone) in CreditAgentView
                                    // We need to dismiss. But `selectedMilestone` is State in parent. 
                                    // The cleanest way is to use @Environment(\.dismiss)
                                    dismiss()
                                }
                            }) {
                                Text("Submit Update")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
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

struct SideQuestsView: View {
    let tasks: [OptionalTaskModel]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Side Quests")
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
                    VStack(spacing: 16) {
                        ForEach(tasks) { task in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: task.icon)
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "F59E0B"))
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: "F59E0B").opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(task.category.capitalized)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    // Impact Badge
                                    Text(task.impact)
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Text(task.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Button(action: {
                                    Task {
                                        do {
                                            try await AgentService.shared.completeTask(task.id)
                                            dismiss()
                                        } catch {
                                            print("Error completing task: \(error)")
                                        }
                                    }
                                }) {
                                    Text("Complete Quest")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "F59E0B")) // Gold for Button
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(hex: "1E293B"))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}
