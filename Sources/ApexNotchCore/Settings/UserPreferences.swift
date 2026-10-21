import SwiftUI
import Combine

public enum HubTab: String, CaseIterable, Identifiable, Codable, Sendable {
    case shelf = "Shelf"
    case clipboard = "Clipboard"
    case music = "Music"
    case dashboard = "Dashboard"
    case camera = "Mirror"
    case browser = "Browser"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .shelf: return "folder.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .music: return "music.note"
        case .dashboard: return "square.grid.2x2.fill"
        case .camera: return "camera.fill"
        case .browser: return "globe"
        }
    }
}

public enum MusicPlayerType: String, CaseIterable, Identifiable, Codable, Sendable {
    case auto = "Auto Detect"
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    
    public var id: String { rawValue }
}

public enum SearchEngine: String, CaseIterable, Identifiable, Codable, Sendable {
    case duckDuckGo = "DuckDuckGo"
    case google = "Google"
    case kagi = "Kagi"
    case bing = "Bing"
    
    public var id: String { rawValue }
    
    public func url(for query: String) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        switch self {
        case .duckDuckGo:
            return URL(string: "https://duckduckgo.com/?q=\(encoded)")
        case .google:
            return URL(string: "https://www.google.com/search?q=\(encoded)")
        case .kagi:
            return URL(string: "https://kagi.com/search?q=\(encoded)")
        case .bing:
            return URL(string: "https://www.bing.com/search?q=\(encoded)")
        }
    }
    
    public var homeURL: URL {
        switch self {
        case .duckDuckGo: return URL(string: "https://duckduckgo.com")!
        case .google: return URL(string: "https://www.google.com")!
        case .kagi: return URL(string: "https://kagi.com")!
        case .bing: return URL(string: "https://www.bing.com")!
        }
    }
}

public enum CameraAspectRatio: String, CaseIterable, Identifiable, Codable, Sendable {
    case wide = "16:9"
    case standard = "4:3"
    case square = "1:1"
    
    public var id: String { rawValue }
    
    public var ratio: CGFloat {
        switch self {
        case .wide: return 16.0 / 9.0
        case .standard: return 4.0 / 3.0
        case .square: return 1.0
        }
    }
}

