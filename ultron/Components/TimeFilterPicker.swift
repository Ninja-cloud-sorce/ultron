import SwiftUI

struct TimeFilterPicker: View {
    let options: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = option }
                }) {
                    Text(option)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selected == option ? .black : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selected == option ? AppTheme.Colors.accentGold : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(AppTheme.Colors.bgElevated)
                .overlay(Capsule().stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        )
    }
}
