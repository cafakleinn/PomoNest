//
//  PomodoroView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI
import Combine

struct PomodoroView: View {
    @State private var pomodoroViewModel = PomodoroViewModel()
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Timer Mode Indicator
                TimerModeView(timerMode: pomodoroViewModel.timerMode)
                
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(lineWidth: 24)
                        .opacity(0.1)
                        .foregroundColor(Color.accentColor)
                    
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(
                            lineWidth: 24,
                            lineCap: .round
                        ))
                        .foregroundColor(timerModeColor)
                        .rotationEffect(Angle(degrees: 270))
                        .animation(.linear, value: progress)
                    
                    VStack(spacing: 10) {
                        Text(pomodoroViewModel.formattedTime())
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(timerModeColor)
                        
                        Text(timerModeText)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if pomodoroViewModel.timerMode == .work {
                            Text("Session \(pomodoroViewModel.completedWorkSessions + 1)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 300, height: 300)
                
                // Control Buttons
                HStack(spacing: 30) {
                    // Reset Button
                    Button(action: {
                        pomodoroViewModel.resetTimer()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .foregroundColor(.red)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    // Play/Pause Button
                    Button(action: {
                        if pomodoroViewModel.timerState == .running {
                            pomodoroViewModel.pauseTimer()
                        } else {
                            pomodoroViewModel.startTimer()
                        }
                    }) {
                        Image(systemName: pomodoroViewModel.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(timerModeColor)
                            .clipShape(Circle())
                    }
                    
                    // Skip Button
                    Button(action: {
                        pomodoroViewModel.skipToNextSession()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                // Completed Sessions
                if pomodoroViewModel.completedWorkSessions > 0 {
                    VStack(spacing: 10) {
                        Text("Completed Sessions: \(pomodoroViewModel.completedWorkSessions)")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<min(pomodoroViewModel.completedWorkSessions, 8), id: \.self) { _ in
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Pomodoro Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                TimerSettingsView(viewModel: pomodoroViewModel, isPresented: $showingSettingsSheet)
            }
        }
    }
    
    private var progress: CGFloat {
        let totalSeconds: CGFloat
        let remainingSeconds = CGFloat(pomodoroViewModel.remainingSeconds)
        
        switch pomodoroViewModel.timerMode {
        case .work:
            totalSeconds = CGFloat(pomodoroViewModel.workDuration)
        case .shortBreak:
            totalSeconds = CGFloat(pomodoroViewModel.shortBreakDuration)
        case .longBreak:
            totalSeconds = CGFloat(pomodoroViewModel.longBreakDuration)
        }
        
        return 1.0 - (remainingSeconds / totalSeconds)
    }
    
    private var timerModeColor: Color {
        switch pomodoroViewModel.timerMode {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    private var timerModeText: String {
        switch pomodoroViewModel.timerMode {
        case .work:
            return "Focus Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
}

struct TimerModeView: View {
    let timerMode: PomodoroViewModel.TimerMode
    
    var body: some View {
        HStack(spacing: 20) {
            TimerModeButton(title: "Work", isSelected: timerMode == .work)
            TimerModeButton(title: "Short Break", isSelected: timerMode == .shortBreak)
            TimerModeButton(title: "Long Break", isSelected: timerMode == .longBreak)
        }
    }
}

struct TimerModeButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
    }
}

struct TimerSettingsView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @Binding var isPresented: Bool
    @State private var workMinutes: Double
    @State private var shortBreakMinutes: Double
    @State private var longBreakMinutes: Double
    @State private var sessionsUntilLongBreak: Double
    
    init(viewModel: PomodoroViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._workMinutes = State(initialValue: Double(viewModel.workDuration) / 60.0)
        self._shortBreakMinutes = State(initialValue: Double(viewModel.shortBreakDuration) / 60.0)
        self._longBreakMinutes = State(initialValue: Double(viewModel.longBreakDuration) / 60.0)
        self._sessionsUntilLongBreak = State(initialValue: Double(viewModel.sessionsUntilLongBreak))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Timer Durations")) {
                    VStack {
                        HStack {
                            Text("Work: \(Int(workMinutes)) min")
                            Spacer()
                        }
                        Slider(value: $workMinutes, in: 1...60, step: 1)
                    }
                    
                    VStack {
                        HStack {
                            Text("Short Break: \(Int(shortBreakMinutes)) min")
                            Spacer()
                        }
                        Slider(value: $shortBreakMinutes, in: 1...30, step: 1)
                    }
                    
                    VStack {
                        HStack {
                            Text("Long Break: \(Int(longBreakMinutes)) min")
                            Spacer()
                        }
                        Slider(value: $longBreakMinutes, in: 5...60, step: 1)
                    }
                }
                
                Section(header: Text("Pomodoro Cycle")) {
                    VStack {
                        HStack {
                            Text("Sessions until long break: \(Int(sessionsUntilLongBreak))")
                            Spacer()
                        }
                        Slider(value: $sessionsUntilLongBreak, in: 2...8, step: 1)
                    }
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.workDuration = Int(workMinutes * 60)
                        viewModel.shortBreakDuration = Int(shortBreakMinutes * 60)
                        viewModel.longBreakDuration = Int(longBreakMinutes * 60)
                        viewModel.sessionsUntilLongBreak = Int(sessionsUntilLongBreak)
                        viewModel.resetTimer()
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    PomodoroView()
}