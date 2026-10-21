# ApexNotch: Feature & Permission Matrix

This document provides a comprehensive mapping of every ApexNotch feature module to its corresponding macOS frameworks, required permissions, and graceful fallback behaviors when permissions are not granted.

---

## 📋 Module & API Matrix

| Feature Module | Core Functionality | System Frameworks & APIs | Permission Required | Graceful Fallback Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Notch Engine** | Displays floating notch capsule hugging physical notch or top screen center. Smooth spring expansion/collapse. | `AppKit`, `NSScreen`, `NSPanel`, `CoreAnimation`, `SwiftUI` | None | Works out-of-the-box on both notched and non-notched Macs. |
| **Multi-Monitor Geometry** | Detects active screen, safe area insets, resolution changes, and auxiliary areas. | `NSScreen.safeAreaInsets`, `auxiliaryTopLeftArea`, `auxiliaryTopRightArea`, `NSWorkspace.activeSpaceDidChangeNotification` | None | Defaults to primary screen or follows mouse cursor. |
| **File Shelf** | Drag files in and hold them while switching spaces. Drag files back out to Finder/apps. | `NSItemProvider`, `NSWorkspace`, `UniformTypeIdentifiers`, `QuickLookUI` | User-selected file access (Native Sandboxing / Drag & Drop) | Only accesses dragged files via security-scoped bookmarks. Unavailable files show clear badge. |
| **Quick Look Preview** | Preview shelf files with spacebar or eye button. | `QLPreviewPanel`, `QLPreviewItem` | None | If preview panel is unavailable, opens file in default application. |
| **Clipboard History** | Real-time monitoring of copied text, URLs, colors, and code snippets. | `NSPasteboard.general`, `NSPasteboard.changeCount` | None (Local pasteboard access) | Password manager concealed markers (`TransientType`) are ignored automatically. Secrets are redacted. |
| **Media Player** | Displays current track, artwork, and playback progress for Apple Music & Spotify. | `NSAppleScript`, `DistributedNotificationCenter`, `NSRunningApplication` | Apple Events / Automation (Prompted upon first playback control) | Displays clean fallback state if players are closed or permission is declined. |
| **Audio Visualizer** | Smoothly animated frequency equalizer bars while audio is playing. | `SwiftUI`, `CoreAnimation` | None | Flatlines when music is paused; stops animation when notch is collapsed to conserve CPU. |
| **Clock & World Times** | Real-time clock with date and international time zones (London, Tokyo, NY, SF). | `Foundation.Date`, `DateFormatter`, `TimeZone` | None | Updates once per second; negligible CPU usage. |
| **Calendar Meetings** | Upcoming calendar meetings within next 48 hours. | `EventKit` (`EKEventStore.events(matching:)`) | Calendar Access (`NSCalendarsUsageDescription`) | Shows friendly "Authorize Access" card with direct System Settings button. |
| **Reminders Checklist** | View and complete pending tasks directly in notch. Quick add new tasks. | `EventKit` (`EKEventStore.fetchReminders`) | Reminders Access (`NSRemindersUsageDescription`) | Shows friendly "Authorize Access" card with direct System Settings button. |
| **Quick Scratchpad** | Auto-saving notes with character & word counts. | `Foundation.FileManager`, `Application Support` | None | Persists to local file; copies to pasteboard with one click. |
| **Bookmarks Launcher** | Fast launchers for frequently visited websites. | `NSWorkspace.shared.open(url:)` | None | Opens in user's default web browser. |
| **App Shortcuts** | Quick switcher and launcher for common system apps. | `NSWorkspace.shared.openApplication` | None | Launches app in background without interrupting notch state. |
| **Pomodoro Focus** | 25m work / 5m break timer cycles with progress ring and alerts. | `UserNotifications`, `Timer` | Notifications (`UNUserNotificationCenter`) | If notifications denied, in-app toast alerts the user. |
| **Precision Stopwatch** | Stopwatch with lap time recordings. | `Foundation.Timer`, `TimeInterval` | None | Millisecond precision. |
| **Hydration & Habit Counter** | Daily water tracker and customizable habit count. | `UserDefaults` | None | Retains daily tally locally. |
| **Milestone Countdown** | Days-until target date calculation. | `Calendar.dateComponents` | None | Real-time calculation. |
| **Camera Mirror** | Live quick mirror with 16:9, 4:3, square aspect ratios and horizontal flipping. | `AVFoundation` (`AVCaptureSession`, `AVCaptureVideoPreviewLayer`) | Camera Access (`NSCameraUsageDescription`) | Shows prominent permission request button. Stops capture immediately when collapsed. |
| **Network Speed Monitor** | Real-time download and upload speeds with history sparkline. | BSD `getifaddrs`, `if_data.ifi_ibytes`, `ifi_obytes` | None | Pauses sampling when notch is collapsed to save CPU cycles. |
| **System Hardware Gauges** | Live CPU %, Memory GB/%, Disk free space, and Battery charging status. | `mach_host_self()`, `host_processor_info()`, `host_statistics64()`, `IOKit.ps` | None | Safe kernel metrics without third-party kernel extensions. |
| **Quick Browser** | Embedded web browser with URL bar and search engine presets. | `WebKit` (`WKWebView`) | None (Standard outbound HTTP/HTTPS) | Safe sandbox execution. |
| **Global Keyboard Hotkey** | `⌥⌘N` hotkey to toggle notch open/closed from any application. | `NSEvent.addGlobalMonitorForEvents` | Accessibility (`AXIsProcessTrusted`) | If accessibility is denied, users can still click the notch or menu bar icon. |

---

## 🛡️ Privacy & Security Commitments

1. **No External Network Calls:** ApexNotch communicates with external networks **strictly** when the user requests web navigation in the Quick Browser or opens a bookmark.
2. **Zero Telemetry:** No analytics SDKs, error reporting beacons, or analytics trackers are bundled.
3. **Hardware Camera Protection:** When the notch collapses or the user switches tabs, `AVCaptureSession.stopRunning()` is invoked synchronously to ensure the green hardware indicator on the Mac display turns off immediately.
4. **Secret Sanitization:** Automatically detects and redacts tokens (`ghp_`, `sk-`, `AKIA`, RSA Private Keys) before saving to clipboard history.
