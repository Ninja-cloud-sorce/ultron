import SwiftUI

struct ProgressDotsView: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i == current ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary.opacity(0.5))
                    .frame(width: i == current ? 24 : 8, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}
