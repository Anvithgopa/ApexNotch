import SwiftUI

public struct MusicPlayerView: View {
    @ObservedObject private var music = MusicPlayerManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Album Art Thumbnail (Left)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.1, blue: 0.05), Color(red: 0.1, green: 0.08, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                
                Image(systemName: "music.note")
                    .font(.system(size: 30))
                    .foregroundColor(NotchDesign.accentAmber)
            }
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
            
            // Middle: Title, Subtitle, Timeline, Controls
            VStack(alignment: .leading, spacing: 4) {
                Text(music.currentTrack.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(NotchDesign.textPrimary)
                    .lineLimit(1)
                
                Text(music.currentTrack.artist.isEmpty ? "ApexNotch Music • Mini Player" : music.currentTrack.artist)
                    .font(.system(size: 11))
                    .foregroundColor(NotchDesign.textSecondary)
                    .lineLimit(1)
                
                // Scrub progress bar
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        let ratio = music.currentTrack.duration > 0 ?
                            min(max(music.currentTrack.position / music.currentTrack.duration, 0.0), 1.0) : 0.25
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 3.5)
                            Capsule()
                                .fill(NotchDesign.accentAmber)
                                .frame(width: geo.size.width * ratio, height: 3.5)
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        Text(formatTime(music.currentTrack.position))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(NotchDesign.textTertiary)
                        Spacer()
                        let remaining = max(music.currentTrack.duration - music.currentTrack.position, 0)
                        Text(remaining > 0 ? "-\(formatTime(remaining))" : "--:--")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(NotchDesign.textTertiary)
                    }
                }
                .padding(.top, 2)
                
                // Playback controls
                HStack(spacing: 18) {
                    Spacer()
                    
                    Button(action: { music.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13))
                            .foregroundColor(NotchDesign.textPrimary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { music.togglePlayPause() }) {
                        Image(systemName: music.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15))
                            .foregroundColor(NotchDesign.textPrimary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { music.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13))
                            .foregroundColor(NotchDesign.textPrimary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            
            // Audio visualizer (Right)
            VStack {
                AudioVisualizerView(isPlaying: music.currentTrack.isPlaying, barColor: NotchDesign.accentAmber)
                    .frame(width: 24)
            }
            .padding(.trailing, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NotchDesign.surfaceDark.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
        .onAppear {
            music.startPolling()
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
