import SwiftUI

struct BarGraph: View {
    let values: [Double]
    let labels: [String]
    var accentColor: Color = AppTheme.Colors.accentGold
    @State private var appeared = false

    var maxValue: Double { values.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { i, value in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(
                            height: appeared
                                ? CGFloat(value / maxValue) * 80
                                : 2
                        )
                        .animation(.easeInOut(duration: 0.8).delay(Double(i) * 0.06), value: appeared)

                    if i < labels.count {
                        Text(labels[i])
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 100)
        .onAppear { appeared = true }
    }
}
