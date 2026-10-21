import AppKit
import SwiftUI

@MainActor
public final class ColorPickerService: ObservableObject {
    public static let shared = ColorPickerService()
    
    @Published public private(set) var lastPickedHex: String = ""
    @Published public private(set) var lastPickedColor: NSColor?
    
    private init() {}
    
    public func pickColor() {
        Task { @MainActor in
            let sampler = NSColorSampler()
            guard let color = await sampler.sample() else { return }
            guard let rgbColor = color.usingColorSpace(.sRGB) else { return }
            
            let r = Int(round(rgbColor.redComponent * 255))
            let g = Int(round(rgbColor.greenComponent * 255))
            let b = Int(round(rgbColor.blueComponent * 255))
            
            let hex = String(format: "#%02X%02X%02X", r, g, b)
            self.lastPickedHex = hex
            self.lastPickedColor = rgbColor
            
            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(hex, forType: .string)
            
            AppState.shared.showToast("Copied \(hex) to clipboard")
        }
    }
}
