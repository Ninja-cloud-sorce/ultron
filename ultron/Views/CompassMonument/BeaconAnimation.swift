import SwiftUI

// MARK: - Lighthouse Beam
//
// A fixed upward beam that originates at the lantern and fans out toward the top
// of the night sky. Calm and cinematic — no full rotation sweep.
// Animations: 5-8% brightness pulse (5 s) + ±2° sway (12 s full cycle).

struct LighthouseBeam: View {
    /// UnitPoint of the lantern orb in the hero view (must match LighthouseHero).
    var lampAnchor: UnitPoint = UnitPoint(x: 0.5, y: 0.62)

    @State private var beamOpacity: Double  = 0.78   // pulses to 0.86 (≈8%)
    @State private var beamTilt:    Double  = -2.0   // ±2° slow sway
    @State private var bloomScale:  CGFloat = 0.90   // lantern bloom pulse

    var body: some View {
        GeometryReader { geo in
            let lampX      = lampAnchor.x * geo.size.width
            let lampY      = lampAnchor.y * geo.size.height
            let beamHeight = lampY                    // beam reaches from lamp to y = 0
            let baseHalf:   CGFloat = 2.5             // 5 pt wide at origin
            let topHalf:    CGFloat = 78.0            // ~156 pt wide at top of frame

            ZStack {
                // ── Core beam — narrow trapezoid, bright gold → clear ──────────
                Path { p in
                    p.move(to:    CGPoint(x: lampX - baseHalf, y: lampY))
                    p.addLine(to: CGPoint(x: lampX - topHalf,  y: lampY - beamHeight))
                    p.addLine(to: CGPoint(x: lampX + topHalf,  y: lampY - beamHeight))
                    p.addLine(to: CGPoint(x: lampX + baseHalf, y: lampY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#FFD86B").opacity(0.82), location: 0.00),
                            .init(color: Color(hex: "#FFD86B").opacity(0.42), location: 0.42),
                            .init(color: Color.clear,                          location: 1.00),
                        ],
                        startPoint: .bottom,   // base = bright gold
                        endPoint:   .top       // sky = transparent
                    )
                )
                .blur(radius: 14)
                .blendMode(.screen)

                // ── Atmospheric halo — wider, dimmer, softer ──────────────────
                Path { p in
                    p.move(to:    CGPoint(x: lampX - baseHalf * 2,  y: lampY))
                    p.addLine(to: CGPoint(x: lampX - topHalf * 1.6, y: lampY - beamHeight * 0.88))
                    p.addLine(to: CGPoint(x: lampX + topHalf * 1.6, y: lampY - beamHeight * 0.88))
                    p.addLine(to: CGPoint(x: lampX + baseHalf * 2,  y: lampY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#FFD86B").opacity(0.22), location: 0.00),
                            .init(color: Color(hex: "#FFD86B").opacity(0.07), location: 0.50),
                            .init(color: Color.clear,                          location: 1.00),
                        ],
                        startPoint: .bottom,
                        endPoint:   .top
                    )
                )
                .blur(radius: 30)
                .blendMode(.screen)

                // ── Soft bloom at lantern — radial glow, 4–8 pt below spire tip
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#FFE88A").opacity(0.88),
                                Color(hex: "#FFD86B").opacity(0.48),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 26
                        )
                    )
                    .frame(width: 52, height: 52)
                    .blur(radius: 9)
                    .scaleEffect(bloomScale)
                    .position(x: lampX, y: lampY + 6)   // 6 pt below brightest glow
            }
            .opacity(beamOpacity)
            // ±2° rotation anchored at lamp — beam pivots around its own source
            .rotationEffect(.degrees(beamTilt), anchor: lampAnchor)
        }
        .onAppear {
            // Brightness pulse: 78% → 86% (~8%), 5 s period
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                beamOpacity = 0.86
            }
            // Sway: –2° → +2°, one full cycle = 12 s (6 s each way)
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                beamTilt = 2.0
            }
            // Bloom breathe
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                bloomScale = 1.12
            }
        }
    }
}

// MARK: - Beam Down Effect

struct BeamDownEffect: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFD700").opacity(0.9),
                            Color(hex: "#FFD700").opacity(0.4),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: appeared ? 80 : 0)

            Circle()
                .fill(Color(hex: "#FFD700"))
                .frame(width: 10, height: 10)
                .blur(radius: 5)
                .opacity(appeared ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.55), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Star Twinkle Layer

struct StarTwinkleLayer: View {
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (0.12, 0.06, 3.0, 0.0),
        (0.75, 0.04, 2.2, 0.4),
        (0.88, 0.10, 2.8, 0.9),
        (0.06, 0.18, 1.8, 0.2),
        (0.55, 0.02, 2.0, 0.6),
        (0.92, 0.22, 1.6, 1.1),
        (0.32, 0.08, 3.2, 0.3),
        (0.78, 0.14, 1.8, 0.8),
        (0.20, 0.14, 2.4, 0.5),
        (0.65, 0.18, 1.4, 1.3),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars.indices, id: \.self) { i in
                let s = stars[i]
                StarDot(size: s.size, delay: s.delay)
                    .position(x: geo.size.width * s.x,
                               y: geo.size.height * s.y)
            }
        }
    }
}

private struct StarDot: View {
    let size: CGFloat
    let delay: Double
    @State private var opacity: Double = 0.15

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.2...2.4))
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    opacity = 0.9
                }
            }
    }
}
