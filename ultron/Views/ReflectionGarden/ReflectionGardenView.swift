import SwiftUI

struct ReflectionGardenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var growIn = false
    @State private var contentVisible = false

    private let gratitudeCount = 23

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header + flower illustration ──────────────────────
                    ZStack(alignment: .bottom) {
                        // Ambient glow behind flower
                        RadialGradient(
                            colors: [Color(hex: "#86EFAC").opacity(0.18), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 130
                        )
                        .frame(height: 260)

                        // flower png asset — transparent PNG illustration
                        Image("flower png")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160)
                            .scaleEffect(growIn ? 1.0 : 0.35)
                            .opacity(growIn ? 1.0 : 0)
                            .animation(.spring(response: 0.85, dampingFraction: 0.6), value: growIn)
                            .offset(y: -16)

                        VStack(spacing: 5) {
                            Text("Reflection Garden")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Nurture what matters")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color.white.opacity(0.55))
                                .tracking(0.3)
                        }
                    }
                    .frame(height: 290)
                    .padding(.top, 68)

                    // ── Content cards ─────────────────────────────────────
                    VStack(spacing: AppTheme.Spacing.l) {

                        // Mood This Week
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                HStack {
                                    Text("Mood This Week")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "waveform.path.ecg")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.white.opacity(0.35))
                                }
                                MoodLineChart(records: MoodRecord.weekSamples)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Gratitude Tracker
                        GlassCard {
                            HStack(spacing: AppTheme.Spacing.l) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Gratitude Tracker")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("entries this month")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.45))
                                }

                                Spacer()

                                HStack(alignment: .bottom, spacing: 4) {
                                    Text("\(gratitudeCount)")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("logged")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.45))
                                        .padding(.bottom, 6)
                                }

                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#86EFAC").opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#86EFAC"))
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: contentVisible)

                        Spacer(minLength: 120)
                    }
                    .padding(.top, AppTheme.Spacing.l)
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: contentVisible)
                }
            }

            // ── Back button ───────────────────────────────────────────────
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(AppTheme.Colors.bgElevated)
                            .clipShape(Circle())
                    }
                    .padding(.leading, AppTheme.Spacing.m)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .hideNavigationBar()
        .onAppear {
            growIn = false
            contentVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { growIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { contentVisible = true }
        }
    }
}
