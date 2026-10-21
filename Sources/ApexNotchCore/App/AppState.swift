import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isExpanded: Bool = false
    @Published public var isHovering: Bool = false
    @Published public var activeTab: HubTab = .shelf
    @Published public var isPinned: Bool = false
    @Published public var quickMessage: String? = nil
    
    // Quick status badges for compact notch
    @Published public var compactBadgeText: String? = nil
    @Published public var compactBadgeColor: Color = NotchDesign.accentCyan
    @Published public var isMediaPlaying: Bool = false
    @Published public var currentMediaTitle: String? = nil
    
    private var messageTimer: Timer?
    
    private init() {
        self.activeTab = UserPreferences.shared.activeTab
    }
    
    public func toggleExpanded() {
        setExpanded(!isExpanded)
    }
    
    public func setExpanded(_ expanded: Bool) {
        withAnimation(expanded ? NotchDesign.expansionSpring : NotchDesign.collapseSpring) {
            self.isExpanded = expanded
        }
    }
    
    public func open(tab: HubTab) {
        self.activeTab = tab
        UserPreferences.shared.activeTab = tab
        setExpanded(true)
    }
    
    public func collapse() {
        if !isPinned {
            setExpanded(false)
        }
    }
    
    public func showToast(_ text: String, duration: TimeInterval = 2.5) {
        quickMessage = text
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.quickMessage = nil
                }
            }
        }
    }
}
