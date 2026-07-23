import SwiftUI

/// Bottom sheet shown when the FAB is tapped.
struct CaptureSheet: View {
    let onWrite:   () -> Void
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppTheme.Colors.borderSubtle)
                .frame(width: 36, height: 4)
                .padding(.top, 14)

            Text("New Journal Entry")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.top, 18)

            HStack(spacing: AppTheme.Spacing.m) {
                CaptureOptionTile(icon: "pencil.and.scribble", title: "Write",
                                  subtitle: "Type your thoughts",      action: onWrite)
                CaptureOptionTile(icon: "doc.viewfinder",      title: "Capture",
                                  subtitle: "Scan handwritten notes",  action: onCapture)
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.top, AppTheme.Spacing.l)

            Spacer()
        }
        .background(AppTheme.Colors.bgSurface)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(AppTheme.Colors.bgSurface)
    }
}

private struct CaptureOptionTile: View {
    let icon: String; let title: String; let subtitle: String; let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.Colors.accentGold)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.Colors.accentGold.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.l)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
