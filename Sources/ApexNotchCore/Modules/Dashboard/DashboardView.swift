import SwiftUI

public struct DashboardView: View {
    @ObservedObject private var registry = WidgetRegistry.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 10) {
                // Top Row: Clock & System Gauges
                HStack(alignment: .top, spacing: 10) {
                    if registry.isWidgetEnabled("clock") {
                        ClockWidget()
                    }
                    if registry.isWidgetEnabled("system") {
                        SystemMonitorWidget()
                    }
                }
                
                // Network & Focus row
                HStack(alignment: .top, spacing: 10) {
                    if registry.isWidgetEnabled("network") {
                        NetworkSpeedWidget()
                    }
                    if registry.isWidgetEnabled("pomodoro") {
                        PomodoroWidget()
                    }
                }
                
                // Calendar / Tasks & Scratchpad
                HStack(alignment: .top, spacing: 10) {
                    if registry.isWidgetEnabled("calendar") {
                        CalendarReminderWidget()
                    }
                    if registry.isWidgetEnabled("notes") {
                        QuickNotesWidget()
                    }
                }
                
                // Stopwatch & Hydration
                HStack(alignment: .top, spacing: 10) {
                    if registry.isWidgetEnabled("stopwatch") {
                        StopwatchWidget()
                    }
                    if registry.isWidgetEnabled("hydration") {
                        HabitWaterWidget()
                    }
                }
                
                // Bookmarks & Countdown
                HStack(alignment: .top, spacing: 10) {
                    if registry.isWidgetEnabled("bookmarks") {
                        BookmarksWidget()
                    }
                    if registry.isWidgetEnabled("countdown") {
                        DaysUntilWidget()
                    }
                }
                
                // App Shortcuts Dock
                if registry.isWidgetEnabled("apps") {
                    AppShortcutsWidget()
                }
                
                // Quick Calculator & Unit Converter
                if registry.isWidgetEnabled("calculator") {
                    QuickCalculatorWidget()
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NotchDesign.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
}
