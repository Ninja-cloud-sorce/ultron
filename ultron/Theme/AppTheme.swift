import SwiftUI

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let bgPrimary    = Color(hex: "#0D0F1A")
        static let bgSurface    = Color(hex: "#161825")
        static let bgElevated   = Color(hex: "#1E2133")
        static let accentGold   = Color(hex: "#F0B429")
        static let accentTeal   = Color(hex: "#4FC3C3")
        static let accentRose   = Color(hex: "#E8758A")
        static let textPrimary  = Color.white
        static let textSecondary = Color(hex: "#A8AABC")
        static let textTertiary = Color(hex: "#666880")
        static let borderSubtle = Color(hex: "#2A2D42")
        static let cardBg       = Color(hex: "#1A1D2E")
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
