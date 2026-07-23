import SwiftUI
import Combine

// MARK: - Variants

enum AppThemeVariant: String, CaseIterable, Identifiable {
    case dark      = "Dark"
    case softCream = "Soft Cream"
    case midnight  = "Midnight"
    case oledBlack = "OLED Black"
    case system    = "System"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dark:      return "moon.stars.fill"
        case .softCream: return "book.closed.fill"
        case .midnight:  return "sparkles"
        case .oledBlack: return "circle.fill"
        case .system:    return "iphone"
        }
    }

    var description: String {
        switch self {
        case .dark:      return "Easy on the eyes"
        case .softCream: return "Warm journal paper"
        case .midnight:  return "Deep focus mode"
        case .oledBlack: return "Pure black display"
        case .system:    return "Follows iOS setting"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark, .midnight, .oledBlack: return .dark
        case .softCream:                   return .light
        case .system:                      return nil
        }
    }

    var previewBg: Color {
        switch self {
        case .dark:      return Color(hex: "#0D0F1A")
        case .softCream: return Color(hex: "#F6F2EA")
        case .midnight:  return Color(hex: "#080812")
        case .oledBlack: return Color.black
        case .system:    return Color(UIColor.systemBackground)
        }
    }

    var colors: ThemeColors {
        switch self {
        case .dark:
            return ThemeColors(
                bgPrimary:     Color(hex: "#0D0F1A"),
                bgSurface:     Color(hex: "#161825"),
                bgElevated:    Color(hex: "#1E2133"),
                accentGold:    Color(hex: "#F0B429"),
                accentTeal:    Color(hex: "#4FC3C3"),
                accentRose:    Color(hex: "#E8758A"),
                textPrimary:   .white,
                textSecondary: Color(hex: "#A8AABC"),
                textTertiary:  Color(hex: "#666880"),
                borderSubtle:  Color(hex: "#2A2D42"),
                cardBg:        Color(hex: "#1A1D2E")
            )
        case .softCream:
            return ThemeColors(
                bgPrimary:     Color(hex: "#F6F2EA"),
                bgSurface:     Color(hex: "#EDE8DC"),
                bgElevated:    Color(hex: "#FFFDF8"),
                accentGold:    Color(hex: "#C9963A"),
                accentTeal:    Color(hex: "#3A8A8A"),
                accentRose:    Color(hex: "#B85A6A"),
                textPrimary:   Color(hex: "#1A1612"),
                textSecondary: Color(hex: "#6B5D4F"),
                textTertiary:  Color(hex: "#9A8E83"),
                borderSubtle:  Color(hex: "#D8D0C4"),
                cardBg:        Color(hex: "#FFFDF8")
            )
        case .midnight:
            return ThemeColors(
                bgPrimary:     Color(hex: "#080812"),
                bgSurface:     Color(hex: "#0E0E1E"),
                bgElevated:    Color(hex: "#14142A"),
                accentGold:    Color(hex: "#E8B84B"),
                accentTeal:    Color(hex: "#56D9D9"),
                accentRose:    Color(hex: "#F07A8E"),
                textPrimary:   Color(hex: "#E8E8F0"),
                textSecondary: Color(hex: "#8888AA"),
                textTertiary:  Color(hex: "#555570"),
                borderSubtle:  Color(hex: "#1A1A30"),
                cardBg:        Color(hex: "#10102A")
            )
        case .oledBlack:
            return ThemeColors(
                bgPrimary:     .black,
                bgSurface:     Color(hex: "#080808"),
                bgElevated:    Color(hex: "#111111"),
                accentGold:    Color(hex: "#F0B429"),
                accentTeal:    Color(hex: "#4FC3C3"),
                accentRose:    Color(hex: "#E8758A"),
                textPrimary:   .white,
                textSecondary: Color(hex: "#999999"),
                textTertiary:  Color(hex: "#555555"),
                borderSubtle:  Color(hex: "#1A1A1A"),
                cardBg:        Color(hex: "#0A0A0A")
            )
        case .system:
            return ThemeColors(
                bgPrimary:     Color(UIColor.systemBackground),
                bgSurface:     Color(UIColor.secondarySystemBackground),
                bgElevated:    Color(UIColor.tertiarySystemBackground),
                accentGold:    Color(hex: "#F0B429"),
                accentTeal:    Color(hex: "#4FC3C3"),
                accentRose:    Color(hex: "#E8758A"),
                textPrimary:   Color(UIColor.label),
                textSecondary: Color(UIColor.secondaryLabel),
                textTertiary:  Color(UIColor.tertiaryLabel),
                borderSubtle:  Color(UIColor.separator),
                cardBg:        Color(UIColor.secondarySystemBackground)
            )
        }
    }
}

// MARK: - Color Bundle

struct ThemeColors {
    let bgPrimary:     Color
    let bgSurface:     Color
    let bgElevated:    Color
    let accentGold:    Color
    let accentTeal:    Color
    let accentRose:    Color
    let textPrimary:   Color
    let textSecondary: Color
    let textTertiary:  Color
    let borderSubtle:  Color
    let cardBg:        Color
}

// MARK: - Manager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private let key = "compass_theme_v1"

    @Published var activeTheme: AppThemeVariant {
        didSet { UserDefaults.standard.set(activeTheme.rawValue, forKey: key) }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "compass_theme_v1") ?? ""
        activeTheme = AppThemeVariant(rawValue: saved) ?? .dark
    }

    var colors: ThemeColors { activeTheme.colors }
    var preferredColorScheme: ColorScheme? { activeTheme.preferredColorScheme }
}