@MainActor
public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()
    
    private let defaults = UserDefaults.standard
    
    // Appearance & Notch
    @Published public var openOnHover: Bool {
        didSet { defaults.set(openOnHover, forKey: "openOnHover") }
    }
    @Published public var hoverOpenDelay: Double {
        didSet { defaults.set(hoverOpenDelay, forKey: "hoverOpenDelay") }
    }
    @Published public var hoverCloseDelay: Double {
        didSet { defaults.set(hoverCloseDelay, forKey: "hoverCloseDelay") }
    }
    @Published public var expandedWidth: Double {
        didSet { defaults.set(expandedWidth, forKey: "expandedWidth") }
    }
    @Published public var expandedHeight: Double {
        didSet { defaults.set(expandedHeight, forKey: "expandedHeight") }
    }
    @Published public var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }
    @Published public var followMouseScreen: Bool {
        didSet { defaults.set(followMouseScreen, forKey: "followMouseScreen") }
    }
    @Published public var hideNotchWhenIdle: Bool {
        didSet { defaults.set(hideNotchWhenIdle, forKey: "hideNotchWhenIdle") }
    }
    @Published public var petCharacter: PetCharacterType {
        didSet { defaults.set(petCharacter.rawValue, forKey: "petCharacter") }
    }
    @Published public var musicVisualizerStyle: MusicVisualizerStyle {
        didSet { defaults.set(musicVisualizerStyle.rawValue, forKey: "musicVisualizerStyle") }
    }
    @Published public var showMusicArtwork: Bool {
        didSet { defaults.set(showMusicArtwork, forKey: "showMusicArtwork") }
    }
    
    // Modules
    @Published public var activeTab: HubTab {
        didSet { defaults.set(activeTab.rawValue, forKey: "activeTab") }
    }
    @Published public var pinExpanded: Bool {
        didSet { defaults.set(pinExpanded, forKey: "pinExpanded") }
    }
    
    // Clipboard
    @Published public var clipboardLimit: Int {
        didSet { defaults.set(clipboardLimit, forKey: "clipboardLimit") }
    }
    @Published public var clipboardDetectSecrets: Bool {
        didSet { defaults.set(clipboardDetectSecrets, forKey: "clipboardDetectSecrets") }
    }
    @Published public var clipboardMemoryOnly: Bool {
        didSet { defaults.set(clipboardMemoryOnly, forKey: "clipboardMemoryOnly") }
    }
    @Published public var clipboardMonitoringPaused: Bool {
        didSet { defaults.set(clipboardMonitoringPaused, forKey: "clipboardMonitoringPaused") }
    }
    
    // Music
    @Published public var musicPreferredPlayer: MusicPlayerType {
        didSet { defaults.set(musicPreferredPlayer.rawValue, forKey: "musicPreferredPlayer") }
    }
    
    // Browser
    @Published public var searchEngine: SearchEngine {
        didSet { defaults.set(searchEngine.rawValue, forKey: "searchEngine") }
    }
    
    // Camera
    @Published public var cameraMirrorHorizontal: Bool {
        didSet { defaults.set(cameraMirrorHorizontal, forKey: "cameraMirrorHorizontal") }
    }
    @Published public var cameraAspectRatio: CameraAspectRatio {
        didSet { defaults.set(cameraAspectRatio.rawValue, forKey: "cameraAspectRatio") }
    }
    
    // Shelf
    @Published public var shelfAutoClearOnDragOut: Bool {
        didSet { defaults.set(shelfAutoClearOnDragOut, forKey: "shelfAutoClearOnDragOut") }
    }
    
    // Pomodoro
    @Published public var pomodoroWorkMinutes: Int {
        didSet { defaults.set(pomodoroWorkMinutes, forKey: "pomodoroWorkMinutes") }
    }
    @Published public var pomodoroBreakMinutes: Int {
        didSet { defaults.set(pomodoroBreakMinutes, forKey: "pomodoroBreakMinutes") }
    }
    
    private init() {
        self.openOnHover = defaults.object(forKey: "openOnHover") as? Bool ?? true
        self.hoverOpenDelay = defaults.object(forKey: "hoverOpenDelay") as? Double ?? 0.12
        self.hoverCloseDelay = defaults.object(forKey: "hoverCloseDelay") as? Double ?? 0.35
        self.expandedWidth = defaults.object(forKey: "expandedWidth") as? Double ?? Double(NotchDesign.expandedWidthDefault)
        self.expandedHeight = defaults.object(forKey: "expandedHeight") as? Double ?? Double(NotchDesign.expandedHeightDefault)
        self.showMenuBarIcon = defaults.object(forKey: "showMenuBarIcon") as? Bool ?? true
        self.followMouseScreen = defaults.object(forKey: "followMouseScreen") as? Bool ?? true
        self.hideNotchWhenIdle = defaults.bool(forKey: "hideNotchWhenIdle")
        
        let petString = defaults.string(forKey: "petCharacter") ?? PetCharacterType.cat.rawValue
        self.petCharacter = PetCharacterType(rawValue: petString) ?? .cat
        
        let vizString = defaults.string(forKey: "musicVisualizerStyle") ?? MusicVisualizerStyle.bars.rawValue
        self.musicVisualizerStyle = MusicVisualizerStyle(rawValue: vizString) ?? .bars
        
        self.showMusicArtwork = defaults.object(forKey: "showMusicArtwork") as? Bool ?? true
        
        let tabString = defaults.string(forKey: "activeTab") ?? HubTab.shelf.rawValue
        self.activeTab = HubTab(rawValue: tabString) ?? .shelf
        self.pinExpanded = defaults.bool(forKey: "pinExpanded")
        
        self.clipboardLimit = defaults.object(forKey: "clipboardLimit") as? Int ?? 50
        self.clipboardDetectSecrets = defaults.object(forKey: "clipboardDetectSecrets") as? Bool ?? true
        self.clipboardMemoryOnly = defaults.object(forKey: "clipboardMemoryOnly") as? Bool ?? false
        self.clipboardMonitoringPaused = defaults.bool(forKey: "clipboardMonitoringPaused")
        
        let playerString = defaults.string(forKey: "musicPreferredPlayer") ?? MusicPlayerType.auto.rawValue
        self.musicPreferredPlayer = MusicPlayerType(rawValue: playerString) ?? .auto
        
        let engineString = defaults.string(forKey: "searchEngine") ?? SearchEngine.duckDuckGo.rawValue
        self.searchEngine = SearchEngine(rawValue: engineString) ?? .duckDuckGo
        
        self.cameraMirrorHorizontal = defaults.object(forKey: "cameraMirrorHorizontal") as? Bool ?? true
        let ratioString = defaults.string(forKey: "cameraAspectRatio") ?? CameraAspectRatio.wide.rawValue
        self.cameraAspectRatio = CameraAspectRatio(rawValue: ratioString) ?? .wide
        
        self.shelfAutoClearOnDragOut = defaults.bool(forKey: "shelfAutoClearOnDragOut")
        self.pomodoroWorkMinutes = defaults.object(forKey: "pomodoroWorkMinutes") as? Int ?? 25
        self.pomodoroBreakMinutes = defaults.object(forKey: "pomodoroBreakMinutes") as? Int ?? 5
    }
    
    public func resetToDefaults() {
        openOnHover = true
        hoverOpenDelay = 0.12
        hoverCloseDelay = 0.35
        expandedWidth = Double(NotchDesign.expandedWidthDefault)
        expandedHeight = Double(NotchDesign.expandedHeightDefault)
        showMenuBarIcon = true
        followMouseScreen = true
        hideNotchWhenIdle = false
        petCharacter = .cat
        musicVisualizerStyle = .bars
        showMusicArtwork = true
        activeTab = .shelf
        pinExpanded = false
        clipboardLimit = 50
        clipboardDetectSecrets = true
        clipboardMemoryOnly = false
        clipboardMonitoringPaused = false
        musicPreferredPlayer = .auto
        searchEngine = .duckDuckGo
        cameraMirrorHorizontal = true
        cameraAspectRatio = .wide
        shelfAutoClearOnDragOut = false
        pomodoroWorkMinutes = 25
        pomodoroBreakMinutes = 5
    }
}
