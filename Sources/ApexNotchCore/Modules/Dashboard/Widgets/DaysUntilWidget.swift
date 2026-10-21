import SwiftUI

public struct DaysUntilWidget: View {
    @NotchState private var targetTitle: String = "Project Milestone"
    @NotchState private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @NotchState private var isEditing: Bool = false
    
    public init() {}
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        return max(components.day ?? 0, 0)
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            HStack {
                Label("Countdown", systemImage: "hourglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentPurple)
                
                Spacer()
                
                Button(action: { isEditing.toggle() }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundColor(NotchDesign.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            if isEditing {
                VStack(spacing: 4) {
                    TextField("Event Name", text: $targetTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10))
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                    
                    DatePicker("", selection: $targetDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(daysRemaining)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(NotchDesign.textPrimary)
                    
                    Text(daysRemaining == 1 ? "day left" : "days left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NotchDesign.accentPurple)
                }
                
                Text(targetTitle)
                    .font(.system(size: 10))
                    .foregroundColor(NotchDesign.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
}
