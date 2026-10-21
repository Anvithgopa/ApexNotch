import Foundation
import AppKit
import ApexNotchCore

@MainActor
struct TestRunner {
    static var passedCount = 0
    static var failedCount = 0
    
    static func assertTest(_ condition: Bool, _ testName: String) {
        if condition {
            passedCount += 1
            print("  ✅ [PASS] \(testName)")
        } else {
            failedCount += 1
            print("  ❌ [FAIL] \(testName)")
        }
    }
    
    static func runAllTests() {
        print("========================================")
        print("  ApexNotch Automated Test Suite")
        print("========================================\n")
        
        testGeometryCalculations()
        testClipboardSecretDetection()
        testFileShelfFormatting()
        testNetworkSpeedFormatting()
        testPomodoroStateProgression()
        testWidgetRegistry()
        testSearchEngineURLs()
        testUserPreferences()
        testNotchPetCharacters()
        testMusicVisualizerStyles()
        testAmbientSounds()
        
        print("\n========================================")
        print("  Test Results: \(passedCount) Passed, \(failedCount) Failed")
        print("========================================")
        
        if failedCount > 0 {
            exit(1)
        }
    }
    
    static func testGeometryCalculations() {
        print("• Running Geometry Tests...")
        let screen = NSScreen.main ?? NSScreen()
        let geometry = DisplayGeometryManager.calculateGeometry(
            for: screen,
            expandedWidth: 680,
            expandedHeight: 440
        )
        
        assertTest(geometry.screenFrame.width > 0, "Screen width must be positive")
        assertTest(geometry.screenFrame.height > 0, "Screen height must be positive")
        assertTest(geometry.expandedFrame.width == 680, "Expanded width matches requested width")
        assertTest(geometry.expandedFrame.height == 440, "Expanded height matches requested height")
        assertTest(geometry.compactFrame.height >= 32.0, "Compact capsule height >= 32 pt")
        assertTest(geometry.compactFrame.width >= 160.0, "Compact capsule width >= 160 pt")
    }
    
    static func testClipboardSecretDetection() {
        print("\n• Running Clipboard Secret Detection Tests...")
        let manager = ClipboardManager.shared
        
        let ghToken = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"
        let (isGHSecret, ghDesc) = manager.detectSecret(in: ghToken)
        assertTest(isGHSecret && ghDesc == "GitHub Token", "GitHub Token detected and tagged")
        
        let openAIKey = "sk-abcdef1234567890abcdef123456789012"
        let (isOpenAI, openAIDesc) = manager.detectSecret(in: openAIKey)
        assertTest(isOpenAI && openAIDesc == "OpenAI API Key", "OpenAI Key detected and tagged")
        
        let awsKey = "AKIA1234567890ABCDEF"
        let (isAWS, awsDesc) = manager.detectSecret(in: awsKey)
        assertTest(isAWS && awsDesc == "AWS Access Key", "AWS Access Key detected and tagged")
        
        let rsaKey = "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0\n-----END RSA PRIVATE KEY-----"
        let (isRSA, rsaDesc) = manager.detectSecret(in: rsaKey)
        assertTest(isRSA && rsaDesc == "Private Encryption Key", "Private Encryption Key detected and tagged")
        
        let normalText = "https://developer.apple.com/documentation/appkit"
        let (isNormal, normalDesc) = manager.detectSecret(in: normalText)
        assertTest(!isNormal && normalDesc == nil, "Standard URL not flagged as secret")
    }
    
    static func testFileShelfFormatting() {
        print("\n• Running File Shelf Formatting Tests...")
        assertTest(FileItem.formatBytes(512) == "512 bytes", "512 bytes formatted properly")
        assertTest(FileItem.formatBytes(1000) == "1 KB" || FileItem.formatBytes(1024) == "1 KB", "Kilobytes formatted properly")
        assertTest(FileItem.formatBytes(1_000_000) == "1 MB" || FileItem.formatBytes(1_048_576) == "1 MB", "1 MB formatted properly")
        assertTest(FileItem.formatBytes(1_000_000_000) == "1 GB" || FileItem.formatBytes(1_073_741_824) == "1.07 GB", "Gigabytes formatted properly")
    }
    
    static func testNetworkSpeedFormatting() {
        print("\n• Running Network Speed Tests...")
        assertTest(NetworkMonitor.formatSpeed(500) == "500 B/s", "Bytes per second formatted")
        assertTest(NetworkMonitor.formatSpeed(2048) == "2.0 KB/s", "Kilobytes per second formatted")
        assertTest(NetworkMonitor.formatSpeed(5_242_880) == "5.0 MB/s", "Megabytes per second formatted")
    }
    
