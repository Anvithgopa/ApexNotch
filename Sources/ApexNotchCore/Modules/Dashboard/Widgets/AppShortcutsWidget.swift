import SwiftUI
import AppKit

public struct AppShortcutItem: Identifiable {
    public let id: String
    public let name: String
    public let bundleURL: URL
    public let icon: NSImage
}

@MainActor
public final class AppShortcutsManager: ObservableObject {
    public static let shared = AppShortcutsManager()
    
    @Published public private(set) var commonApps: [AppShortcutItem] = []
    
    private init() {
        loadCommonApps()
    }
    
    public func loadCommonApps() {
        let appNames = ["Finder", "Safari", "Terminal", "System Settings", "Notes", "Calendar"]
        var items: [AppShortcutItem] = []
        
        for name in appNames {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId(for: name)) ??
               findAppInSystem(named: name) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                items.append(AppShortcutItem(id: name, name: name, bundleURL: appURL, icon: icon))
            }
        }
        self.commonApps = items
    }
    
    private func bundleId(for name: String) -> String {
        switch name {
        case "Finder": return "com.apple.finder"
        case "Safari": return "com.apple.Safari"
        case "Terminal": return "com.apple.Terminal"
        case "System Settings": return "com.apple.systempreferences"
        case "Notes": return "com.apple.Notes"
        case "Calendar": return "com.apple.iCal"
        default: return ""
        }
    }
    
    private func findAppInSystem(named: String) -> URL? {
        let standardPath = "/System/Applications/\(named).app"
        if FileManager.default.fileExists(atPath: standardPath) {
            return URL(fileURLWithPath: standardPath)
        }
        let appsPath = "/Applications/\(named).app"
        if FileManager.default.fileExists(atPath: appsPath) {
            return URL(fileURLWithPath: appsPath)
        }
        return nil
    }
    
    public func launch(app: AppShortcutItem) {
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: app.bundleURL, configuration: config, completionHandler: nil)
    }
}

public struct AppShortcutsWidget: View {
    @ObservedObject private var manager = AppShortcutsManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("App Shortcuts", systemImage: "macwindow.on.rectangle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(NotchDesign.accentPurple)
            
            HStack(spacing: 10) {
                ForEach(manager.commonApps.prefix(5)) { app in
                    Button(action: { manager.launch(app: app) }) {
                        VStack(spacing: 3) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                            Text(app.name)
                                .font(.system(size: 9))
                                .foregroundColor(NotchDesign.textSecondary)
                                .lineLimit(1)
                                .frame(width: 44)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Launch \(app.name)")
                }
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
    }
}
