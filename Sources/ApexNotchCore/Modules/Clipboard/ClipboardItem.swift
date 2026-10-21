import Foundation
import AppKit

public enum ClipboardContentType: String, Codable {
    case text
    case url
    case code
    case color
    case image
}

public struct ClipboardItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let content: String
    public let type: ClipboardContentType
    public let timestamp: Date
    public var isPinned: Bool
    public var isSecret: Bool
    public var secretDescription: String?
    
    public init(
        id: UUID = UUID(),
        content: String,
        type: ClipboardContentType = .text,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        isSecret: Bool = false,
        secretDescription: String? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.isSecret = isSecret
        self.secretDescription = secretDescription
    }
    
    public var displayTitle: String {
        if isSecret {
            return "•••••••• [\(secretDescription ?? "Hidden Secret")]"
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "Empty Snippet" : firstLine
    }
    
    public var timeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
