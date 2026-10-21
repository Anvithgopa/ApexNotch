import SwiftUI
import AppKit

public enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case widgets = "Widgets"
    case fileShelf = "File Shelf"
    case clipboard = "Clipboard"
    case music = "Music"
    case camera = "Camera"
    case permissions = "Permissions"
    case privacy = "Privacy & Storage"
    case diagnostics = "Diagnostics"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .widgets: return "square.grid.2x2.fill"
        case .fileShelf: return "tray.full.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .music: return "music.note"
        case .camera: return "camera.fill"
        case .permissions: return "hand.raised.fill"
        case .privacy: return "lock.shield.fill"
        case .diagnostics: return "stethoscope"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared
    @ObservedObject private var perms = PermissionManager.shared
    @ObservedObject private var widgetRegistry = WidgetRegistry.shared
    @NotchState private var selectedSection: SettingsSection = .general
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.icon)
                        .font(.system(size: 12))
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, maxWidth: 200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    detailView(for: selectedSection)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 720, height: 480)
    }
    
    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            generalSettings
        case .appearance:
            appearanceSettings
        case .widgets:
            widgetSettings
        case .fileShelf:
            shelfSettings
        case .clipboard:
            clipboardSettings
        case .music:
            musicSettings
        case .camera:
            cameraSettings
        case .permissions:
            permissionsSettings
        case .privacy:
            privacySettings
        case .diagnostics:
            diagnosticsSettings
        case .about:
            aboutSettings
        }
    }
    
    // MARK: - General
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("General Settings")
                .font(.title2.bold())
            
            Toggle("Show Menu Bar Status Icon", isOn: $prefs.showMenuBarIcon)
            Toggle("Multi-Monitor: Follow Mouse Pointer Screen", isOn: $prefs.followMouseScreen)
            
            Divider()
            
            Text("Global Keyboard Shortcut")
                .font(.headline)
            Text("Press Option + Space or Command + Option + N to toggle the Notch Hub from any application.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Divider()
            
            Button("Reset All Preferences to Defaults", role: .destructive) {
                prefs.resetToDefaults()
            }
        }
    }
    
    // MARK: - Appearance
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notch & Appearance")
                .font(.title2.bold())
            
            Toggle("Open Notch Hub on Mouse Hover", isOn: $prefs.openOnHover)
            Toggle("Auto-Hide Notch When Not In Use", isOn: $prefs.hideNotchWhenIdle)
            
            Divider()
            
            Text("Notch Companion Pet")
                .font(.headline)
            Text("A fun companion that walks, rests, or sprints based on your Mac's CPU usage and performance!")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Picker("Character", selection: $prefs.petCharacter) {
                ForEach(PetCharacterType.allCases) { pet in
                    Text("\(pet.emoji) \(pet.rawValue)").tag(pet)
                }
            }
            .pickerStyle(.menu)
            
            if prefs.petCharacter != .none {
                HStack(spacing: 12) {
                    NotchPetView()
                        .frame(width: 40, height: 30)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Activity: \(NotchPetManager.shared.currentState.label)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(NotchDesign.accentCyan)
                        Text("Speed dynamically scales with your laptop processor activity.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "Hover Open Delay: %.2f seconds", prefs.hoverOpenDelay))
                    .font(.subheadline)
                Slider(value: $prefs.hoverOpenDelay, in: 0.05...0.6, step: 0.05)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "Hover Close Delay: %.2f seconds", prefs.hoverCloseDelay))
                    .font(.subheadline)
                Slider(value: $prefs.hoverCloseDelay, in: 0.15...1.0, step: 0.05)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "Expanded Hub Width: %.0f pt", prefs.expandedWidth))
                    .font(.subheadline)
                Slider(value: $prefs.expandedWidth, in: 540...860, step: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "Expanded Hub Height: %.0f pt", prefs.expandedHeight))
                    .font(.subheadline)
                Slider(value: $prefs.expandedHeight, in: 360...600, step: 20)
            }
        }
    }
    
    // MARK: - Widgets
    private var widgetSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Widget Management")
                .font(.title2.bold())
            Text("Enable or disable individual productivity widgets in the Dashboard.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(widgetRegistry.widgets) { widget in
                    HStack {
                        Image(systemName: widget.iconName)
                            .frame(width: 20)
                            .foregroundColor(NotchDesign.accentCyan)
                        Text(widget.displayName)
                            .font(.system(size: 12))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { widget.isEnabled },
                            set: { _ in widgetRegistry.toggleWidget(id: widget.id) }
                        ))
                        .labelsHidden()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - File Shelf
    private var shelfSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("File Shelf Preferences")
                .font(.title2.bold())
            
            Toggle("Automatically remove temporary files when dragged out", isOn: $prefs.shelfAutoClearOnDragOut)
            
            Divider()
            
            Text("About Safety & Permissions:")
                .font(.headline)
            Text("ApexNotch NEVER deletes, moves, or alters your original files on disk. The shelf holds secure references so you can easily juggle files between workspaces.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Button("Clear All Shelf Items Now", role: .destructive) {
                FileShelfManager.shared.clearAll()
            }
        }
    }
    
    // MARK: - Clipboard
    private var clipboardSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Clipboard Manager")
                .font(.title2.bold())
            
            Toggle("Detect and Redact Sensitive Information (API keys, Tokens, Secrets)", isOn: $prefs.clipboardDetectSecrets)
            Toggle("Memory-Only Mode (Do not save history to disk)", isOn: $prefs.clipboardMemoryOnly)
            
            Picker("History Retention Limit", selection: $prefs.clipboardLimit) {
                Text("20 items").tag(20)
                Text("50 items").tag(50)
                Text("100 items").tag(100)
                Text("200 items").tag(200)
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Button("Clear Non-Pinned Clipboard History", role: .destructive) {
                ClipboardManager.shared.clearHistory()
            }
        }
    }
    
    // MARK: - Music
    private var musicSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Music Player Integration")
                .font(.title2.bold())
            
            Picker("Preferred Music Source", selection: $prefs.musicPreferredPlayer) {
                ForEach(MusicPlayerType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.radioGroup)
            
            Divider()
            
            Text("Visualizer & Artwork Options")
                .font(.headline)
            
            Picker("Visualizer Animation Style", selection: $prefs.musicVisualizerStyle) {
                ForEach(MusicVisualizerStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.menu)
            
            HStack(spacing: 12) {
                Text("Preview:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                AudioVisualizerView(isPlaying: true, barColor: NotchDesign.accentAmber, style: prefs.musicVisualizerStyle)
                    .frame(width: 32, height: 18)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
            }
            
            Toggle("Show Album Artwork / Music Images in Notch", isOn: $prefs.showMusicArtwork)
            
            Text("Supports native Apple Music and Spotify player control via macOS Apple Events without external network requests.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Camera
    private var cameraSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Camera Mirror")
                .font(.title2.bold())
            
            Toggle("Mirror Preview Horizontally", isOn: $prefs.cameraMirrorHorizontal)
            
            Picker("Aspect Ratio", selection: $prefs.cameraAspectRatio) {
                ForEach(CameraAspectRatio.allCases) { ratio in
                    Text(ratio.rawValue).tag(ratio)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            
            Text("The camera hardware is strictly active ONLY while the mirror tab is in view. It powers down immediately when closed.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Permissions Matrix
    private var permissionsSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("System Permissions")
                .font(.title2.bold())
            Text("ApexNotch adheres strictly to macOS privacy architecture (TCC). Permissions can be granted or revoked at any time in macOS System Settings.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(PermissionKind.allCases) { kind in
                    HStack {
                        Image(systemName: kind.icon)
                            .frame(width: 20)
                            .foregroundColor(NotchDesign.accentCyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                            Text(kind.explanation)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        let status = perms.status(for: kind)
                        Text(status.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(status == .authorized ? NotchDesign.accentGreen : NotchDesign.accentAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                        
                        Button("Manage") {
                            perms.openSettings(for: kind)
                        }
                        .font(.system(size: 10))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Privacy & Storage
    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Privacy & Storage")
                .font(.title2.bold())
            
            Text("All data created by ApexNotch remains strictly 100% local to your Mac. No analytics, tracking, telemetry, or cloud synchronization occurs.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Local Data Directory:")
                .font(.headline)
            Text("~/Library/Application Support/ApexNotch/")
                .font(.system(size: 11, design: .monospaced))
                .padding(6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(4)
            
            Button("Open Application Support in Finder") {
                if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let dir = appSupport.appendingPathComponent("ApexNotch", isDirectory: true)
                    NSWorkspace.shared.activateFileViewerSelecting([dir])
                }
            }
        }
    }
    
    // MARK: - Diagnostics
    private var diagnosticsSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diagnostics & Environment")
                .font(.title2.bold())
            
            let geom = DisplayGeometryManager.shared.currentGeometry
            
            Group {
                Text("• OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
                Text("• Process Architecture: \(ProcessInfo.processInfo.environment["TARGET_CPU"] ?? "arm64 / Native")")
                Text("• Screen Frame: \(Int(geom.screenFrame.width)) × \(Int(geom.screenFrame.height))")
                Text("• Hardware Camera Notch: \(geom.hasPhysicalNotch ? "Detected" : "Standard Display (Virtual Capsule Mode)")")
                if let notchRect = geom.physicalNotchRect {
                    Text("• Notch Dimensions: \(Int(notchRect.width)) × \(Int(notchRect.height)) pt")
                }
                Text("• Active Displays: \(NSScreen.screens.count)")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - About
    private var aboutSettings: some View {
        VStack(spacing: 14) {
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(NotchDesign.accentCyan)
            
            Text("ApexNotch")
                .font(.title.bold())
            
            Text("Native macOS Dynamic Island & Notch Hub")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Version \(ApexNotchMeta.version) • Built with Swift, AppKit & SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("Developed by ")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                +
                Text("Anvith Gopa")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(NotchDesign.accentCyan)
                
                Button(action: {
                    NSWorkspace.shared.open(ApexNotchMeta.githubProfileURL)
                }) {
                    Text("@\(ApexNotchMeta.githubUsername) on GitHub")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(spacing: 10) {
                Button(action: {
                    NSWorkspace.shared.open(ApexNotchMeta.githubRepoURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("View on GitHub (Source Code & Releases)")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 320, height: 32)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSWorkspace.shared.open(ApexNotchMeta.supportMeURL)
                }) {
                    HStack(spacing: 8) {
                        Text("☕")
                        Text("Buy Me a Coffee / Support Development")
                            .bold()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 320, height: 32)
                    .background(Color(red: 1.0, green: 0.86, blue: 0.0))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSWorkspace.shared.open(ApexNotchMeta.issuesURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Report an Issue / Request Features")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Released under the MIT License • 100% Free & Open Source")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

@MainActor
public final class SettingsWindowController: NSObject {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    override private init() {
        super.init()
    }
    
    public func showWindow() {
        if let window = self.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
            .environmentObject(AppState.shared)
            .environmentObject(UserPreferences.shared)
            .environmentObject(DisplayGeometryManager.shared)
        let hostingView = NSHostingView(rootView: settingsView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "ApexNotch Settings"
        newWindow.contentView = hostingView
        newWindow.isReleasedWhenClosed = false
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
