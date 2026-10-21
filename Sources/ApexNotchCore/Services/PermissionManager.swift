import Foundation
import AppKit
import AVFoundation
import EventKit
import UserNotifications

public enum PermissionKind: String, CaseIterable, Identifiable {
    case camera = "Camera"
    case calendar = "Calendar"
    case reminders = "Reminders"
    case accessibility = "Accessibility"
    case appleEvents = "Media Automation"
    case notifications = "Notifications"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .accessibility: return "accessibility"
        case .appleEvents: return "applescript"
        case .notifications: return "bell.badge.fill"
        }
    }
    
    public var explanation: String {
        switch self {
        case .camera:
            return "Used only when opening the Camera Mirror widget to show your preview."
        case .calendar:
            return "Used to display your upcoming calendar events and meeting schedules in the dashboard."
        case .reminders:
            return "Used to view and check off tasks directly from the notch hub."
        case .accessibility:
            return "Allows global shortcut triggers and active window detection without stealing focus."
        case .appleEvents:
            return "Used to control Apple Music and Spotify playback and read current track details."
        case .notifications:
            return "Sends subtle reminders when your Pomodoro or Countdown timers complete."
        }
    }
    
    public var settingsURL: URL? {
        switch self {
        case .camera:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
        case .calendar:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        case .reminders:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .appleEvents:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
        case .notifications:
            return URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        }
    }
}

public enum PermissionStatus: String {
    case authorized = "Authorized"
    case denied = "Denied"
    case notDetermined = "Not Requested"
    case restricted = "Restricted"
}

@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published public private(set) var calendarStatus: PermissionStatus = .notDetermined
    @Published public private(set) var remindersStatus: PermissionStatus = .notDetermined
    @Published public private(set) var accessibilityStatus: PermissionStatus = .notDetermined
    @Published public private(set) var notificationsStatus: PermissionStatus = .notDetermined
    
    private let eventStore = EKEventStore()
    
    private init() {
        refreshAll()
    }
    
    public func refreshAll() {
        checkCamera()
        checkCalendar()
        checkReminders()
        checkAccessibility()
        checkNotifications()
    }
    
    public func status(for kind: PermissionKind) -> PermissionStatus {
        switch kind {
        case .camera: return cameraStatus
        case .calendar: return calendarStatus
        case .reminders: return remindersStatus
        case .accessibility: return accessibilityStatus
        case .appleEvents: return .authorized // Handled dynamically via AppleScript prompt
        case .notifications: return notificationsStatus
        }
    }
    
    public func checkCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraStatus = .authorized
        case .denied: cameraStatus = .denied
        case .restricted: cameraStatus = .restricted
        case .notDetermined: cameraStatus = .notDetermined
        @unknown default: cameraStatus = .notDetermined
        }
    }
    
    public func requestCameraAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        checkCamera()
        return granted
    }
    
    public func checkCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess: calendarStatus = .authorized
        case .denied: calendarStatus = .denied
        case .restricted: calendarStatus = .restricted
        case .notDetermined: calendarStatus = .notDetermined
        default: calendarStatus = .notDetermined
        }
    }
    
    public func requestCalendarAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                checkCalendar()
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                checkCalendar()
                return granted
            }
        } catch {
            checkCalendar()
            return false
        }
    }
    
    public func checkReminders() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized, .fullAccess: remindersStatus = .authorized
        case .denied: remindersStatus = .denied
        case .restricted: remindersStatus = .restricted
        case .notDetermined: remindersStatus = .notDetermined
        default: remindersStatus = .notDetermined
        }
    }
    
    public func requestRemindersAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToReminders()
                checkReminders()
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .reminder)
                checkReminders()
                return granted
            }
        } catch {
            checkReminders()
            return false
        }
    }
    
    public func checkAccessibility() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": false]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        accessibilityStatus = isTrusted ? .authorized : .denied
    }
    
    public func requestAccessibility() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        checkAccessibility()
    }
    
    public func checkNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let authStatus = settings.authorizationStatus
            Task { @MainActor [weak self] in
                switch authStatus {
                case .authorized, .provisional: self?.notificationsStatus = .authorized
                case .denied: self?.notificationsStatus = .denied
                case .notDetermined: self?.notificationsStatus = .notDetermined
                default: self?.notificationsStatus = .notDetermined
                }
            }
        }
    }
    
    public func requestNotifications() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            checkNotifications()
            return granted
        } catch {
            return false
        }
    }
    
    public func openSettings(for kind: PermissionKind) {
        if let url = kind.settingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}
