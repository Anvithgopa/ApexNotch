# ApexNotch: Quality Assurance & Testing Checklist

Use this checklist to perform comprehensive verification of ApexNotch across hardware, operating systems, and edge cases.

---

## 💻 1. Display Geometry & Multi-Monitor

- [x] **MacBook Pro with Hardware Notch (14" / 16"):**
  - Compact capsule aligns perfectly with the physical camera notch (`safeAreaInsets.top > 0`).
  - Capsule expands seamlessly downward without covering menu bar icons.
- [x] **MacBook Air & Non-Notched Displays (e.g. Studio Display, External Monitors):**
  - Compact capsule centers at the top edge of the screen as a virtual Dynamic Island (`safeAreaInsets.top == 0`).
  - Height defaults to standard 32 pt pill.
- [x] **Multiple Displays:**
  - With "Follow Mouse Screen" enabled in Settings, the notch relocates to the active monitor where cursor resides.
  - Multi-monitor resolution changes trigger `NSApplication.didChangeScreenParametersNotification` and recalibrate dimensions instantly.
- [x] **Full-Screen Spaces:**
  - When switching to full-screen apps or separate virtual desktops, `NSPanel` remains accessible via `.canJoinAllSpaces` and `.fullScreenAuxiliary`.

---

## 🗄️ 2. File Shelf Module

- [x] **Drag Files In:**
  - Dragging single and multiple files from Finder directly onto the compact notch opens the shelf and adds them.
  - File cards show correct system file icons, name, and formatted size (e.g., KB, MB, GB).
- [x] **Drag Files Out:**
  - Dragging a file card out of the shelf into Finder, Desktop, Mail, or Slack transfers the file reference seamlessly.
- [x] **Quick Look:**
  - Double clicking or clicking the eye icon opens macOS `QLPreviewPanel` with spacebar controls.
- [x] **Pinning vs. Temporary:**
  - Pinned items persist across application restarts.
  - Temporary items can be cleared in bulk with "Clear Temp".
- [x] **File Safety:**
  - Original files remain intact and unmodified on disk.

---

## 📋 3. Clipboard Manager Module

- [x] **Continuous Capture:**
  - Copying text, URLs, colors, or code snippets from any application updates the clipboard history.
- [x] **Secret Detection & Redaction:**
  - GitHub tokens (`ghp_...`), OpenAI keys (`sk-...`), and AWS access keys (`AKIA...`) are detected and tagged with red badge.
- [x] **Private Marker Respect:**
  - Passwords copied from 1Password or marked with `TransientType` / `ConcealedType` are ignored.
- [x] **Search & Recopy:**
  - Typing in search box filters history immediately.
  - Clicking any item recopys it to the system pasteboard with a confirmation toast.
- [x] **Clear & Pause:**
  - Pausing monitoring halts capture. "Clear" removes non-pinned items.

---

## 🎵 4. Music Player & Visualizer

- [x] **Apple Music & Spotify:**
  - Displays track title, artist name, and album.
  - Play, pause, previous track, and next track buttons execute reliably via Apple Events.
- [x] **Animated Visualizer:**
  - Equalizer bars bounce dynamically during playback.
  - Bars flatline when paused.
- [x] **CPU Conservation:**
  - Polling and visualizer animations stop when the notch is collapsed.

---

## 📊 5. Productivity Dashboard Widgets

- [x] **Clock & World Times:** Displays live clock with seconds and world time zones (London, Tokyo, NY, SF).
- [x] **Calendar & Reminders:** Integrates with EventKit; allows checking off reminders inline.
- [x] **Quick Scratchpad:** Auto-saves text to disk in real-time; persists across restarts.
- [x] **Bookmarks:** Opens links in default web browser.
- [x] **App Shortcuts:** Launches system apps (Finder, Safari, Terminal, Notes).
- [x] **Pomodoro Timer:** Work/break cycle progression, circular progress ring, completion alerts.
- [x] **Stopwatch:** Millisecond accuracy, lap time list, reset button.
- [x] **Hydration & Habit:** Daily water glass count and habit tally.
- [x] **Milestone Countdown:** Days-remaining countdown for deadlines.
- [x] **System Metrics:** Real-time CPU %, RAM GB/%, Disk free space, and Battery charging status.
- [x] **Network Speed Monitor:** Live upload/download gauges and history sparkline.

---

## 🪞 6. Camera Mirror Module

- [x] **Stream Lifecycle:**
  - Preview appears when the Mirror tab is selected.
  - Video capture terminates **immediately** when switching tabs or collapsing the notch, turning off the green hardware camera indicator.
- [x] **Mirroring & Aspect Ratios:**
  - Horizontal flip toggle functions properly.
  - Segmented control switches between 16:9, 4:3, and 1:1.

---

## 🌐 7. Quick Browser Module

- [x] **Search & Navigation:**
  - Navigates to URLs or search terms with DuckDuckGo / Google / Kagi / Bing.
  - Back, forward, and reload buttons work seamlessly.

---

## ⚙️ 8. Settings & Permissions

- [x] **Settings Window:**
  - Multi-tab navigation operates without memory leaks or UI glitches.
  - Changing slider values (expanded dimensions, hover delays) updates the notch geometry immediately.
- [x] **Permission Deep Links:**
  - Clicking "Manage" in Permissions tab opens the exact macOS System Settings privacy pane.
