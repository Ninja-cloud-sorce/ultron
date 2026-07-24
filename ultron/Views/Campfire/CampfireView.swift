import SwiftUI

// MARK: - Campfire View

struct CampfireView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CampfireHeader(onBack: { dismiss() })
                    CampfireHeroImage()

                    VStack(spacing: 14) {
                        MoodChartCard(records: journalVM.moodHistory)
                        StreakCard(streak: journalVM.currentStreak)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Spacer(minLength: 120)
                }
            }
        }
        .hideNavigationBar()
    }
}

// MARK: - Header

struct CampfireHeader: View {
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Back button — sits above the title, no overlap
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Campfire")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("A place for honest reflection")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 14)
    }
}

// MARK: - Hero Image

struct CampfireHeroImage: View {
    var body: some View {
        Image("campire")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .clipped()
            .overlay(
                // Top: subtle dark for header legibility
                LinearGradient(
                    colors: [Color.black.opacity(0.18), .clear],
                    startPoint: .top, endPoint: .center
                )
            )
            .overlay(
                // Bottom: smooth fade into dark bg
                LinearGradient(
                    colors: [.clear, AppTheme.Colors.bgPrimary.opacity(0.55), AppTheme.Colors.bgPrimary],
                    startPoint: .center, endPoint: .bottom
                )
            )
    }
}

// MARK: - Mood Chart Card

struct MoodChartCard: View {
    let records: [MoodRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood This Week")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            WeeklyMoodChart(records: records)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.Colors.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
        )
    }
}

// MARK: - Weekly Mood Chart

struct WeeklyMoodChart: View {
    let records: [MoodRecord]
    @State private var appeared = false

    private func yFraction(_ mood: Mood) -> CGFloat {
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
        let totalHeight: CGFloat = 160
        let chartAreaH: CGFloat  = 82
        let emojiY: CGFloat      = chartAreaH + 18
        let labelY: CGFloat      = chartAreaH + 42

        GeometryReader { geo in
            let w       = geo.size.width
            let count   = records.count
            let stepX   = count > 1 ? (w - 20) / CGFloat(count - 1) : 0
            let originX : CGFloat = 10

            ZStack(alignment: .topLeading) {
                ForEach([CGFloat(0.25), 0.5, 0.75], id: \.self) { fraction in
                    let y = chartAreaH - fraction * chartAreaH
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.055),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                }

                if records.count > 1 {
                    Path { path in
                        for (i, r) in records.enumerated() {
                            let x = originX + CGFloat(i) * stepX
                            let y = chartAreaH - yFraction(r.mood) * chartAreaH
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let prev = records[i - 1]
                                let px   = originX + CGFloat(i - 1) * stepX
                                let py   = chartAreaH - yFraction(prev.mood) * chartAreaH
                                let midX = (px + x) / 2
                                path.addCurve(
                                    to:       CGPoint(x: x, y: y),
                                    control1: CGPoint(x: midX, y: py),
                                    control2: CGPoint(x: midX, y: y)
                                )
                            }
                        }
                    }
                    .stroke(
                        Color(hex: "#4FC3C3").opacity(0.7),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.55), value: appeared)
                }

                ForEach(records.indices, id: \.self) { i in
                    let r = records[i]
                    let x = originX + CGFloat(i) * stepX
                    let y = chartAreaH - yFraction(r.mood) * chartAreaH

                    Circle()
                        .fill(r.mood.color.opacity(0.22))
                        .frame(width: 20, height: 20)
                        .position(x: x, y: y)
                        .opacity(appeared ? 1 : 0)

                    Circle()
                        .fill(r.mood.color)
                        .frame(width: 9, height: 9)
                        .shadow(color: r.mood.color.opacity(0.65), radius: 5)
                        .position(x: x, y: y)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.38, dampingFraction: 0.62)
                                .delay(Double(i) * 0.07),
                            value: appeared
                        )

                    Text(r.mood.emoji)
                        .font(.system(size: 17))
                        .position(x: x, y: emojiY)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: appeared)

                    Text(r.dayLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.38))
                        .position(x: x, y: labelY)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: appeared)
                }
            }
            .onAppear {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { appeared = true }
            }
        }
        .frame(height: totalHeight)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    @State private var glowPulse = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your Streak")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                Text("\(streak)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("day streak")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()

            // Flame circle with glow
            ZStack {
                Circle()
                    .fill(Color(hex: "#F0B429").opacity(glowPulse ? 0.16 : 0.05))
                    .frame(width: 68, height: 68)
                    .blur(radius: 8)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                Circle()
                    .fill(Color(hex: "#1C1810"))
                    .frame(width: 56, height: 56)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#F0B429"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.Colors.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
        )
        .onAppear { glowPulse = true }
    }
}
