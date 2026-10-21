import SwiftUI

/// Design tokens and layout constants for ApexNotch
public enum NotchDesign {
    public static let compactHeightDefault: CGFloat = 32.0
    public static let compactWidthDefault: CGFloat = 200.0
    public static let expandedWidthDefault: CGFloat = 680.0
    public static let expandedHeightDefault: CGFloat = 440.0
    public static let cornerRadiusCompact: CGFloat = 16.0
    public static let cornerRadiusExpanded: CGFloat = 28.0
    
    // Animation curves
    public static let expansionSpring = Animation.spring(response: 0.38, dampingFraction: 0.82, blendDuration: 0.1)
    public static let collapseSpring = Animation.spring(response: 0.32, dampingFraction: 0.86, blendDuration: 0.1)
    public static let tabSpring = Animation.spring(response: 0.28, dampingFraction: 0.85)
    
    // Colors
    public static let deepBlack = Color(red: 0.04, green: 0.04, blue: 0.05)
    public static let surfaceDark = Color(red: 0.09, green: 0.09, blue: 0.11)
    public static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.17)
    public static let borderSubtle = Color.white.opacity(0.12)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textTertiary = Color.white.opacity(0.40)
    
    // Accent colors
    public static let accentCyan = Color(red: 0.22, green: 0.78, blue: 0.99)
    public static let accentPurple = Color(red: 0.68, green: 0.38, blue: 0.99)
    public static let accentGreen = Color(red: 0.24, green: 0.86, blue: 0.52)
    public static let accentAmber = Color(red: 1.0, green: 0.65, blue: 0.15)
    public static let accentRed = Color(red: 1.0, green: 0.32, blue: 0.36)
}

/// Metadata and developer credits for ApexNotch
public enum ApexNotchMeta {
    public static let appName = "ApexNotch"
    public static let version = "1.0.0"
    public static let author = "Anvith Gopa"
    public static let githubUsername = "Anvithgopa"
    public static let githubRepoURL = URL(string: "https://github.com/Anvithgopa/ApexNotch")!
    public static let githubProfileURL = URL(string: "https://github.com/Anvithgopa")!
    public static let supportMeURL = URL(string: "https://payments.cashfree.com/forms/supportMe")!
    public static let issuesURL = URL(string: "https://github.com/Anvithgopa/ApexNotch/issues")!
    public static let releasesURL = URL(string: "https://github.com/Anvithgopa/ApexNotch/releases/latest")!
}

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat = 12
    var background: Color = NotchDesign.surfaceDark
    var border: Color = NotchDesign.borderSubtle
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(border, lineWidth: 1)
                    )
            )
    }
}

public extension View {
    func glassCard(
        cornerRadius: CGFloat = 14,
        padding: CGFloat = 12,
        background: Color = NotchDesign.surfaceDark,
        border: Color = NotchDesign.borderSubtle
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding, background: background, border: border))
    }
}
