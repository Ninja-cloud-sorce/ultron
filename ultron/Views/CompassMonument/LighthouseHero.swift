import SwiftUI

struct LighthouseHero: View {
    let isActive: Bool
    let onTap: () -> Void

    // Must match LighthouseBeam.lampAnchor so the glow ring and beam share the same origin.
    // y = 0.62 → ≈ 260 pt from top of the 420 pt hero, giving the upward beam
    // a full 260 pt of night sky to shine through (within spec range of 260–340 pt).
    private let lampAnchor = UnitPoint(x: 0.5, y: 0.62)

    @State private var glowPulse = false
    @State private var hintPulse = false

    var body: some View {
        // GeometryReader pins the image to the exact screen width,
        // preventing scaledToFill from reporting an over-wide layout size.
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Monument image ─────────────────────────────────────────
                Image("Compass Monument")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.clear,
                                Color.clear,
                                AppTheme.Colors.bgPrimary.opacity(0.55),
                                AppTheme.Colors.bgPrimary,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // ── Star field ─────────────────────────────────────────────
                if isActive {
                    StarTwinkleLayer()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.opacity.animation(.easeIn(duration: 0.6)))
                }

                // ── Lighthouse beam overlay ────────────────────────────────
                // .clipped() keeps the rotating beam inside the hero frame so it
                // doesn't leak into the status bar or content below.
                if isActive {
                    LighthouseBeam(lampAnchor: lampAnchor)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .transition(.opacity.animation(.easeIn(duration: 0.5)))
                }

                // ── Ambient glow ring at lamp position ─────────────────────
                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(
                        isActive
                            ? (glowPulse ? 0.60 : 0.35)
                            : (glowPulse ? 0.18 : 0.07)
                    ))
                    .frame(width: 110, height: 110)
                    .blur(radius: 28)
                    .position(
                        x: lampAnchor.x * geo.size.width,
                        y: lampAnchor.y * geo.size.height
                    )
                    .animation(
                        .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                // ── Title block ────────────────────────────────────────────
                VStack(spacing: 5) {
                    Text("Compass Monument")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your inner compass")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color.white.opacity(0.55))
                        .tracking(0.3)

                    if !isActive {
                        HStack(spacing: 5) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 12))
                            Text("Tap for guidance")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(AppTheme.Colors.accentGold.opacity(hintPulse ? 0.9 : 0.5))
                        .padding(.top, 6)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: hintPulse
                        )
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .frame(height: 420)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onAppear {
            glowPulse = true
            hintPulse = true
        }
    }
}
