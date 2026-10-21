import AppKit
import SwiftUI
import QuickLookThumbnailing

public struct FileItem: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let fileExtension: String
    public let sizeFormatted: String
    public var isPinned: Bool
    public var isTemporary: Bool
    public let dateAdded: Date
    public var icon: NSImage
    public var isAvailable: Bool
    
    public init(
        id: UUID = UUID(),
        url: URL,
        isPinned: Bool = false,
        isTemporary: Bool = true,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.name = url.lastPathComponent
        self.fileExtension = url.pathExtension.uppercased()
        self.isPinned = isPinned
        self.isTemporary = isTemporary
        self.dateAdded = dateAdded
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
            self.isAvailable = true
            if isDir.boolValue {
                self.sizeFormatted = "Folder"
            } else if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
                      let size = attrs[.size] as? UInt64 {
                self.sizeFormatted = FileItem.formatBytes(size)
            } else {
                self.sizeFormatted = "--"
            }
        } else {
            self.isAvailable = false
            self.sizeFormatted = "Unavailable"
        }
        
        // Default system icon
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }
    
    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id && lhs.isPinned == rhs.isPinned && lhs.isTemporary == rhs.isTemporary
    }
    
    public static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
