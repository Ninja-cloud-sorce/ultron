import SwiftUI

struct MoodLineChart: View {
    let records: [MoodRecord]
    @State private var appeared = false

    private func moodY(_ mood: Mood) -> Double {
        switch mood {
        case .radiant:  return 0.92
        case .hopeful:  return 0.78
        case .grateful: return 0.68
        case .calm:     return 0.58
        case .neutral:  return 0.44
        case .anxious:  return 0.28
        case .low:      return 0.12
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let chartH = geo.size.height - 24  // 24pt reserved for day labels
            let count = records.count
            let stepX = count > 1 ? (w - 16) / CGFloat(count - 1) : 0
            let startX: CGFloat = 8

            ZStack(alignment: .topLeading) {
                // Connecting line
                if appeared {
                    Path { path in
                        for (i, r) in records.enumerated() {
                            let x = startX + CGFloat(i) * stepX
                            let y = chartH - CGFloat(moodY(r.mood)) * chartH
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else       { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .transition(.opacity)
                }

                // Dots + labels
                ForEach(records.indices, id: \.self) { i in
                    let r = records[i]
                    let x = startX + CGFloat(i) * stepX
                    let y = chartH - CGFloat(moodY(r.mood)) * chartH

                    // Glow halo
                    Circle()
                        .fill(r.mood.color.opacity(0.25))
                        .frame(width: 18, height: 18)
                        .position(x: x, y: y)
                        .opacity(appeared ? 1 : 0)

                    // Dot
                    Circle()
                        .fill(r.mood.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: r.mood.color.opacity(0.6), radius: 4)
                        .position(x: x, y: y)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.38, dampingFraction: 0.65)
                                .delay(Double(i) * 0.07),
                            value: appeared
                        )

                    // Day label
                    Text(r.dayLabel)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                        .position(x: x, y: chartH + 13)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.3), value: appeared)
                }
            }
            .onAppear {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.4)) { appeared = true }
                }
            }
        }
        .frame(height: 120)
    }
}
