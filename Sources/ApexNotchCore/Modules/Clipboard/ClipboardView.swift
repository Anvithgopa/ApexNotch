import SwiftUI

public struct ClipboardView: View {
    @ObservedObject private var manager = ClipboardManager.shared
    @ObservedObject private var prefs = UserPreferences.shared
    @NotchState private var hoveredItemId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header with search & actions
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textSecondary)
                    TextField("Search clipboard history...", text: $manager.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !manager.searchText.isEmpty {
                        Button(action: { manager.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(NotchDesign.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                
                Button(action: { prefs.clipboardMonitoringPaused.toggle() }) {
                    Image(systemName: prefs.clipboardMonitoringPaused ? "pause.fill" : "record.circle")
                        .font(.system(size: 11))
                        .foregroundColor(prefs.clipboardMonitoringPaused ? NotchDesign.accentAmber : NotchDesign.accentGreen)
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help(prefs.clipboardMonitoringPaused ? "Monitoring Paused (Click to Resume)" : "Monitoring Active")
                
                if !manager.items.isEmpty {
                    Button(action: { manager.clearHistory() }) {
                        Label("Clear", systemImage: "trash")
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Clear non-pinned clipboard history")
                }
            }
            
            // Clipboard items list
            if manager.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(NotchDesign.textTertiary)
                    Text(manager.searchText.isEmpty ? "No Clipboard History" : "No matches found")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(NotchDesign.textSecondary)
                    Text(manager.searchText.isEmpty ? "Copy text, links, or code snippets from any app to see them here." : "Try a different search term.")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 6) {
                        ForEach(manager.filteredItems) { item in
                            clipboardRow(item: item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NotchDesign.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private func clipboardRow(item: ClipboardItem) -> some View {
        HStack(spacing: 10) {
            typeIcon(for: item)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.system(size: 12, weight: item.isPinned ? .semibold : .regular))
                    .foregroundColor(item.isSecret ? NotchDesign.accentAmber : NotchDesign.textPrimary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(item.timeFormatted)
                        .font(.system(size: 10))
                        .foregroundColor(NotchDesign.textTertiary)
                    
                    if item.isPinned {
                        Text("• Pinned")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NotchDesign.accentAmber)
                    }
                    if item.isSecret {
                        Text("• Sensitive")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NotchDesign.accentRed)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Button(action: { manager.copyToClipboard(item: item) }) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 10))
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Copy again")
                
                Button(action: { manager.togglePin(id: item.id) }) {
                    Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(item.isPinned ? NotchDesign.accentAmber : NotchDesign.textSecondary)
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin snippet" : "Pin snippet")
                
                Button(action: { manager.removeItem(id: item.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(NotchDesign.textTertiary)
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Delete snippet")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(item.isPinned ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manager.copyToClipboard(item: item)
        }
    }
    
    @ViewBuilder
    private func typeIcon(for item: ClipboardItem) -> some View {
        if item.isSecret {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(NotchDesign.accentRed)
                .font(.system(size: 14))
                .frame(width: 22)
        } else {
            switch item.type {
            case .url:
                Image(systemName: "link")
                    .foregroundColor(NotchDesign.accentCyan)
                    .font(.system(size: 14))
                    .frame(width: 22)
            case .code:
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(NotchDesign.accentPurple)
                    .font(.system(size: 12))
                    .frame(width: 22)
            case .color:
                Circle()
                    .fill(Color(hex: item.content) ?? NotchDesign.accentGreen)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    .frame(width: 22)
            default:
                Image(systemName: "text.alignleft")
                    .foregroundColor(NotchDesign.textSecondary)
                    .font(.system(size: 14))
                    .frame(width: 22)
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }
        guard clean.count == 6 || clean.count == 8,
              let intVal = UInt64(clean, radix: 16) else { return nil }
        
        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
