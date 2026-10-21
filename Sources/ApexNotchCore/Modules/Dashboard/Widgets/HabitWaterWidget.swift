import SwiftUI

@MainActor
public final class HabitWaterManager: ObservableObject {
    public static let shared = HabitWaterManager()
    
    @Published public var waterGlasses: Int = 0 { didSet { save() } }
    @Published public var waterGoal: Int = 8
    @Published public var habitName: String = "Exercise / Reading"
    @Published public var habitCount: Int = 0 { didSet { save() } }
    
    private let defaults = UserDefaults.standard
    
    private init() {
        self.waterGlasses = defaults.integer(forKey: "waterGlasses")
        self.waterGoal = defaults.object(forKey: "waterGoal") as? Int ?? 8
        self.habitCount = defaults.integer(forKey: "habitCount")
        self.habitName = defaults.string(forKey: "habitName") ?? "Pushups / Habit"
    }
    
    public func addWater() {
        waterGlasses += 1
    }
    
    public func removeWater() {
        if waterGlasses > 0 { waterGlasses -= 1 }
    }
    
    public func addHabit() {
        habitCount += 1
    }
    
    public func resetDaily() {
        waterGlasses = 0
        habitCount = 0
    }
    
    private func save() {
        defaults.set(waterGlasses, forKey: "waterGlasses")
        defaults.set(waterGoal, forKey: "waterGoal")
        defaults.set(habitCount, forKey: "habitCount")
        defaults.set(habitName, forKey: "habitName")
    }
}

public struct HabitWaterWidget: View {
    @ObservedObject private var manager = HabitWaterManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // Water Tracker
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(NotchDesign.accentCyan)
                        .font(.system(size: 11))
                    Text("Hydration")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(manager.waterGlasses)/\(manager.waterGoal)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(NotchDesign.accentCyan)
                }
                
                GeometryReader { geo in
                    let ratio = min(max(Double(manager.waterGlasses) / Double(manager.waterGoal), 0.0), 1.0)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                        Capsule().fill(NotchDesign.accentCyan).frame(width: geo.size.width * ratio, height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack(spacing: 8) {
                    Button(action: { manager.addWater() }) {
                        Label("Drink", systemImage: "plus")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(NotchDesign.accentCyan)
                    
                    if manager.waterGlasses > 0 {
                        Button(action: { manager.removeWater() }) {
                            Image(systemName: "minus")
                                .font(.system(size: 8))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(NotchDesign.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Habit Tracker
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(NotchDesign.accentAmber)
                        .font(.system(size: 11))
                    Text("Daily Tally")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(manager.habitCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(NotchDesign.accentAmber)
                }
                
                Text(manager.habitName)
                    .font(.system(size: 9))
                    .foregroundColor(NotchDesign.textSecondary)
                    .lineLimit(1)
                
                Button(action: { manager.addHabit() }) {
                    Label("Log Count", systemImage: "plus.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(NotchDesign.accentAmber)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
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
