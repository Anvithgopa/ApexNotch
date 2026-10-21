import SwiftUI

public enum PetCharacterType: String, CaseIterable, Identifiable, Codable, Sendable {
    case none = "None"
    case cat = "Cat (Whiskers)"
    case dog = "Dog (Buddy)"
    case fox = "Fox (Rusty)"
    case duck = "Duck (Quackers)"
    case frog = "Frog (Hoppy)"
    case robot = "Robot (Byte)"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .none: return ""
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .fox: return "🦊"
        case .duck: return "🦆"
        case .frog: return "🐸"
        case .robot: return "🤖"
        }
    }
    
    public var title: String {
        switch self {
        case .none: return "Disabled"
        case .cat: return "Whiskers the Cat"
        case .dog: return "Buddy the Dog"
        case .fox: return "Rusty the Fox"
        case .duck: return "Quackers the Duck"
        case .frog: return "Hoppy the Frog"
        case .robot: return "Byte the Robot"
        }
    }
}

public enum PetState: Equatable, Sendable {
    case sleeping       // CPU < 15% (Idle, energy saver)
    case walking        // CPU 15% - 35% (Light work)
    case trotting       // CPU 35% - 60% (Moderate load)
    case sprinting      // CPU > 60% (High performance / Turbo)
    
    public var label: String {
        switch self {
        case .sleeping: return "Sleeping (Idle)"
        case .walking: return "Walking (Normal)"
        case .trotting: return "Jogging (Moderate Load)"
        case .sprinting: return "Sprint Turbo! (High CPU)"
        }
    }
}
