import SwiftUI

public struct BookmarkItem: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var urlString: String
    public var icon: String
    
    public init(id: UUID = UUID(), name: String, urlString: String, icon: String = "globe") {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.icon = icon
    }
}

@MainActor
public final class BookmarksManager: ObservableObject {
    public static let shared = BookmarksManager()
    
    @Published public var bookmarks: [BookmarkItem] = [] {
        didSet { saveBookmarks() }
    }
    
    private let storageURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ApexNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("bookmarks.json")
        loadBookmarks()
    }
    
    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            try? data.write(to: storageURL)
        }
    }
    
    private func loadBookmarks() {
        if let data = try? Data(contentsOf: storageURL),
           let loaded = try? JSONDecoder().decode([BookmarkItem].self, from: data) {
            self.bookmarks = loaded
        } else {
            // Default presets
            self.bookmarks = [
                BookmarkItem(name: "GitHub", urlString: "https://github.com", icon: "chevron.left.forwardslash.chevron.right"),
                BookmarkItem(name: "ChatGPT", urlString: "https://chatgpt.com", icon: "sparkles"),
                BookmarkItem(name: "Docs", urlString: "https://developer.apple.com", icon: "book.fill"),
                BookmarkItem(name: "YouTube", urlString: "https://youtube.com", icon: "play.rectangle.fill")
            ]
        }
    }
    
    public func open(item: BookmarkItem) {
        if let url = URL(string: item.urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func add(name: String, url: String) {
        var cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "https://" + cleanURL
        }
        let item = BookmarkItem(name: name, urlString: cleanURL)
        bookmarks.append(item)
    }
    
    public func delete(id: UUID) {
        bookmarks.removeAll(where: { $0.id == id })
    }
}

public struct BookmarksWidget: View {
    @ObservedObject private var manager = BookmarksManager.shared
    @NotchState private var showingAddSheet = false
    @NotchState private var newName = ""
    @NotchState private var newURL = ""
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Quick Links", systemImage: "bookmark.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentCyan)
                
                Spacer()
                
                Button(action: { showingAddSheet.toggle() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Add bookmark")
            }
            
            if showingAddSheet {
                HStack(spacing: 4) {
                    TextField("Name", text: $newName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10))
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                    
                    TextField("URL", text: $newURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10))
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                    
                    Button("Add") {
                        if !newName.isEmpty && !newURL.isEmpty {
                            manager.add(name: newName, url: newURL)
                            newName = ""
                            newURL = ""
                            showingAddSheet = false
                        }
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.plain)
                    .foregroundColor(NotchDesign.accentGreen)
                }
                .padding(.vertical, 2)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(manager.bookmarks) { item in
                        Button(action: { manager.open(item: item) }) {
                            HStack(spacing: 5) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(NotchDesign.accentCyan)
                                Text(item.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(NotchDesign.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Open in Browser") { manager.open(item: item) }
                            Button("Delete Bookmark", role: .destructive) { manager.delete(id: item.id) }
                        }
                    }
                }
                .padding(.horizontal, 1)
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
