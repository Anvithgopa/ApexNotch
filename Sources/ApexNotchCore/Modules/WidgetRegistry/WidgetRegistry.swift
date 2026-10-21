import SwiftUI

public protocol NotchWidget: Identifiable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }
    var category: WidgetCategory { get }
    var defaultEnabled: Bool { get }
}

public enum WidgetCategory: String, CaseIterable, Codable {
    case productivity = "Productivity"
    case system = "System & Hardware"
    case utility = "Utilities"
}

public struct WidgetDescriptor: NotchWidget, Codable, Equatable {
    public let id: String
    public let displayName: String
    public let iconName: String
    public let category: WidgetCategory
    public let defaultEnabled: Bool
    public var isEnabled: Bool
}

@MainActor
public final class WidgetRegistry: ObservableObject {
    public static let shared = WidgetRegistry()
    
    @Published public var widgets: [WidgetDescriptor] = [] {
        didSet { save() }
    }
    
    private let storageURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ApexNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("widgets_config.json")
        load()
    }
    
    private var defaultWidgets: [WidgetDescriptor] {
        [
            WidgetDescriptor(id: "clock", displayName: "Clock & World Times", iconName: "clock.fill", category: .utility, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "system", displayName: "CPU & Memory Gauges", iconName: "cpu", category: .system, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "network", displayName: "Network Traffic Sparkline", iconName: "network", category: .system, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "calendar", displayName: "Calendar & Reminders", iconName: "calendar", category: .productivity, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "notes", displayName: "Quick Scratchpad", iconName: "note.text", category: .productivity, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "pomodoro", displayName: "Pomodoro Focus Timer", iconName: "brain.head.profile", category: .productivity, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "stopwatch", displayName: "Precision Stopwatch", iconName: "stopwatch.fill", category: .productivity, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "hydration", displayName: "Hydration & Habit Counter", iconName: "drop.fill", category: .productivity, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "bookmarks", displayName: "Quick Bookmarks", iconName: "bookmark.fill", category: .utility, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "apps", displayName: "App Switcher Shortcuts", iconName: "macwindow.on.rectangle", category: .utility, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "countdown", displayName: "Milestone Countdown", iconName: "hourglass", category: .utility, defaultEnabled: true, isEnabled: true),
            WidgetDescriptor(id: "calculator", displayName: "Quick Calc & Converter", iconName: "function", category: .utility, defaultEnabled: true, isEnabled: true)
        ]
    }
    
    public func toggleWidget(id: String) {
        if let index = widgets.firstIndex(where: { $0.id == id }) {
            widgets[index].isEnabled.toggle()
        }
    }
    
    public func isWidgetEnabled(_ id: String) -> Bool {
        widgets.first(where: { $0.id == id })?.isEnabled ?? true
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(widgets) {
            try? data.write(to: storageURL)
        }
    }
    
    private func load() {
        if let data = try? Data(contentsOf: storageURL),
           let loaded = try? JSONDecoder().decode([WidgetDescriptor].self, from: data) {
            self.widgets = loaded
        } else {
            self.widgets = defaultWidgets
        }
    }
}
