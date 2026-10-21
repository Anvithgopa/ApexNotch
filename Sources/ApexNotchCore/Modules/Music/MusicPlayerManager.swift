import Foundation
import AppKit
import Combine

public struct TrackInfo: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var position: Double
    public var duration: Double
    public var playerSource: String
    
    public init(
        title: String = "No Media Playing",
        artist: String = "Apple Music or Spotify",
        album: String = "",
        isPlaying: Bool = false,
        position: Double = 0.0,
        duration: Double = 0.0,
        playerSource: String = "None"
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.position = position
        self.duration = duration
        self.playerSource = playerSource
    }
}

@MainActor
public final class MusicPlayerManager: ObservableObject {
    public static let shared = MusicPlayerManager()
    
    @Published public private(set) var currentTrack = TrackInfo()
    @Published public private(set) var isAvailable: Bool = false
    
    private var timer: Timer?
    private var isQuerying = false
    
    private init() {
    }
    
    public func startPolling() {
        guard timer == nil else { return }
        pollCurrentPlayer()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollCurrentPlayer()
            }
        }
    }
    
    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    public func pollCurrentPlayer() {
        guard !isQuerying else { return }
        isQuerying = true
        
        let preferred = UserPreferences.shared.musicPreferredPlayer
        
        Task.detached(priority: .userInitiated) { [weak self] in
            let track = MusicPlayerManager.fetchTrackStatic(preference: preferred)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isQuerying = false
                self.currentTrack = track
                self.isAvailable = track.playerSource != "None"
                AppState.shared.isMediaPlaying = track.isPlaying
                AppState.shared.currentMediaTitle = track.isPlaying ? "\(track.title) • \(track.artist)" : nil
            }
        }
    }
    
    public nonisolated static func fetchTrackStatic(preference: MusicPlayerType) -> TrackInfo {
        if preference == .appleMusic || preference == .auto {
            if let track = queryAppleMusic() {
                return track
            }
        }
        if preference == .spotify || preference == .auto {
            if let track = querySpotify() {
                return track
            }
        }
        return TrackInfo()
    }
    
    private nonisolated static func queryAppleMusic() -> TrackInfo? {
        let script = """
        if application "Music" is running then
            tell application "Music"
                set pState to (player state as string)
                if pState is "playing" or pState is "paused" then
                    set tName to (name of current track)
                    set tArtist to (artist of current track)
                    set tAlbum to (album of current track)
                    set tPos to (player position as string)
                    set tDur to (duration of current track as string)
                    return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tPos & "|||" & tDur
                end if
            end tell
        end if
        return "none"
        """
        guard let output = executeAppleScript(script), output != "none" else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let state = parts[0].lowercased()
        let isPlaying = state.contains("play")
        let title = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let pos = Double(parts[4]) ?? 0.0
        let dur = Double(parts[5]) ?? 0.0
        
        return TrackInfo(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            position: pos,
            duration: dur,
            playerSource: "Music"
        )
    }
    
    private nonisolated static func querySpotify() -> TrackInfo? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                set pState to (player state as string)
                if pState is "playing" or pState is "paused" then
                    set tName to (name of current track)
                    set tArtist to (artist of current track)
                    set tAlbum to (album of current track)
                    set tPos to (player position as string)
                    set tDur to ((duration of current track) / 1000 as string)
                    return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tPos & "|||" & tDur
                end if
            end tell
        end if
        return "none"
        """
        guard let output = executeAppleScript(script), output != "none" else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let state = parts[0].lowercased()
        let isPlaying = state.contains("play")
        let title = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let pos = Double(parts[4]) ?? 0.0
        let dur = Double(parts[5]) ?? 0.0
        
        return TrackInfo(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            position: pos,
            duration: dur,
            playerSource: "Spotify"
        )
    }
    
    private nonisolated static func executeAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
    
    // Playback actions
    public func togglePlayPause() {
        let source = currentTrack.playerSource
        let app = (source == "Spotify") ? "Spotify" : "Music"
        let script = "tell application \"\(app)\" to playpause"
        _ = MusicPlayerManager.executeAppleScript(script)
        pollCurrentPlayer()
    }
    
    public func nextTrack() {
        let source = currentTrack.playerSource
        let app = (source == "Spotify") ? "Spotify" : "Music"
        let script = "tell application \"\(app)\" to next track"
        _ = MusicPlayerManager.executeAppleScript(script)
        pollCurrentPlayer()
    }
    
    public func previousTrack() {
        let source = currentTrack.playerSource
        let app = (source == "Spotify") ? "Spotify" : "Music"
        let script = "tell application \"\(app)\" to previous track"
        _ = MusicPlayerManager.executeAppleScript(script)
        pollCurrentPlayer()
    }
}
