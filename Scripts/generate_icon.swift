import AppKit
import CoreGraphics

func generateAppIcon() {
    let sizes = [16, 32, 64, 128, 256, 512, 1024]
    let iconsetDir = "Resources/AppIcon.iconset"
    try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    
    for size in sizes {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            continue
        }
        
        let s = CGFloat(size)
        let rect = CGRect(x: 0, y: 0, width: s, height: s)
        
        // Dark background squircle
        let cornerRadius = s * 0.2237
        let bgPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.04, dy: s * 0.04), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx.addPath(bgPath)
        ctx.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0))
        ctx.fillPath()
        
        // Subtle outer border
        ctx.addPath(bgPath)
        ctx.setStrokeColor(CGColor(red: 0.25, green: 0.75, blue: 0.95, alpha: 0.4))
        ctx.setLineWidth(max(1, s * 0.015))
        ctx.strokePath()
        
        // Glowing Notch Pill at top center
        let pillWidth = s * 0.52
        let pillHeight = s * 0.16
        let pillRect = CGRect(x: (s - pillWidth) / 2.0, y: s * 0.65, width: pillWidth, height: pillHeight)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillHeight / 2.0, cornerHeight: pillHeight / 2.0, transform: nil)
        
        // Glow shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.06, color: CGColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.6))
        ctx.addPath(pillPath)
        ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1.0))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Camera lens dot inside pill
        let lensSize = s * 0.05
        let lensRect = CGRect(x: (s - lensSize) / 2.0, y: pillRect.midY - (lensSize / 2.0), width: lensSize, height: lensSize)
        ctx.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.9))
        ctx.fillEllipse(in: lensRect)
        
        // Dynamic Island Accent Arc
        let arcRect = CGRect(x: s * 0.25, y: s * 0.24, width: s * 0.5, height: s * 0.28)
        let arcPath = CGPath(roundedRect: arcRect, cornerWidth: s * 0.08, cornerHeight: s * 0.08, transform: nil)
        ctx.addPath(arcPath)
        ctx.setStrokeColor(CGColor(red: 0.65, green: 0.35, blue: 1.0, alpha: 0.75))
        ctx.setLineWidth(max(1.5, s * 0.02))
        ctx.strokePath()
        
        image.unlockFocus()
        
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let filename = size == 1024 ? "icon_512x512@2x.png" : "icon_\(size)x\(size).png"
            try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(filename)"))
            if size <= 512 {
                let filename2x = "icon_\(size/2)x\(size/2)@2x.png"
                try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(filename2x)"))
            }
        }
    }
    print("Iconset created successfully.")
}

generateAppIcon()
