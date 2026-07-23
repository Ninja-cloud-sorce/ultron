import SwiftUI

// MARK: - Data Model

struct AlignmentDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let score: Int          // 0–100
    let reason: String
    let direction: Direction

    var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }

    var scoreColor: Color {
        if score >= 90 { return Color(hex: "#7BC67E") }
        if score >= 70 { return Color(hex: "#F0B429") }
        if score >= 50 { return Color(hex: "#F5924E") }
        return Color(hex: "#E8758A")
    }

    var alignmentLabel: String {
        if score >= 90 { return "Strongly Aligned" }
        if score >= 70 { return "Well Aligned" }
        if score >= 50 { return "Partially Aligned" }
        return "Needs Focus"
    }

    var directionSymbol: String {
        switch direction {
        case .toward:  return "↑"
        case .neutral: return "→"
        case .away:    return "↓"
        }
    }

    var yFraction: CGFloat {
        CGFloat(max(0, min(100, score))) / 100.0
    }
}

// MARK: - Line Shape (supports trim-based draw animation)

private struct AlignmentLinePath: Shape {
    let points: [AlignmentDataPoint]
    let originX: CGFloat
    let stepX: CGFloat
    let chartH: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count > 1 else { return p }
        for (i, pt) in points.enumerated() {
            let x = originX + CGFloat(i) * stepX
            let y = chartH - pt.yFraction * chartH
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                let prev = points[i - 1]
                let px   = originX + CGFloat(i - 1) * stepX
                let py   = chartH - prev.yFraction * chartH
                let midX = (px + x) / 2
                p.addCurve(
                    to:       CGPoint(x: x, y: y),
                    control1: CGPoint(x: midX, y: py),
                    control2: CGPoint(x: midX, y: y)
                )
            }
        }
        return p
    }
}

// MARK: - Tooltip

private struct AlignmentTooltip: View {
    let point: AlignmentDataPoint
    let dotX: CGFloat
    let dotY: CGFloat
    let containerW: CGFloat

    var body: some View {
        let tipW: CGFloat = 158
        let cx = min(max(dotX, tipW / 2 + 4), containerW - tipW / 2 - 4)
        let ty = dotY > 52 ? dotY - 72 : dotY + 66

        VStack(alignment: .leading, spacing: 3) {
            Text(point.date.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.50))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(point.score)%")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(point.scoreColor)
                Text(point.alignmentLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
            }
            if !point.reason.isEmpty {
                Text(point.reason)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: tipW, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "#151929"))
                .shadow(color: .black.opacity(0.45), radius: 10, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
        .position(x: cx, y: ty)
        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .bottom)))
    }
}

// MARK: - AlignmentChartView

struct AlignmentChartView: View {
    let points: [AlignmentDataPoint]

    @State private var appeared      = false
    @State private var selectedIndex: Int? = nil

    private let chartH : CGFloat = 82
    private let symbolY: CGFloat = 100   // chartH + 18
    private let labelY : CGFloat = 124   // chartH + 42
    private let totalH : CGFloat = 160

    var body: some View {
        if points.count < 2 {
            Text("Write a few reflections to see your weekly alignment.")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.38))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .frame(height: totalH)
                .frame(maxWidth: .infinity)
        } else {
            chartCanvas
        }
    }

    private var chartCanvas: some View {
        GeometryReader { geo in
            let w       = geo.size.width
            let count   = points.count
            let stepX   = (w - 20) / CGFloat(count - 1)
            let originX : CGFloat = 10

            ZStack(alignment: .topLeading) {
                // Subtle grid lines
                ForEach([CGFloat(0.25), 0.5, 0.75], id: \.self) { f in
                    Path { p in
                        p.move(to:    CGPoint(x: 0, y: chartH - f * chartH))
                        p.addLine(to: CGPoint(x: w, y: chartH - f * chartH))
                    }
                    .stroke(Color.white.opacity(0.055),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                }

                // Bezier line — draws left to right via trim animation
                AlignmentLinePath(points: points, originX: originX, stepX: stepX, chartH: chartH)
                    .trim(from: 0, to: appeared ? 1.0 : 0.0)
                    .stroke(
                        Color(hex: "#9B8BE4").opacity(0.65),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .animation(.easeInOut(duration: 0.9), value: appeared)

                // Per-point: halo, dot, direction symbol, day label
                ForEach(points.indices, id: \.self) { i in
                    let pt    = points[i]
                    let x     = originX + CGFloat(i) * stepX
                    let y     = chartH - pt.yFraction * chartH
                    let col   = pt.scoreColor
                    let isSel = selectedIndex == i

                    // Glow halo
                    Circle()
                        .fill(col.opacity(0.22))
                        .frame(width: 20, height: 20)
                        .position(x: x, y: y)
                        .opacity(appeared ? 1 : 0)

                    // Dot
                    Circle()
                        .fill(col.opacity(isSel ? 1.0 : 0.85))
                        .frame(width: isSel ? 12 : 9, height: isSel ? 12 : 9)
                        .shadow(color: col.opacity(0.65), radius: isSel ? 9 : 5)
                        .position(x: x, y: y)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.38, dampingFraction: 0.62).delay(Double(i) * 0.09),
                            value: appeared
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSel)

                    // Direction symbol (↑ → ↓) colored by score
                    Text(pt.directionSymbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(col.opacity(0.8))
                        .position(x: x, y: symbolY)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.55), value: appeared)

                    // Single-letter day label
                    Text(pt.dayLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.38))
                        .position(x: x, y: labelY)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.55), value: appeared)
                }

                // Tap tooltip
                if let idx = selectedIndex {
                    AlignmentTooltip(
                        point:      points[idx],
                        dotX:       originX + CGFloat(idx) * stepX,
                        dotY:       chartH - points[idx].yFraction * chartH,
                        containerW: w
                    )
                    .zIndex(10)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let raw = (v.location.x - originX) / stepX
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            selectedIndex = max(0, min(points.count - 1, Int(raw.rounded())))
                        }
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                            withAnimation(.easeOut(duration: 0.25)) { selectedIndex = nil }
                        }
                    }
            )
            .onAppear {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { appeared = true }
            }
        }
        .frame(height: totalH)
    }
}
