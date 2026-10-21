import SwiftUI

public struct NotchRootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var prefs: UserPreferences
    @EnvironmentObject private var geometry: DisplayGeometryManager
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            if appState.isExpanded {
                expandedHubView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.94, anchor: .top))
                    ))
            } else {
                NotchCompactView()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = appState.quickMessage {
                toastView(text: toast)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var expandedHubView: some View {
        VStack(spacing: 8) {
            NotchCapsuleHeader()
            
            // Active Tab View
            Group {
                switch appState.activeTab {
                case .shelf:
                    FileShelfView()
                case .clipboard:
                    ClipboardView()
                case .music:
                    MusicPlayerView()
                case .dashboard:
                    DashboardView()
                case .camera:
                    CameraMirrorView()
                case .browser:
                    QuickBrowserView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.top, 10)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.04, green: 0.04, blue: 0.05).opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.6),
                                    Color(red: 0.2, green: 0.8, blue: 0.9).opacity(0.6),
                                    Color(red: 0.7, green: 0.3, blue: 1.0).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 25, x: 0, y: 12)
        )
    }
    
    private func toastView(text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(NotchDesign.accentGreen)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(NotchDesign.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
        )
    }
}
