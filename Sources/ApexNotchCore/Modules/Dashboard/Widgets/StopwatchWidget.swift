import SwiftUI

@MainActor
public final class StopwatchManager: ObservableObject {
    public static let shared = StopwatchManager()
    
    @Published public private(set) var elapsedTime: TimeInterval = 0.0
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var laps: [TimeInterval] = []
    
    private var timer: Timer?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0.0
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        if let start = startTime {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        startTime = nil
        timer?.invalidate()
        timer = nil
    }
    
    public func reset() {
        stop()
        accumulatedTime = 0.0
        elapsedTime = 0.0
        laps.removeAll()
    }
    
    public func lap() {
        guard isRunning else { return }
        laps.insert(elapsedTime, at: 0)
    }
    
    private func tick() {
        if let start = startTime {
            elapsedTime = accumulatedTime + Date().timeIntervalSince(start)
        }
    }
}

public struct StopwatchWidget: View {
    @ObservedObject private var stopwatch = StopwatchManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label("Stopwatch", systemImage: "stopwatch.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentCyan)
                
                Spacer()
                
                if !stopwatch.laps.isEmpty {
                    Text("\(stopwatch.laps.count) Laps")
                        .font(.system(size: 9))
                        .foregroundColor(NotchDesign.textTertiary)
                }
            }
            
            Text(formatTime(stopwatch.elapsedTime))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(NotchDesign.textPrimary)
            
            HStack(spacing: 12) {
                Button(action: {
                    if stopwatch.isRunning {
                        stopwatch.stop()
                    } else {
                        stopwatch.start()
                    }
                }) {
                    Text(stopwatch.isRunning ? "Stop" : "Start")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(stopwatch.isRunning ? NotchDesign.accentRed : NotchDesign.accentGreen)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                if stopwatch.isRunning {
                    Button("Lap") { stopwatch.lap() }
                        .font(.system(size: 10))
                        .buttonStyle(.plain)
                        .foregroundColor(NotchDesign.textSecondary)
                } else if stopwatch.elapsedTime > 0 {
                    Button("Reset") { stopwatch.reset() }
                        .font(.system(size: 10))
                        .buttonStyle(.plain)
                        .foregroundColor(NotchDesign.textSecondary)
                }
            }
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}
