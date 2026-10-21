import AppKit
import SwiftUI
import QuickLookUI
import UniformTypeIdentifiers

private struct PinnedFileRecord: Codable {
    let bookmarkData: Data
    let name: String
    let dateAdded: Date
}

@MainActor
public final class FileShelfManager: NSObject, ObservableObject {
    public static let shared = FileShelfManager()
    
    @Published public private(set) var items: [FileItem] = []
    @Published public var previewURL: URL? = nil
    
    private let storageURL: URL
    
    override private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ApexNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("pinned_shelf.json")
        super.init()
        loadPinnedItems()
    }
    
    public func addFiles(urls: [URL], asPinned: Bool = false) {
        for url in urls {
            // Avoid duplicate items
            if !items.contains(where: { $0.url.path == url.path }) {
                let item = FileItem(url: url, isPinned: asPinned, isTemporary: !asPinned)
                items.insert(item, at: 0)
            }
        }
        if asPinned {
            savePinnedItems()
        }
        AppState.shared.showToast("Added \(urls.count) item\(urls.count == 1 ? "" : "s") to Shelf")
    }
    
    public func removeItem(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items[index]
            items.remove(at: index)
            if item.isPinned {
                savePinnedItems()
            }
        }
    }
    
    public func togglePin(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isPinned.toggle()
            items[index].isTemporary = !items[index].isPinned
            savePinnedItems()
            AppState.shared.showToast(items[index].isPinned ? "Item pinned" : "Item unpinned")
        }
    }
    
    public func clearTemporary() {
        let beforeCount = items.count
        items.removeAll(where: { $0.isTemporary && !$0.isPinned })
        let cleared = beforeCount - items.count
        if cleared > 0 {
            AppState.shared.showToast("Cleared \(cleared) temporary item\(cleared == 1 ? "" : "s")")
        }
    }
    
    public func clearAll() {
        items.removeAll()
        savePinnedItems()
        AppState.shared.showToast("File Shelf cleared")
    }
    
    public func openFile(item: FileItem) {
        guard item.isAvailable else {
            AppState.shared.showToast("File no longer exists at original path")
            return
        }
        NSWorkspace.shared.open(item.url)
    }
    
    public func showInFinder(item: FileItem) {
        guard item.isAvailable else {
            AppState.shared.showToast("File no longer exists at original path")
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
    
    public func triggerAirDrop(item: FileItem) {
        guard item.isAvailable else { return }
        if let service = NSSharingService(named: .sendViaAirDrop) {
            if service.canPerform(withItems: [item.url]) {
                service.perform(withItems: [item.url])
            } else {
                AppState.shared.showToast("AirDrop is unavailable for this item")
            }
        }
    }
    
    public func preview(item: FileItem) {
        guard item.isAvailable else { return }
        self.previewURL = item.url
        QuickLookCoordinator.shared.preview(url: item.url)
    }
    
    // MARK: - Persistence
    private func savePinnedItems() {
        let pinned = items.filter { $0.isPinned }
        var records: [PinnedFileRecord] = []
        for item in pinned {
            if let bookmark = try? item.url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                records.append(PinnedFileRecord(bookmarkData: bookmark, name: item.name, dateAdded: item.dateAdded))
            }
        }
        
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: storageURL)
        }
    }
    
    private func loadPinnedItems() {
        guard let data = try? Data(contentsOf: storageURL),
              let records = try? JSONDecoder().decode([PinnedFileRecord].self, from: data) else { return }
        
        var loadedItems: [FileItem] = []
        for record in records {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: record.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                let item = FileItem(url: url, isPinned: true, isTemporary: false, dateAdded: record.dateAdded)
                loadedItems.append(item)
            }
        }
        self.items = loadedItems
    }
}
