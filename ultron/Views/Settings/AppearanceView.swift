import SwiftUI

struct AppearanceView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerNote
                    themeGrid
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(theme.preferredColorScheme, for: .navigationBar)
    }

    private var headerNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.accentGold)
            Text("Choose a visual theme for Compass. Changes apply instantly across the entire app.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(16)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private var themeGrid: some View {
        VStack(spacing: 12) {
            ForEach(AppThemeVariant.allCases) { variant in
                ThemeCard(variant: variant, isActive: theme.activeTheme == variant) {
                    theme.activeTheme = variant
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct ThemeCard: View {
    let variant: AppThemeVariant
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Color preview swatch
                RoundedRectangle(cornerRadius: 12)
                    .fill(variant.previewBg)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: variant.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(variant == .softCream ? Color(hex: "#C9963A") : Color(hex: "#F0B429"))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(variant.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(variant.description)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isActive ? AppTheme.Colors.accentGold : AppTheme.Colors.borderSubtle, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isActive {
                        Circle()
                            .fill(AppTheme.Colors.accentGold)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.Colors.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isActive ? AppTheme.Colors.accentGold.opacity(0.5) : AppTheme.Colors.borderSubtle, lineWidth: isActive ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}
