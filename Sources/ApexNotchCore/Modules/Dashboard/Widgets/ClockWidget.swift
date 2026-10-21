import SwiftUI
import Combine

public struct ClockWidget: View {
    @NotchState private var currentTime = Date()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // World clock cities
    private let worldCities: [(city: String, tz: String)] = [
        ("London", "Europe/London"),
        ("Tokyo", "Asia/Tokyo"),
        ("New York", "America/New_York"),
        ("San Francisco", "America/Los_Angeles")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString(for: currentTime, timeZone: .current))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(NotchDesign.textPrimary)
                    
                    Text(dateString(for: currentTime))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NotchDesign.accentCyan)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(NotchDesign.accentCyan.opacity(0.8))
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // World Clocks mini row
            HStack(spacing: 12) {
                ForEach(worldCities, id: \.city) { item in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.city)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(NotchDesign.textTertiary)
                        Text(timeString(for: currentTime, timeZoneId: item.tz))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(NotchDesign.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    private func timeString(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }
    
    private func timeString(for date: Date, timeZoneId: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneId) ?? .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}
