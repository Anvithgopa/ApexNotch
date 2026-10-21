import SwiftUI
import UniformTypeIdentifiers

public struct FileShelfView: View {
    @ObservedObject private var shelf = FileShelfManager.shared
    @NotchState private var isTargetedForDrop: Bool = false
    @NotchState private var hoveredItemId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Top action bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .foregroundColor(NotchDesign.accentCyan)
                    Text("File Shelf")
                        .font(.system(size: 13, weight: .semibold))
                    Text("(\(shelf.items.count))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(NotchDesign.textSecondary)
                }
                
                Spacer()
                
                if !shelf.items.isEmpty {
                    Button(action: { shelf.clearTemporary() }) {
                        Label("Clear Temp", systemImage: "sparkles")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    
                    Button(action: { shelf.clearAll() }) {
                        Label("Clear All", systemImage: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                }
            }
            
            // Drop target & file list
            if shelf.items.isEmpty {
                emptyShelfDropZone
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelf.items) { item in
                            fileCard(item: item)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
                .frame(height: 140)
            }
            
            // Bottom quick drop prompt
            if !shelf.items.isEmpty {
                HStack {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textTertiary)
                    Text("Drop more files here • Drag items out to Finder or any app")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textSecondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isTargetedForDrop ? NotchDesign.accentCyan.opacity(0.12) : NotchDesign.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isTargetedForDrop ? NotchDesign.accentCyan : NotchDesign.borderSubtle, lineWidth: isTargetedForDrop ? 2 : 1)
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private var emptyShelfDropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: isTargetedForDrop ? "arrow.down.circle.fill" : "tray.and.arrow.down")
                .font(.system(size: 36))
                .foregroundColor(isTargetedForDrop ? NotchDesign.accentCyan : NotchDesign.textSecondary)
                .scaleEffect(isTargetedForDrop ? 1.15 : 1.0)
                .animation(.spring(response: 0.25), value: isTargetedForDrop)
            
            Text("Drag & Drop Files Here")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(NotchDesign.textPrimary)
            
            Text("Hold files while switching spaces or applications. Drag them back out anytime.")
                .font(.system(size: 11))
                .foregroundColor(NotchDesign.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
    }
    
    private func fileCard(item: FileItem) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(NotchDesign.accentAmber)
                        .padding(3)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
            
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(NotchDesign.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(width: 86)
                
                Text(item.sizeFormatted)
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textSecondary)
            }
            
            // Hover quick actions
            HStack(spacing: 6) {
                Button(action: { shelf.preview(item: item) }) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .help("Quick Look")
                
                Button(action: { shelf.togglePin(id: item.id) }) {
                    Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin item" : "Pin item")
                
                Button(action: { shelf.triggerAirDrop(item: item) }) {
                    Image(systemName: "airdrop")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .help("AirDrop file")
                
                Button(action: { shelf.removeItem(id: item.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .help("Remove from shelf")
            }
            .foregroundColor(NotchDesign.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.08))
            .cornerRadius(4)
        }
        .frame(width: 98, height: 124)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
        .onDrag {
            // Native drag-out support
            NSItemProvider(object: item.url as NSURL)
        }
        .onTapGesture(count: 2) {
            shelf.openFile(item: item)
        }
        .contextMenu {
            Button("Open File") { shelf.openFile(item: item) }
            Button("Show in Finder") { shelf.showInFinder(item: item) }
            Button("Quick Look Preview") { shelf.preview(item: item) }
            Divider()
            Button(item.isPinned ? "Unpin File" : "Pin File") { shelf.togglePin(id: item.id) }
            Button("Share via AirDrop") { shelf.triggerAirDrop(item: item) }
            Divider()
            Button("Remove from Shelf", role: .destructive) { shelf.removeItem(id: item.id) }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            shelf.addFiles(urls: [url], asPinned: false)
                        }
                    }
                }
            } else {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            shelf.addFiles(urls: [url], asPinned: false)
                        }
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            shelf.addFiles(urls: [url], asPinned: false)
                        }
                    }
                }
            }
        }
    }
}
