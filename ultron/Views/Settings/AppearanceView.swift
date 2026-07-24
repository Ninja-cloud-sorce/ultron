import SwiftUI

struct AppearancePickerSheet: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(AppTheme.Colors.borderSubtle)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appearance")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text("Changes apply instantly across the app")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.bgElevated)
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Theme list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(AppThemeVariant.allCases) { variant in
                            ThemeCard(variant: variant, isActive: theme.activeTheme == variant) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    theme.activeTheme = variant
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(AppTheme.Colors.bgPrimary)
    }
}

private struct ThemeCard: View {
    let variant: AppThemeVariant
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Color swatch
                RoundedRectangle(cornerRadius: 12)
                    .fill(variant.previewBg)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: variant.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(variant == .softCream ? Color(hex: "#C9963A") : Color(hex: "#F0B429"))
                    )
                    .shadow(color: variant.previewBg.opacity(0.5), radius: isActive ? 8 : 0, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(variant.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(variant.description)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isActive ? AppTheme.Colors.accentGold : AppTheme.Colors.borderSubtle, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isActive {
                        Circle()
                            .fill(AppTheme.Colors.accentGold)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isActive)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.Colors.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isActive ? AppTheme.Colors.accentGold.opacity(0.55) : AppTheme.Colors.borderSubtle,
                                lineWidth: isActive ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isActive ? 1.0 : 0.995)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(.plain)
    }
}
