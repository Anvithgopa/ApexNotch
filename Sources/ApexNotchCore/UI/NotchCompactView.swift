import SwiftUI
import Combine
import UniformTypeIdentifiers

public struct NotchCompactView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var prefs: UserPreferences
    @EnvironmentObject private var geometry: DisplayGeometryManager
    @ObservedObject private var music = MusicPlayerManager.shared
    @ObservedObject private var shelf = FileShelfManager.shared
    
    @NotchState private var isHovering: Bool = false
    @NotchState private var isDropTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        Group {
            if geometry.currentGeometry.hasPhysicalNotch {
                notchedCapsuleContent
            } else {
                standardCapsuleContent
            }
        }
        .frame(height: max(geometry.currentGeometry.compactFrame.height, 34.0))
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 18,
                topTrailingRadius: 0
            )
            .fill(Color.black)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 0
                )
                .strokeBorder(
                    isDropTargeted ? NotchDesign.accentCyan :
                    (isHovering ? Color.white.opacity(0.35) : Color.white.opacity(0.12)),
                    lineWidth: isDropTargeted ? 2 : 1
                )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                self.isHovering = hovering
            }
        }
        .onTapGesture {
            appState.setExpanded(true)
        }
        .onDrop(of: [.fileURL, .item], isTargeted: $isDropTargeted) { providers in
            let group = DispatchGroup()
            var collectedURLs: [URL] = []
            let lock = NSLock()
            
            for provider in providers {
                group.enter()
                if provider.canLoadObject(ofClass: URL.self) {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            lock.lock()
                            collectedURLs.append(url)
                            lock.unlock()
                        }
                        group.leave()
                    }
                } else {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let url = item as? URL {
                            lock.lock()
                            collectedURLs.append(url)
                            lock.unlock()
                        } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            lock.lock()
                            collectedURLs.append(url)
                            lock.unlock()
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                if !collectedURLs.isEmpty {
                    shelf.addFiles(urls: collectedURLs, asPinned: false)
                    appState.open(tab: .shelf)
                    appState.showToast("Added \(collectedURLs.count) item\(collectedURLs.count == 1 ? "" : "s") to Shelf")
                }
            }
            return true
        }
    }
    
    // MARK: - Notched Mac Layout (Dynamic Island Wings Flanking the Hardware Cutout)
    private var notchedCapsuleContent: some View {
        let notchWidth = geometry.currentGeometry.physicalNotchRect?.width ?? 179.0
        let totalWidth = geometry.currentGeometry.compactFrame.width
        let wingWidth = max((totalWidth - notchWidth) / 2.0 - 4.0, 32.0)
        
        return HStack(spacing: 0) {
            // LEFT WING: Situated to the left of the physical camera notch
            HStack(spacing: 4) {
                if isDropTargeted {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(NotchDesign.accentCyan)
                } else if music.currentTrack.isPlaying {
                    if prefs.showMusicArtwork {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 15, height: 15)
                            Image(systemName: "music.note")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(NotchDesign.accentAmber)
                    }
                } else if !shelf.items.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "tray.full.fill")
                            .font(.system(size: 9))
                            .foregroundColor(NotchDesign.accentCyan)
                        Text("\(shelf.items.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(NotchDesign.accentCyan)
                    }
                } else if prefs.petCharacter != .none {
                    NotchPetView()
                } else {
                    Circle()
                        .fill(NotchDesign.accentCyan)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: wingWidth, alignment: .center)
            
            // CENTER: Dedicated physical camera notch cutout (clean empty hardware space)
            Spacer(minLength: notchWidth)
            
            // RIGHT WING: Situated to the right of the physical camera notch
            HStack(spacing: 4) {
                if isDropTargeted {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(NotchDesign.accentCyan)
                } else if music.currentTrack.isPlaying {
                    AudioVisualizerView(
                        isPlaying: true,
                        barColor: NotchDesign.accentAmber,
                        style: prefs.musicVisualizerStyle
                    )
                    .frame(width: 16, height: 10)
                } else if isHovering {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(NotchDesign.accentCyan)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: wingWidth, alignment: .center)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Standard Non-Notched Mac Layout
    private var standardCapsuleContent: some View {
        HStack(spacing: 8) {
            // Left Status item
            if music.currentTrack.isPlaying {
                if prefs.showMusicArtwork {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [Color.orange, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 15, height: 15)
                        Image(systemName: "music.note")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(NotchDesign.accentAmber)
                }
            } else if !shelf.items.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 9))
                        .foregroundColor(NotchDesign.accentCyan)
                    Text("\(shelf.items.count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(NotchDesign.accentCyan)
                }
            } else if prefs.petCharacter != .none {
                NotchPetView()
            } else {
                Circle()
                    .fill(NotchDesign.accentCyan.opacity(0.9))
                    .frame(width: 6, height: 6)
            }
            
            Spacer()
            
            // Center info / Title
            if isDropTargeted {
                Text("Drop to Add")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(NotchDesign.accentCyan)
            } else if music.currentTrack.isPlaying {
                Text(music.currentTrack.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(NotchDesign.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("ApexNotch")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(NotchDesign.textSecondary)
            }
            
            Spacer()
            
            // Right Status item
            if music.currentTrack.isPlaying {
                AudioVisualizerView(
                    isPlaying: true,
                    barColor: NotchDesign.accentAmber,
                    style: prefs.musicVisualizerStyle
                )
                .frame(width: 16, height: 10)
            } else if isHovering {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(NotchDesign.accentCyan)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 12)
    }
}
