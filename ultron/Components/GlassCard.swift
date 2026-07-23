import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}
