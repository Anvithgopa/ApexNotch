import SwiftUI
import AppKit
import ApexNotchCore

@main
struct ApexNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // App settings window
        Settings {
            SettingsView()
                .environmentObject(AppState.shared)
                .environmentObject(UserPreferences.shared)
                .environmentObject(DisplayGeometryManager.shared)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app with status bar item
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusBarItem()
        NotchWindowController.shared.setup()
        HotkeyManager.shared.setup()
        
        // Start background services with low overhead
        SystemStatsService.shared.startMonitoring()
        NetworkMonitor.shared.startMonitoring()
        ClipboardManager.shared.startMonitoring()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "circle.circle", accessibilityDescription: "ApexNotch")
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle ApexNotch (⌥⌘N)", action: #selector(toggleNotch), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        
        let shelfItem = NSMenuItem(title: "File Shelf", action: #selector(openShelf), keyEquivalent: "1")
        let clipItem = NSMenuItem(title: "Clipboard Manager", action: #selector(openClipboard), keyEquivalent: "2")
        let musicItem = NSMenuItem(title: "Music Player", action: #selector(openMusic), keyEquivalent: "3")
        let dashItem = NSMenuItem(title: "Dashboard", action: #selector(openDashboard), keyEquivalent: "4")
        let camItem = NSMenuItem(title: "Camera Mirror", action: #selector(openCamera), keyEquivalent: "5")
        let browserItem = NSMenuItem(title: "Quick Browser", action: #selector(openBrowser), keyEquivalent: "6")
        
        menu.addItem(shelfItem)
        menu.addItem(clipItem)
        menu.addItem(musicItem)
        menu.addItem(dashItem)
        menu.addItem(camItem)
        menu.addItem(browserItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick tools
        let pickerItem = NSMenuItem(title: "Eyedropper Color Picker", action: #selector(pickColor), keyEquivalent: "c")
        let ocrItem = NSMenuItem(title: "Extract Text from Screen (OCR)", action: #selector(extractOCR), keyEquivalent: "o")
        menu.addItem(pickerItem)
        menu.addItem(ocrItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit ApexNotch", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleNotch() {
        AppState.shared.toggleExpanded()
    }
    
    @objc private func openShelf() {
        AppState.shared.open(tab: .shelf)
    }
    
    @objc private func openClipboard() {
        AppState.shared.open(tab: .clipboard)
    }
    
    @objc private func openMusic() {
        AppState.shared.open(tab: .music)
    }
    
    @objc private func openDashboard() {
        AppState.shared.open(tab: .dashboard)
    }
    
    @objc private func openCamera() {
        AppState.shared.open(tab: .camera)
    }
    
    @objc private func openBrowser() {
        AppState.shared.open(tab: .browser)
    }
    
    @objc private func pickColor() {
        ColorPickerService.shared.pickColor()
    }
    
    @objc private func extractOCR() {
        ScreenOCRService.shared.captureAndExtractText()
    }
    
    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
