import SwiftUI

public struct NotchPetView: View {
    @ObservedObject private var petManager = NotchPetManager.shared
    @ObservedObject private var prefs = UserPreferences.shared
    @ObservedObject private var sys = SystemStatsService.shared
    
    public init() {}
    
    public var body: some View {
        if prefs.petCharacter != .none {
            HStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    // Speed lines / dust trail when sprinting
                    if petManager.currentState == .sprinting {
                        HStack(spacing: 2) {
                            Text("💨")
                                .font(.system(size: 9))
                                .opacity(petManager.animationStep % 2 == 0 ? 0.9 : 0.3)
                                .offset(x: -8, y: 0)
                        }
                    }
                    
                    // Sleeping zZz indicators
                    if petManager.currentState == .sleeping {
                        Text("💤")
                            .font(.system(size: 8))
                            .offset(x: 8, y: -10 + petManager.currentBounce)
                            .transition(.opacity)
                    }
                    
                    // Heart on tap
                    if petManager.isExcited {
                        Text("❤️")
                            .font(.system(size: 9))
                            .offset(x: 0, y: -14)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Pet Sprite
                    Text(prefs.petCharacter.emoji)
                        .font(.system(size: 14))
                        .offset(y: petManager.currentBounce)
                        .rotationEffect(.degrees(rotationAngle))
                        .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                petManager.petTapped()
            }
            .help("\(prefs.petCharacter.title): \(petManager.currentState.label) • CPU: \(Int(sys.stats.cpuUsagePercent))%")
        }
    }
    
    private var rotationAngle: Double {
        switch petManager.currentState {
        case .sleeping:
            return 8.0
        case .walking:
            return petManager.animationStep % 2 == 0 ? -4.0 : 4.0
        case .trotting:
            return petManager.animationStep % 2 == 0 ? -7.0 : 7.0
        case .sprinting:
            return petManager.animationStep % 2 == 0 ? -12.0 : 12.0
        }
    }
    
    private var isFlipped: Bool {
        // Subtle facing change when idle or trotting
        return false
    }
}
