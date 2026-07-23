import SwiftUI

enum AppTheme {
    // MARK: - Colors (delegates to active theme)
    enum Colors {
        static var bgPrimary:     Color { ThemeManager.shared.colors.bgPrimary }
        static var bgSurface:     Color { ThemeManager.shared.colors.bgSurface }
        static var bgElevated:    Color { ThemeManager.shared.colors.bgElevated }
        static var accentGold:    Color { ThemeManager.shared.colors.accentGold }
        static var accentTeal:    Color { ThemeManager.shared.colors.accentTeal }
        static var accentRose:    Color { ThemeManager.shared.colors.accentRose }
        static var textPrimary:   Color { ThemeManager.shared.colors.textPrimary }
        static var textSecondary: Color { ThemeManager.shared.colors.textSecondary }
        static var textTertiary:  Color { ThemeManager.shared.colors.textTertiary }
        static var borderSubtle:  Color { ThemeManager.shared.colors.borderSubtle }
        static var cardBg:        Color { ThemeManager.shared.colors.cardBg }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 16
        static let l:  CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radius
    enum Radius {
        static let small:  CGFloat = 8
        static let medium: CGFloat = 12
        static let large:  CGFloat = 16
        static let xlarge: CGFloat = 20
        static let full:   CGFloat = 100
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
