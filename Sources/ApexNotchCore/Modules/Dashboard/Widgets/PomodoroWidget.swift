import SwiftUI
import UserNotifications

public enum PomodoroState: String {
    case work = "Deep Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}

@MainActor
public final class PomodoroManager: ObservableObject {
    public static let shared = PomodoroManager()
    
    @Published public private(set) var currentState: PomodoroState = .work
    @Published public private(set) var secondsRemaining: Int = 25 * 60
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var completedSessions: Int = 0
    
    private var timer: Timer?
    
    private init() {
        self.secondsRemaining = UserPreferences.shared.pomodoroWorkMinutes * 60
    }
    
    public var totalDurationForCurrentState: Int {
        switch currentState {
        case .work: return UserPreferences.shared.pomodoroWorkMinutes * 60
        case .shortBreak: return UserPreferences.shared.pomodoroBreakMinutes * 60
        case .longBreak: return 15 * 60
        }
    }
    
    public var progress: Double {
        let total = Double(totalDurationForCurrentState)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(secondsRemaining) / total)
    }
    
    public func toggleStartPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    public func start() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    public func reset() {
        pause()
        secondsRemaining = totalDurationForCurrentState
    }
    
    public func skip() {
        pause()
        advanceToNextState()
    }
    
    private func tick() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
        } else {
            // Finished
            notifyCompletion()
            advanceToNextState()
        }
    }
    
    private func advanceToNextState() {
        if currentState == .work {
            completedSessions += 1
            if completedSessions % 4 == 0 {
                currentState = .longBreak
            } else {
                currentState = .shortBreak
            }
        } else {
            currentState = .work
        }
        secondsRemaining = totalDurationForCurrentState
    }
    
    private func notifyCompletion() {
        let content = UNMutableNotificationContent()
        content.title = currentState == .work ? "Focus Session Completed!" : "Break Finished!"
        content.body = currentState == .work ? "Time for a refreshing break." : "Ready for your next deep work session?"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        AppState.shared.showToast(content.title)
    }
}

public struct PomodoroWidget: View {
    @ObservedObject private var pomodoro = PomodoroManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(pomodoro.currentState.rawValue, systemImage: pomodoro.currentState == .work ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(pomodoro.currentState == .work ? NotchDesign.accentRed : NotchDesign.accentGreen)
                
                Spacer()
                
                Text("Session #\(pomodoro.completedSessions + 1)")
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textTertiary)
            }
            
            HStack(spacing: 12) {
                // Circular progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .trim(from: 0, to: pomodoro.progress)
                        .stroke(
                            pomodoro.currentState == .work ? NotchDesign.accentRed : NotchDesign.accentGreen,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: pomodoro.isRunning ? "bolt.fill" : "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(NotchDesign.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeDisplay(seconds: pomodoro.secondsRemaining))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(NotchDesign.textPrimary)
                    
                    HStack(spacing: 8) {
                        Button(action: { pomodoro.toggleStartPause() }) {
                            Text(pomodoro.isRunning ? "Pause" : "Start")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(pomodoro.currentState == .work ? NotchDesign.accentRed : NotchDesign.accentGreen)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { pomodoro.reset() }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                                .foregroundColor(NotchDesign.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Reset Session")
                        
                        Button(action: { pomodoro.skip() }) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 10))
                                .foregroundColor(NotchDesign.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Skip Session")
                    }
                }
                
                Spacer()
            }
            
            // Ambient Focus Sounds Bar
            HStack(spacing: 5) {
                Text("Sound:")
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textTertiary)
                
                ForEach(AmbientSoundType.allCases) { sound in
                    let isActive = AmbientSoundService.shared.isPlaying && AmbientSoundService.shared.currentSound == sound
                    Button(action: {
                        AmbientSoundService.shared.toggleSound(sound)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: sound.icon)
                                .font(.system(size: 8))
                            Text(sound.rawValue)
                                .font(.system(size: 9))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isActive ? NotchDesign.accentCyan.opacity(0.25) : Color.white.opacity(0.06))
                        .foregroundColor(isActive ? NotchDesign.accentCyan : NotchDesign.textSecondary)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private func timeDisplay(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
