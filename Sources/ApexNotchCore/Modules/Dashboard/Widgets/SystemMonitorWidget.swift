import SwiftUI

public struct SystemMonitorWidget: View {
    @ObservedObject private var sys = SystemStatsService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("System Metrics", systemImage: "cpu")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentCyan)
                
                Spacer()
                
                // Battery badge
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon)
                        .font(.system(size: 10))
                        .foregroundColor(sys.stats.isCharging ? NotchDesign.accentGreen : NotchDesign.textSecondary)
                    Text("\(sys.stats.batteryLevel)%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(NotchDesign.textSecondary)
                }
            }
            
            HStack(spacing: 12) {
                // CPU Gauge
                metricItem(
                    title: "CPU",
                    value: String(format: "%.0f%%", sys.stats.cpuUsagePercent),
                    percent: sys.stats.cpuUsagePercent / 100.0,
                    color: cpuColor(sys.stats.cpuUsagePercent)
                )
                
                // Memory Gauge
                metricItem(
                    title: "RAM",
                    value: String(format: "%.1f GB", Double(sys.stats.memoryUsedBytes) / 1_073_741_824.0),
                    percent: sys.stats.memoryPercent / 100.0,
                    color: NotchDesign.accentPurple
                )
                
                // Disk Gauge
                metricItem(
                    title: "Disk Free",
                    value: String(format: "%.0f GB", Double(sys.stats.diskFreeBytes) / 1_073_741_824.0),
                    percent: sys.stats.diskUsedPercent / 100.0,
                    color: NotchDesign.accentGreen
                )
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
        .onAppear {
            sys.startMonitoring()
        }
    }
    
    private func metricItem(title: String, value: String, percent: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textTertiary)
                Spacer()
                Text(value)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(NotchDesign.textPrimary)
            }
            
            GeometryReader { geo in
                let ratio = min(max(percent, 0.0), 1.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * ratio, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var batteryIcon: String {
        if sys.stats.isCharging { return "battery.100.bolt" }
        let lvl = sys.stats.batteryLevel
        if lvl > 75 { return "battery.100" }
        if lvl > 50 { return "battery.75" }
        if lvl > 25 { return "battery.50" }
        return "battery.25"
    }
    
    private func cpuColor(_ usage: Double) -> Color {
        if usage > 80 { return NotchDesign.accentRed }
        if usage > 50 { return NotchDesign.accentAmber }
        return NotchDesign.accentCyan
    }
}
