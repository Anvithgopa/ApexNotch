import SwiftUI

public enum MusicVisualizerStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case bars = "Equalizer Bars"
    case wave = "Sound Wave"
    case dots = "Spectrum Dots"
    case pulse = "Radial Pulse"
    
    public var id: String { rawValue }
}

public struct AudioVisualizerView: View {
    public var isPlaying: Bool
    public var barColor: Color = NotchDesign.accentAmber
    public var style: MusicVisualizerStyle = .bars
    
    @NotchState private var barHeights: [CGFloat] = [0.4, 0.7, 0.9, 0.5, 0.8]
    @NotchState private var wavePhase: Double = 0.0
    @NotchState private var pulseScale: CGFloat = 1.0
    @NotchState private var timer: Timer? = nil
    
    public init(
        isPlaying: Bool,
        barColor: Color = NotchDesign.accentAmber,
        style: MusicVisualizerStyle = .bars
    ) {
        self.isPlaying = isPlaying
        self.barColor = barColor
        self.style = style
    }
    
    public var body: some View {
        Group {
            switch style {
            case .bars:
                barsView
            case .wave:
                waveView
            case .dots:
                dotsView
            case .pulse:
                pulseView
            }
        }
        .frame(height: 16)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - 1. Equalizer Bars
    private var barsView: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor)
                    .frame(width: 2.5, height: isPlaying ? max(barHeights[index] * 14.0, 3.0) : 3.0)
            }
        }
    }
    
    // MARK: - 2. Flowing Sound Wave
    private var waveView: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<6, id: \.self) { index in
                let height = isPlaying ? (sin(wavePhase + Double(index) * 0.8) * 5.0 + 7.0) : 3.0
                Capsule()
                    .fill(barColor)
                    .frame(width: 2, height: CGFloat(height))
            }
        }
    }
    
    // MARK: - 3. Bouncing Spectrum Dots
    private var dotsView: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(barColor)
                    .frame(width: 3, height: 3)
                    .offset(y: isPlaying ? -barHeights[index % barHeights.count] * 8.0 : 0)
            }
        }
    }
    
    // MARK: - 4. Radial Breathing Pulse
    private var pulseView: some View {
        ZStack {
            Circle()
                .stroke(barColor.opacity(0.4), lineWidth: 1.5)
                .scaleEffect(isPlaying ? pulseScale : 1.0)
                .opacity(isPlaying ? (2.0 - Double(pulseScale)) : 0.0)
            
            Circle()
                .fill(barColor)
                .frame(width: 6, height: 6)
        }
        .frame(width: 14, height: 14)
    }
    
    private func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.16, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.15)) {
                    barHeights = (0..<5).map { _ in CGFloat.random(in: 0.25...1.0) }
                    wavePhase += 0.45
                    pulseScale = pulseScale >= 1.6 ? 1.0 : (pulseScale + 0.15)
                }
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        barHeights = [0.2, 0.2, 0.2, 0.2, 0.2]
        wavePhase = 0
        pulseScale = 1.0
    }
}
