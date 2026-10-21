import SwiftUI
import EventKit

public struct CalendarEventItem: Identifiable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let color: Color
}

public struct ReminderTaskItem: Identifiable {
    public let id: String
    public var title: String
    public var isCompleted: Bool
    public let priority: Int
}

@MainActor
public final class CalendarReminderManager: ObservableObject {
    public static let shared = CalendarReminderManager()
    
    @Published public private(set) var events: [CalendarEventItem] = []
    @Published public private(set) var reminders: [ReminderTaskItem] = []
    @Published public var newReminderTitle: String = ""
    
    private let eventStore = EKEventStore()
    
    private init() {
        refresh()
    }
    
    public func refresh() {
        let perm = PermissionManager.shared
        if perm.calendarStatus == .authorized {
            fetchEvents()
        }
        if perm.remindersStatus == .authorized {
            fetchReminders()
        }
    }
    
    public func fetchEvents() {
        let calendar = Calendar.current
        let start = Date()
        guard let end = calendar.date(byAdding: .day, value: 2, to: start) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        self.events = ekEvents.prefix(4).map { ek in
            CalendarEventItem(
                id: ek.eventIdentifier ?? UUID().uuidString,
                title: ek.title ?? "Untitled Event",
                startDate: ek.startDate,
                endDate: ek.endDate,
                isAllDay: ek.isAllDay,
                color: Color(cgColor: ek.calendar?.cgColor ?? CGColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0))
            )
        }
    }
    
    public func fetchReminders() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
            guard let ekReminders = ekReminders else { return }
            Task { @MainActor [weak self] in
                self?.reminders = ekReminders.prefix(6).map { rem in
                    ReminderTaskItem(
                        id: rem.calendarItemIdentifier,
                        title: rem.title ?? "Untitled Task",
                        isCompleted: rem.isCompleted,
                        priority: rem.priority
                    )
                }
            }
        }
    }
    
    public func toggleReminder(id: String) {
        guard let ek = eventStore.calendarItem(withIdentifier: id) as? EKReminder else { return }
        ek.isCompleted.toggle()
        try? eventStore.save(ek, commit: true)
        fetchReminders()
    }
    
    public func addReminder() {
        let title = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        try? eventStore.save(reminder, commit: true)
        newReminderTitle = ""
        fetchReminders()
        AppState.shared.showToast("Reminder added!")
    }
}

public struct CalendarReminderWidget: View {
    @ObservedObject private var manager = CalendarReminderManager.shared
    @ObservedObject private var perms = PermissionManager.shared
    @NotchState private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Button(action: { selectedTab = 0 }) {
                        Text("Events")
                            .font(.system(size: 11, weight: selectedTab == 0 ? .bold : .regular))
                            .foregroundColor(selectedTab == 0 ? NotchDesign.accentCyan : NotchDesign.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Text("•")
                        .foregroundColor(NotchDesign.textTertiary)
                    
                    Button(action: { selectedTab = 1 }) {
                        Text("Reminders")
                            .font(.system(size: 11, weight: selectedTab == 1 ? .bold : .regular))
                            .foregroundColor(selectedTab == 1 ? NotchDesign.accentCyan : NotchDesign.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: { manager.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(NotchDesign.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            if selectedTab == 0 {
                eventsContent
            } else {
                remindersContent
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var eventsContent: some View {
        if perms.calendarStatus != .authorized {
            permissionPrompt(title: "Calendar Access", icon: "calendar") {
                Task {
                    _ = await perms.requestCalendarAccess()
                    manager.fetchEvents()
                }
            }
        } else if manager.events.isEmpty {
            Text("No upcoming events in the next 48 hours.")
                .font(.system(size: 11))
                .foregroundColor(NotchDesign.textTertiary)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 6) {
                ForEach(manager.events) { event in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 6, height: 6)
                        
                        Text(event.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NotchDesign.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatEventTime(event))
                            .font(.system(size: 10))
                            .foregroundColor(NotchDesign.textSecondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var remindersContent: some View {
        if perms.remindersStatus != .authorized {
            permissionPrompt(title: "Reminders Access", icon: "checklist") {
                Task {
                    _ = await perms.requestRemindersAccess()
                    manager.fetchReminders()
                }
            }
        } else {
            VStack(spacing: 6) {
                // Quick add row
                HStack(spacing: 6) {
                    TextField("Add a new task...", text: $manager.newReminderTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .onSubmit { manager.addReminder() }
                    
                    if !manager.newReminderTitle.isEmpty {
                        Button(action: { manager.addReminder() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(NotchDesign.accentGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                
                if manager.reminders.isEmpty {
                    Text("All tasks completed! Great job.")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(manager.reminders) { rem in
                        HStack(spacing: 6) {
                            Button(action: { manager.toggleReminder(id: rem.id) }) {
                                Image(systemName: rem.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(rem.isCompleted ? NotchDesign.accentGreen : NotchDesign.textSecondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text(rem.title)
                                .font(.system(size: 11))
                                .foregroundColor(rem.isCompleted ? NotchDesign.textTertiary : NotchDesign.textPrimary)
                                .strikethrough(rem.isCompleted)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private func permissionPrompt(title: String, icon: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Text("Enable \(title) to display meetings and tasks in your notch.")
                .font(.system(size: 10))
                .foregroundColor(NotchDesign.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Authorize Access", action: action)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(NotchDesign.accentCyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
    
    private func formatEventTime(_ event: CalendarEventItem) -> String {
        if event.isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}
