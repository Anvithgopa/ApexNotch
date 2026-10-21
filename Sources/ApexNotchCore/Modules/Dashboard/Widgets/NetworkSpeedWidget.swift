import SwiftUI

public struct NetworkSpeedWidget: View {
    @ObservedObject private var net = NetworkMonitor.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label("Network Traffic", systemImage: "network")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentGreen)
                
                Spacer()
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                            .foregroundColor(NotchDesign.accentCyan)
                        Text(net.currentSpeed.formattedDownload)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(NotchDesign.textPrimary)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                            .foregroundColor(NotchDesign.accentPurple)
                        Text(net.currentSpeed.formattedUpload)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(NotchDesign.textPrimary)
                    }
                }
            }
            
            // Sparkline chart
            sparklineChart
                .frame(height: 24)
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
            net.startMonitoring()
        }
    }
    
    private var sparklineChart: some View {
        GeometryReader { geo in
            let points = net.downloadHistory
            let maxVal = max(points.max() ?? 1.0, 1024.0)
            let stepX = points.count > 1 ? geo.size.width / CGFloat(points.count - 1) : 0
            
            Path { path in
                for (index, val) in points.enumerated() {
                    let norm = CGFloat(val / maxVal)
                    let x = CGFloat(index) * stepX
                    let y = geo.size.height * (1.0 - norm)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(NotchDesign.accentCyan, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
