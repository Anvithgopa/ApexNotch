import AppKit
import SwiftUI
import Combine

@MainActor
public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()
    
    public private(set) var panel: NotchPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var openTimer: Timer?
    private var closeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private var isMouseInsideCurrentFrame = false
    private var isDragging = false
    
    override private init() {
        super.init()
    }
    
    public func setup() {
        let geometry = DisplayGeometryManager.shared.currentGeometry
        let initialFrame = geometry.compactFrame
        
        let newPanel = NotchPanel(contentRect: initialFrame)
        self.panel = newPanel
        
        let rootView = NotchRootView()
            .environmentObject(AppState.shared)
            .environmentObject(UserPreferences.shared)
            .environmentObject(DisplayGeometryManager.shared)
        
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = NSRect(origin: .zero, size: initialFrame.size)
        
        newPanel.contentView = hostingView
        newPanel.orderFrontRegardless()
        
        setupSubscriptions()
        setupMouseMonitoring()
    }
    
    private func setupSubscriptions() {
        // Observe AppState isExpanded
        AppState.shared.$isExpanded
            .removeDuplicates()
            .sink { [weak self] expanded in
                self?.handleExpansionChange(expanded)
            }
            .store(in: &cancellables)
            
        // Observe DisplayGeometry changes
        DisplayGeometryManager.shared.$currentGeometry
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState()
            }
            .store(in: &cancellables)
            
        // Observe preference changes for dimensions
        UserPreferences.shared.$expandedWidth
            .combineLatest(UserPreferences.shared.$expandedHeight)
            .sink { [weak self] width, height in
                DisplayGeometryManager.shared.recalculate(expandedWidth: width, expandedHeight: height)
                self?.updateFrameForCurrentState()
            }
            .store(in: &cancellables)
            
        // Observe idle state changes for auto-hide
        UserPreferences.shared.$hideNotchWhenIdle
            .combineLatest(MusicPlayerManager.shared.$currentTrack, FileShelfManager.shared.$items)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateIdleVisibility(isNearNotch: self?.isMouseInsideCurrentFrame ?? false)
            }
            .store(in: &cancellables)
    }
    
    private func setupMouseMonitoring() {
        let eventMask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .leftMouseUp,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ]
        
        // Global mouse movement and drag monitor across all applications
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseEvent(event)
            }
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseEvent(event)
            }
            return event
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        guard let panel = self.panel else { return }
        let prefs = UserPreferences.shared
        let appState = AppState.shared
        let screenPoint = NSEvent.mouseLocation
        
        // Track whether user is actively dragging something
        if event.type == .leftMouseDragged || event.type == .rightMouseDragged || event.type == .otherMouseDragged {
            self.isDragging = true
        } else if event.type == .leftMouseUp || event.type == .rightMouseUp || event.type == .otherMouseUp {
            self.isDragging = false
        }
        
        if prefs.followMouseScreen && !appState.isExpanded {
            DisplayGeometryManager.shared.updateActiveScreen(at: screenPoint, expandedWidth: prefs.expandedWidth, expandedHeight: prefs.expandedHeight)
        }
        
        let geometry = DisplayGeometryManager.shared.currentGeometry
        let compactRect = geometry.compactFrame
        let screen = geometry.screenFrame
        
        // Generous trigger zone for drag operations vs normal hover
        // When dragging a file, give a large top-screen landing area so the notch welcomes the drop without hiding!
        let triggerMarginX: CGFloat = isDragging ? -50.0 : -10.0
        let triggerMarginY: CGFloat = isDragging ? -30.0 : -4.0
        let triggerRect = compactRect.insetBy(dx: triggerMarginX, dy: triggerMarginY)
        
        // Check if mouse is near top-center screen during a drag
        let isTopCenterScreen = screenPoint.y >= (screen.maxY - 70.0) && abs(screenPoint.x - screen.midX) < (compactRect.width / 2.0 + 80.0)
        let isNearNotch = NSPointInRect(screenPoint, triggerRect) || (isDragging && isTopCenterScreen)
        self.isMouseInsideCurrentFrame = isNearNotch
        
        // When dragging a file towards the notch:
        if isDragging {
            // Cancel close timer so the notch never closes or hides during drag!
            closeTimer?.invalidate()
            closeTimer = nil
            
            if isNearNotch {
                panel.animator().alphaValue = 1.0
                
                // If dragging near compact notch, auto-expand to File Shelf after a brief delay
                if !appState.isExpanded && openTimer == nil {
                    openTimer = Timer.scheduledTimer(withTimeInterval: 0.20, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            AppState.shared.open(tab: .shelf)
                        }
                    }
                }
                return
            }
            
            // If already expanded, keep it open while dragging
            if appState.isExpanded {
                panel.animator().alphaValue = 1.0
                return
            }
        }
        
        updateIdleVisibility(isNearNotch: isNearNotch)
        
        // Normal Compact hover handling (when not dragging)
        if isNearNotch && !appState.isExpanded {
            closeTimer?.invalidate()
            closeTimer = nil
            
            if prefs.openOnHover && openTimer == nil {
                openTimer = Timer.scheduledTimer(withTimeInterval: prefs.hoverOpenDelay, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        AppState.shared.setExpanded(true)
                    }
                }
            }
        } else if !isNearNotch && !appState.isExpanded && !isDragging {
            openTimer?.invalidate()
            openTimer = nil
        }
        
        // Normal Expanded hover handling (when not dragging)
        if appState.isExpanded {
            openTimer?.invalidate()
            openTimer = nil
            
            let expandedHitArea = panel.frame.insetBy(dx: -16, dy: -16)
            if !NSPointInRect(screenPoint, expandedHitArea) {
                if !appState.isPinned && !isDragging && closeTimer == nil {
                    closeTimer = Timer.scheduledTimer(withTimeInterval: prefs.hoverCloseDelay, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            AppState.shared.collapse()
                        }
                    }
                }
            } else {
                closeTimer?.invalidate()
                closeTimer = nil
            }
        }
    }
    
    private func handleExpansionChange(_ expanded: Bool) {
        openTimer?.invalidate()
        openTimer = nil
        closeTimer?.invalidate()
        closeTimer = nil
        
        guard let panel = self.panel else { return }
        let geometry = DisplayGeometryManager.shared.currentGeometry
        let targetFrame = expanded ? geometry.expandedFrame : geometry.compactFrame
        
        if expanded {
            panel.alphaValue = 1.0
        }
        
        // Smoothly animate frame
        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.35 : 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        }
        panel.orderFrontRegardless()
    }
    
    public func updateFrameForCurrentState() {
        guard let panel = self.panel else { return }
        let geometry = DisplayGeometryManager.shared.currentGeometry
        let targetFrame = AppState.shared.isExpanded ? geometry.expandedFrame : geometry.compactFrame
        panel.setFrame(targetFrame, display: true)
    }
    
    public func updateIdleVisibility(isNearNotch: Bool) {
        guard let panel = self.panel else { return }
        let prefs = UserPreferences.shared
        let appState = AppState.shared
        let isMusicPlaying = MusicPlayerManager.shared.currentTrack.isPlaying
        let hasShelfFiles = !FileShelfManager.shared.items.isEmpty
        
        // Never hide while dragging files, or while expanded, or while hovering, or while music is playing
        let shouldHide = prefs.hideNotchWhenIdle && !appState.isExpanded && !isNearNotch && !isMusicPlaying && !hasShelfFiles && !isDragging
        let targetAlpha: CGFloat = shouldHide ? 0.0 : 1.0
        
        if abs(panel.alphaValue - targetAlpha) > 0.01 {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = targetAlpha
            }
        }
    }
    
    public func teardown() {
        if let g = globalMouseMonitor { NSEvent.removeMonitor(g); globalMouseMonitor = nil }
        if let l = localMouseMonitor { NSEvent.removeMonitor(l); localMouseMonitor = nil }
    }
}
