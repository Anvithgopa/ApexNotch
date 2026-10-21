import AppKit
import Combine

public struct NotchGeometry: Equatable, Sendable {
    public let screenFrame: NSRect
    public let hasPhysicalNotch: Bool
    public let physicalNotchRect: NSRect?
    public let compactFrame: NSRect
    public let expandedFrame: NSRect
    
    public init(
        screenFrame: NSRect,
        hasPhysicalNotch: Bool,
        physicalNotchRect: NSRect?,
        compactFrame: NSRect,
        expandedFrame: NSRect
    ) {
        self.screenFrame = screenFrame
        self.hasPhysicalNotch = hasPhysicalNotch
        self.physicalNotchRect = physicalNotchRect
        self.compactFrame = compactFrame
        self.expandedFrame = expandedFrame
    }
}

@MainActor
public final class DisplayGeometryManager: ObservableObject {
    public static let shared = DisplayGeometryManager()
    
    @Published public private(set) var currentGeometry: NotchGeometry
    @Published public private(set) var currentScreen: NSScreen
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let initialScreen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        self.currentScreen = initialScreen
        self.currentGeometry = DisplayGeometryManager.calculateGeometry(for: initialScreen, expandedWidth: NotchDesign.expandedWidthDefault, expandedHeight: NotchDesign.expandedHeightDefault)
        
        setupScreenNotifications()
    }
    
    private func setupScreenNotifications() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculate()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification, object: NSWorkspace.shared)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculate()
            }
            .store(in: &cancellables)
    }
    
    public func updateActiveScreen(at point: NSPoint? = nil, expandedWidth: CGFloat, expandedHeight: CGFloat) {
        let targetScreen: NSScreen
        if let point = point {
            targetScreen = NSScreen.screens.first(where: { NSPointInRect(point, $0.frame) }) ?? currentScreen
        } else if let mouseLocation = Optional(NSEvent.mouseLocation) {
            targetScreen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) ?? NSScreen.main ?? currentScreen
        } else {
            targetScreen = NSScreen.main ?? currentScreen
        }
        
        self.currentScreen = targetScreen
        self.currentGeometry = DisplayGeometryManager.calculateGeometry(for: targetScreen, expandedWidth: expandedWidth, expandedHeight: expandedHeight)
    }
    
    public func recalculate(expandedWidth: CGFloat = NotchDesign.expandedWidthDefault, expandedHeight: CGFloat = NotchDesign.expandedHeightDefault) {
        let targetScreen = NSScreen.main ?? currentScreen
        self.currentScreen = targetScreen
        self.currentGeometry = DisplayGeometryManager.calculateGeometry(for: targetScreen, expandedWidth: expandedWidth, expandedHeight: expandedHeight)
    }
    
    public static func calculateGeometry(for screen: NSScreen, expandedWidth: CGFloat, expandedHeight: CGFloat) -> NotchGeometry {
        let frame = screen.frame
        let insets = screen.safeAreaInsets
        
        // Detect physical notch via safeAreaInsets and auxiliary areas
        let hasNotch = insets.top > 0
        var notchCenterX: CGFloat = frame.midX
        let notchTopY: CGFloat = frame.maxY
        let notchHeight: CGFloat = max(insets.top, 32.0)
        var physicalNotchWidth: CGFloat = 179.0
        var physicalNotchRect: NSRect? = nil
        
        if hasNotch {
            if let leftArea = screen.auxiliaryTopLeftArea,
               let rightArea = screen.auxiliaryTopRightArea {
                let notchX = leftArea.maxX
                let notchW = rightArea.minX - leftArea.maxX
                if notchW > 0 {
                    physicalNotchWidth = notchW
                    notchCenterX = notchX + (notchW / 2.0)
                    physicalNotchRect = NSRect(x: notchX, y: frame.maxY - notchHeight, width: notchW, height: notchHeight)
                }
            }
        }
        
        if physicalNotchRect == nil && hasNotch {
            physicalNotchRect = NSRect(
                x: notchCenterX - (physicalNotchWidth / 2.0),
                y: frame.maxY - notchHeight,
                width: physicalNotchWidth,
                height: notchHeight
            )
        }
        
        // Compact capsule dimensions anchored directly to top screen bezel / notch
        // Dynamic Island wings flanking the physical notch for quick glanceable status
        let compactWidth: CGFloat = hasNotch ? max(physicalNotchWidth + 76.0, 255.0) : 180.0
        let compactHeight: CGFloat = hasNotch ? max(notchHeight + 4.0, 36.0) : 32.0
        
        let compactFrame = NSRect(
            x: notchCenterX - (compactWidth / 2.0),
            y: notchTopY - compactHeight,
            width: compactWidth,
            height: compactHeight
        )
        
        let validExpandedWidth = min(expandedWidth, frame.width - 40.0)
        let validExpandedHeight = min(expandedHeight, frame.height - 80.0)
        
        // Expanded Hub is anchored cleanly beneath the notch / menu bar
        // This guarantees it NEVER overlaps or obstructs macOS menu bar status items or system controls
        let topClearance: CGFloat = hasNotch ? notchHeight : max(frame.maxY - screen.visibleFrame.maxY, 24.0)
        let expandedTopY = notchTopY - topClearance
        
        let expandedFrame = NSRect(
            x: notchCenterX - (validExpandedWidth / 2.0),
            y: expandedTopY - validExpandedHeight,
            width: validExpandedWidth,
            height: validExpandedHeight
        )
        
        return NotchGeometry(
            screenFrame: frame,
            hasPhysicalNotch: hasNotch,
            physicalNotchRect: physicalNotchRect,
            compactFrame: compactFrame,
            expandedFrame: expandedFrame
        )
    }
}
