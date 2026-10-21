import SwiftUI

@MainActor
public final class QuickNotesManager: ObservableObject {
    public static let shared = QuickNotesManager()
    
    @Published public var noteText: String = "" {
        didSet { saveNote() }
    }
    
    private let storageURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ApexNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("quick_notes.txt")
        loadNote()
    }
    
    private func saveNote() {
        try? noteText.write(to: storageURL, atomically: true, encoding: .utf8)
    }
    
    private func loadNote() {
        if let text = try? String(contentsOf: storageURL, encoding: .utf8) {
            self.noteText = text
        }
    }
    
    public func clear() {
        noteText = ""
    }
    
    public func copyNote() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(noteText, forType: .string)
        AppState.shared.showToast("Note copied to clipboard!")
    }
}

public struct QuickNotesWidget: View {
    @ObservedObject private var manager = QuickNotesManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Quick Scratchpad", systemImage: "note.text")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentAmber)
                
                Spacer()
                
                if !manager.noteText.isEmpty {
                    Button(action: { manager.copyNote() }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Copy note")
                    
                    Button(action: { manager.clear() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Clear note")
                }
            }
            
            TextEditor(text: $manager.noteText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(NotchDesign.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                .frame(height: 70)
            
            HStack {
                let words = manager.noteText.split(whereSeparator: \.isWhitespace).count
                Text("\(words) words • \(manager.noteText.count) chars")
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textTertiary)
                Spacer()
                Text("Auto-saved")
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.accentGreen.opacity(0.8))
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
