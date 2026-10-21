import SwiftUI

public struct NotchCapsuleHeader: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var prefs: UserPreferences
    @EnvironmentObject private var geometry: DisplayGeometryManager
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header Top Bar: Brand, Quick Tools & Window Actions
            HStack(spacing: 8) {
                // Left: Brand & Active Tab Indicator
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(NotchDesign.accentCyan)
                    
                    Text("ApexNotch")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(NotchDesign.textPrimary)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(NotchDesign.textTertiary)
                    
                    Text(appState.activeTab.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NotchDesign.accentCyan)
                }
                
                Spacer()
                
                // Right: Quick Utility Tools & Window Controls
                HStack(spacing: 6) {
                    // Quick Eyedropper Tool
                    Button(action: {
                        ColorPickerService.shared.pickColor()
                    }) {
                        Image(systemName: "eyedropper.halffull")
                            .font(.system(size: 11))
                            .foregroundColor(NotchDesign.accentCyan)
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Color Picker (Eyedropper)")
                    
                    // Quick OCR Text Extractor
                    Button(action: {
                        ScreenOCRService.shared.captureAndExtractText()
                    }) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 11))
                            .foregroundColor(NotchDesign.accentGreen)
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Extract Text from Screen (OCR)")
                    
                    // Pin open toggle
                    Button(action: {
                        appState.isPinned.toggle()
                        prefs.pinExpanded = appState.isPinned
                        appState.showToast(appState.isPinned ? "Notch Hub pinned open" : "Notch Hub unpinned")
                    }) {
                        Image(systemName: appState.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                            .foregroundColor(appState.isPinned ? NotchDesign.accentAmber : NotchDesign.textSecondary)
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help(appState.isPinned ? "Unpin Notch" : "Pin Notch Open")
                    
                    // Settings button
                    Button(action: {
                        SettingsWindowController.shared.showWindow()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11))
                            .foregroundColor(NotchDesign.textSecondary)
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Open Settings")
                    
                    // Collapse button
                    Button(action: {
                        appState.setExpanded(false)
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(NotchDesign.textSecondary)
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Notch")
                }
            }
            .padding(.horizontal, 6)
            
            // Sub-Notch Navigation Bar
            HStack(spacing: 4) {
                ForEach(HubTab.allCases) { tab in
                    Button(action: {
                        withAnimation(NotchDesign.tabSpring) {
                            appState.open(tab: tab)
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10, weight: appState.activeTab == tab ? .bold : .medium))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: appState.activeTab == tab ? .semibold : .regular))
                        }
                        .foregroundColor(appState.activeTab == tab ? NotchDesign.textPrimary : NotchDesign.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            appState.activeTab == tab ?
                            Capsule().fill(Color.white.opacity(0.20)) :
                            Capsule().fill(Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        }
    }
}
