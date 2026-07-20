import SwiftUI

struct GlowButton: View {
    let title: String
    var icon: String? = nil
    var isFullWidth: Bool = true
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle { case primary, secondary, ghost }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.s) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                Text(title).font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(labelColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, isFullWidth ? 0 : 28)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.full))
            .shadow(color: shadowColor, radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var labelColor: Color {
        switch style {
        case .primary:   return .black
        case .secondary: return AppTheme.Colors.accentGold
        case .ghost:     return AppTheme.Colors.textSecondary
        }
    }

    private var bgColor: Color {
        switch style {
        case .primary:   return AppTheme.Colors.accentGold
        case .secondary: return AppTheme.Colors.accentGold.opacity(0.15)
        case .ghost:     return Color.clear
        }
    }

    private var shadowColor: Color {
        style == .primary ? AppTheme.Colors.accentGold.opacity(0.45) : .clear
    }
}
