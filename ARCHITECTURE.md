# ApexNotch: Architecture & Technical Design

This document details the architectural decisions, design patterns, threading model, and subsystem relationships that power **ApexNotch**.

---

## 🏛️ High-Level System Architecture

```mermaid
graph TD
    subgraph System Layer
        Screen[NSScreen Geometry]
        InputEvents[NSEvent Global / Local Monitors]
        Pasteboard[NSPasteboard]
        MachKernel[Mach Host Processor & VM APIs]
        EventKitEngine[EventKit Store]
        AVCapture[AVCaptureSession Engine]
        IOKitPower[IOKit Power Sources]
    end

    subgraph Core Engine
        GeomManager[DisplayGeometryManager]
        HoverCtrl[NotchWindowController]
        Panel[NotchPanel: Borderless Floating Panel]
        AppState[AppState Coordinator]
        Prefs[UserPreferences]
        Perms[PermissionManager]
    end

    subgraph Feature Modules
        ShelfMod[FileShelfManager + QuickLook]
        ClipMod[ClipboardManager]
        MusicMod[MusicPlayerManager + AppleScript]
        DashMod[Productivity Widgets + Registry]
        CamMod[CameraManager]
        NetMod[NetworkMonitor]
        BrowserMod[BrowserViewModel + WKWebView]
    end

    subgraph SwiftUI Presentation Layer
        RootView[NotchRootView]
        CompactView[NotchCompactView]
        ExpandedHub[NotchCapsuleHeader + Tab Views]
        SettingsUI[SettingsView]
    end

    Screen --> GeomManager
    InputEvents --> HoverCtrl
    GeomManager --> Panel
    HoverCtrl --> AppState
    AppState --> Panel
    Prefs --> AppState

    MachKernel --> DashMod
    IOKitPower --> DashMod
    EventKitEngine --> DashMod
    Pasteboard --> ClipMod
    AVCapture --> CamMod

    AppState --> RootView
    RootView --> CompactView
    RootView --> ExpandedHub

    ShelfMod --> ExpandedHub
    ClipMod --> ExpandedHub
    MusicMod --> ExpandedHub
    DashMod --> ExpandedHub
    CamMod --> ExpandedHub
    NetMod --> ExpandedHub
    BrowserMod --> ExpandedHub

    Prefs --> SettingsUI
    Perms --> SettingsUI
```

---

## 🔄 Interaction & Hover Lifecycle Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as User Mouse Cursor
    participant Screen as NSScreen & Geometry
    participant WinCtrl as NotchWindowController
    participant AppState as AppState
    participant Panel as NotchPanel (NSPanel)
    participant UI as NotchRootView (SwiftUI)

    User->>WinCtrl: Pointer moves into Notch trigger zone (top center)
    WinCtrl->>WinCtrl: Start debounced open timer (hoverOpenDelay = 120ms)
    WinCtrl->>AppState: setExpanded(true)
    AppState->>Panel: Animate frame to expandedFrame (spring curve)
    AppState->>UI: Render expanded module hub & active tab
    User->>UI: Interacts with File Shelf / Clipboard / Widgets
    User->>WinCtrl: Pointer exits expanded window perimeter
    WinCtrl->>WinCtrl: Start debounced close timer (hoverCloseDelay = 350ms)
    alt If User pinned the notch
        WinCtrl-->>WinCtrl: Keep open (isPinned == true)
    else If unpinned
        WinCtrl->>AppState: collapse()
        AppState->>Panel: Animate frame back to compactFrame
        AppState->>UI: Render compact Dynamic Island capsule
    end
```

---

## 🧵 Threading & Concurrency Model

ApexNotch adheres to **Swift 6 strict concurrency (`ApproachableConcurrency`)**:

1. **MainActor Isolation:**
   - All UI elements, SwiftUI Views, `AppState`, `UserPreferences`, `NotchPanel`, `NotchWindowController`, and `SettingsWindowController` are `@MainActor`-isolated.
   - All state mutations are guaranteed to execute on the main thread, eliminating UI stutter and race conditions.

2. **Background Detached Tasks:**
   - **AppleScript Media Querying:** Queries to Apple Music and Spotify run in `Task.detached(priority: .userInitiated)` to avoid blocking the main UI thread during Apple Event resolution.
   - **Network Byte Counters:** BSD `getifaddrs` sampling occurs asynchronously and updates `@Published` properties on `@MainActor`.
   - **Camera Stream Management:** `AVCaptureSession` configuration and start/stop routines run on a dedicated serial background queue (`sessionQueue`), while the preview layer is rendered seamlessly via CoreAnimation.

3. **Lifecycle-Aware Resource Pausing:**
   - When the notch is collapsed:
     - `CameraManager` halts video capture.
     - `AudioVisualizerView` halts equalizer bar timers.
     - `NetworkMonitor` pauses polling intervals.
     - `SystemStatsService` pauses CPU load calculations.
   - This ensures **idle CPU consumption remains < 0.2%** on Apple Silicon Macs.

---

## 💾 Local Storage Schema

All persistent state is saved in `~/Library/Application Support/ApexNotch/`:

- `pinned_shelf.json`: Contains security-scoped bookmark records for files pinned to the shelf.
- `clipboard_history.json`: Encoded `[ClipboardItem]` records with timestamps, types, and pinned flags.
- `quick_notes.txt`: Auto-saved scratchpad text.
- `bookmarks.json`: User-configured quick bookmarks list.
- `widgets_config.json`: Enabled/disabled widget registry configuration.
- `UserDefaults`: Notch dimensions, animation speeds, player preference, search engine selection.