    static func testPomodoroStateProgression() {
        print("\n• Running Pomodoro Progression Tests...")
        let pomodoro = PomodoroManager.shared
        pomodoro.reset()
        
        assertTest(pomodoro.currentState == .work, "Initial state is Deep Focus work")
        assertTest(!pomodoro.isRunning, "Initial timer is paused")
        assertTest(pomodoro.secondsRemaining == UserPreferences.shared.pomodoroWorkMinutes * 60, "Seconds remaining matches preferences")
        assertTest(pomodoro.progress == 0.0, "Initial progress is 0.0")
        
        pomodoro.start()
        assertTest(pomodoro.isRunning, "Timer is running after start()")
        
        pomodoro.pause()
        assertTest(!pomodoro.isRunning, "Timer is paused after pause()")
        
        pomodoro.reset()
        assertTest(pomodoro.secondsRemaining == UserPreferences.shared.pomodoroWorkMinutes * 60, "Timer resets properly")
    }
    
    static func testWidgetRegistry() {
        print("\n• Running Widget Registry Tests...")
        let registry = WidgetRegistry.shared
        assertTest(!registry.widgets.isEmpty, "Widget registry contains registered widgets")
        assertTest(registry.widgets.count >= 10, "Widget registry has at least 10 widgets")
        
        let initialClockState = registry.isWidgetEnabled("clock")
        registry.toggleWidget(id: "clock")
        assertTest(registry.isWidgetEnabled("clock") != initialClockState, "Widget toggles state")
        
        registry.toggleWidget(id: "clock")
        assertTest(registry.isWidgetEnabled("clock") == initialClockState, "Widget restores original state")
    }
    
    static func testSearchEngineURLs() {
        print("\n• Running Search Engine URL Tests...")
        let ddg = SearchEngine.duckDuckGo
        let ddgURL = ddg.url(for: "macOS notch utility")
        assertTest(ddgURL != nil && ddgURL!.absoluteString.contains("duckduckgo.com"), "DuckDuckGo search URL generated")
        
        let google = SearchEngine.google
        let gURL = google.url(for: "macOS notch utility")
        assertTest(gURL != nil && gURL!.absoluteString.contains("google.com"), "Google search URL generated")
    }
    
    static func testUserPreferences() {
        print("\n• Running User Preferences Tests...")
        let prefs = UserPreferences.shared
        assertTest(prefs.expandedWidth >= 500, "Expanded width within safe bounds")
        assertTest(prefs.expandedHeight >= 300, "Expanded height within safe bounds")
        assertTest(prefs.hoverOpenDelay > 0, "Hover open delay is positive")
        assertTest(prefs.hoverCloseDelay > 0, "Hover close delay is positive")
    }
    
    static func testNotchPetCharacters() {
        print("\n• Running Notch Pet Character Tests...")
        let pets = PetCharacterType.allCases
        assertTest(pets.count >= 6, "At least 6 pet characters defined")
        assertTest(PetCharacterType.cat.emoji == "🐱", "Cat character has cat emoji")
        assertTest(PetCharacterType.dog.emoji == "🐶", "Dog character has dog emoji")
        assertTest(PetCharacterType.fox.emoji == "🦊", "Fox character has fox emoji")
        assertTest(PetCharacterType.robot.emoji == "🤖", "Robot character has robot emoji")
        
        let petManager = NotchPetManager.shared
        assertTest(petManager.speedFactor > 0, "Pet speed factor is positive")
    }
    
    static func testMusicVisualizerStyles() {
        print("\n• Running Music Visualizer Style Tests...")
        let styles = MusicVisualizerStyle.allCases
        assertTest(styles.count >= 4, "At least 4 visualizer styles available")
        assertTest(styles.contains(.bars), "Contains Equalizer Bars style")
        assertTest(styles.contains(.wave), "Contains Sound Wave style")
        assertTest(styles.contains(.dots), "Contains Spectrum Dots style")
        assertTest(styles.contains(.pulse), "Contains Radial Pulse style")
    }
    
    static func testAmbientSounds() {
        print("\n• Running Ambient Sound Tests...")
        let sounds = AmbientSoundType.allCases
        assertTest(sounds.count >= 4, "At least 4 ambient sounds available")
        assertTest(sounds.contains(.rain), "Contains Rain sound")
        assertTest(sounds.contains(.ocean), "Contains Ocean sound")
        assertTest(sounds.contains(.whiteNoise), "Contains White Noise sound")
    }
}

// Entry point
TestRunner.runAllTests()
