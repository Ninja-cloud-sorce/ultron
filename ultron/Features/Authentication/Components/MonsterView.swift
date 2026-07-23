import SwiftUI

// Colour palette for MonsterView — extracted outside the generic type because
// Swift does not allow static stored properties in generic structs.
private enum MC {
    static let bodyNrmTop = Color(red: 0.612, green: 0.851, blue: 0.620)
    static let bodyNrmBot = Color(red: 0.443, green: 0.765, blue: 0.459)
    static let bodyErrTop = Color(red: 0.949, green: 0.424, blue: 0.424)
    static let bodyErrBot = Color(red: 0.784, green: 0.235, blue: 0.235)
    static let bodySucTop = Color(red: 0.627, green: 0.910, blue: 0.639)
    static let bodySucBot = Color(red: 0.471, green: 0.800, blue: 0.486)
    static let hornCol    = Color(red: 0.173, green: 0.408, blue: 0.188)
    static let handCol    = Color(red: 0.337, green: 0.608, blue: 0.353)
    static let tuftCol    = Color(red: 0.173, green: 0.408, blue: 0.188)
}

// MonsterView — a fully hand-drawn SwiftUI illustration. No PNG, no clip-art.
//
// Three-layer composition:
//   A. Horns + body ellipse + hair tufts + eyes  (behind the card)
//   B. Card content (injected via @ViewBuilder)  (in front of body)
//   C. Fists                                     (on top of card — "holding" effect)
//
// Mood reacts visually:
//   .error   → body flashes coral-red, eyes widen, whole view shakes
//   .success → body brightens, gentle bounce
//   .idle    → slow float + breathe + periodic blink

struct MonsterView<Card: View>: View {
    var mood:        MonsterMood  = .idle
    /// Fraction of view height where the card's top edge is placed.
    var cardTopFrac: CGFloat      = 0.52
    /// Horizontal inset (each side) applied to the card, as fraction of view width.
    var cardHPad:    CGFloat      = 0.11

    private let cardContent: () -> Card

    init(mood: MonsterMood = .idle,
         cardTopFrac: CGFloat = 0.52,
         cardHPad: CGFloat = 0.11,
         @ViewBuilder card: @escaping () -> Card) {
        self.mood        = mood
        self.cardTopFrac = cardTopFrac
        self.cardHPad    = cardHPad
        self.cardContent = card
    }

    // ── Animation state ──────────────────────────────────────────────
    @State private var floatY:   CGFloat = 0
    @State private var breathe:  CGFloat = 1.0
    @State private var blinkAmt: CGFloat = 0   // 0 = open, 1 = closed
    @State private var eyeScale: CGFloat = 1.0
    @State private var shakeX:   CGFloat = 0
    @State private var isError:  Bool    = false
    @State private var isSuccess:Bool    = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bodyTop: Color { isError ? MC.bodyErrTop : isSuccess ? MC.bodySucTop : MC.bodyNrmTop }
    private var bodyBot: Color { isError ? MC.bodyErrBot : isSuccess ? MC.bodySucBot : MC.bodyNrmBot }

    // ── Root view ────────────────────────────────────────────────────
    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            ZStack {
                layerA(W: W, H: H)   // monster illustration (behind card)
                layerB(W: W, H: H)   // card
                layerC(W: W, H: H)   // fists (over card)
            }
        }
        .offset(x: shakeX, y: floatY)
        .scaleEffect(breathe)
        .onAppear   { if !reduceMotion { beginIdle() } }
        .onChange(of: mood) { _, m in react(m) }
    }

    // MARK: – Layer A  ▸ Horns · Body · Tufts · Eyes

    @ViewBuilder
    private func layerA(W: CGFloat, H: CGFloat) -> some View {
        ZStack {
            // ── Left horn (rendered behind body) ──────────────────────
            MonsterHorn(mirrored: false)
                .fill(MC.hornCol)
                .frame(width: W * 0.19, height: H * 0.21)
                .position(x: W * 0.240, y: H * 0.120)

            // ── Right horn ────────────────────────────────────────────
            MonsterHorn(mirrored: true)
                .fill(MC.hornCol)
                .frame(width: W * 0.19, height: H * 0.21)
                .position(x: W * 0.760, y: H * 0.120)

            // ── Body ellipse ──────────────────────────────────────────
            Ellipse()
                .fill(
                    LinearGradient(colors: [bodyTop, bodyBot],
                                   startPoint: .top, endPoint: .bottom)
                )
                .animation(.easeInOut(duration: 0.38), value: isError)
                .animation(.easeInOut(duration: 0.38), value: isSuccess)
                .frame(width: W * 0.88, height: H * 0.76)
                .position(x: W * 0.500, y: H * 0.550)
                // Subtle inner shadow on left side to add depth
                .shadow(color: MC.bodyNrmBot.opacity(0.25), radius: 20, x: -8, y: 0)

            // ── Hair tufts between horns ──────────────────────────────
            HStack(spacing: W * 0.022) {
                ForEach([-12.0, 0.0, 12.0], id: \.self) { deg in
                    Capsule()
                        .fill(MC.tuftCol)
                        .frame(width: W * 0.027, height: H * 0.044)
                        .scaleEffect(y: deg == 0 ? 1.0 : 0.72, anchor: .bottom)
                        .rotationEffect(.degrees(deg))
                }
            }
            .position(x: W * 0.500, y: H * 0.170)

            // ── Eyes ──────────────────────────────────────────────────
            eyeView(size: W * 0.135)
                .position(x: W * 0.365, y: H * 0.370)
            eyeView(size: W * 0.135)
                .position(x: W * 0.635, y: H * 0.370)
        }
    }

    // Eye: white sclera → dark pupil → catch-light → animated eyelid
    @ViewBuilder
    private func eyeView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 2)

            // Pupil — slight offset gives personality
            Circle()
                .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                .frame(width: size * 0.40, height: size * 0.40)
                .offset(x: size * 0.06, y: size * 0.05)

            // Catch-light
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: size * 0.14, y: -size * 0.14)

            // Eyelid (scales from top anchor); colour tracks body mood colour
            Capsule()
                .fill(bodyTop)
                .animation(.easeInOut(duration: 0.35), value: isError)
                .frame(width: size * 1.05, height: size)
                .scaleEffect(y: blinkAmt, anchor: .top)
        }
        .scaleEffect(eyeScale)
        .animation(.spring(response: 0.28, dampingFraction: 0.55), value: eyeScale)
    }

    // MARK: – Layer B  ▸ Card content

    @ViewBuilder
    private func layerB(W: CGFloat, H: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: H * cardTopFrac)
            cardContent()
                .padding(.horizontal, W * cardHPad)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Layer C  ▸ Fists (in front of card top edge)

    @ViewBuilder
    private func layerC(W: CGFloat, H: CGFloat) -> some View {
        let fw = W * 0.130
        let fh = H * 0.070
        // Fist centres are fractionally below the card's top so they appear
        // to grip the card from the front.
        let fy = H * cardTopFrac + H * 0.019

        ZStack {
            fist(width: fw, height: fh).position(x: W * 0.196, y: fy)
            fist(width: fw, height: fh).position(x: W * 0.804, y: fy)
        }
    }

    @ViewBuilder
    private func fist(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(colors: [MC.handCol.opacity(0.88), MC.handCol],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // MARK: – Animation helpers

    private func beginIdle() {
        withAnimation(.easeInOut(duration: 3.1).repeatForever(autoreverses: true)) {
            floatY = -8
        }
        withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
            breathe = 1.024
        }
        scheduleBlink()
    }

    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.4...5.2)) {
            guard mood != .error else { scheduleBlink(); return }
            doBlink()
        }
    }

    private func doBlink() {
        withAnimation(.linear(duration: 0.055)) { blinkAmt = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.linear(duration: 0.055)) { blinkAmt = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { scheduleBlink() }
        }
    }

    private func react(_ m: MonsterMood) {
        switch m {
        case .error:
            withAnimation(.easeInOut(duration: 0.32)) { isError = true; eyeScale = 1.38 }
            doShake()
        case .idle:
            withAnimation(.spring(response: 0.50, dampingFraction: 0.70)) {
                isError = false; isSuccess = false; eyeScale = 1.0
            }
        case .success:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { isSuccess = true }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.50)) { floatY = -16 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.70)) { floatY = 0 }
            }
        case .pressing:
            withAnimation(.spring(response: 0.18, dampingFraction: 0.60)) { breathe = 0.955 }
        case .typing:
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) { breathe = 1.0 }
        }
    }

    private func doShake() {
        let seq: [(CGFloat, Double)] = [
            (16, 0.00), (-13, 0.055), (11, 0.11),
            (-8, 0.165), (5, 0.22), (-3, 0.275), (0, 0.33)
        ]
        for (dx, t) in seq {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: 0.05)) { shakeX = dx }
            }
        }
    }
}

// MARK: – MonsterHorn shape

// Bezier horn: wide at the base, tapers to a curved outward-pointing tip.
// `mirrored` flips the tip direction for the right horn.
private struct MonsterHorn: Shape {
    var mirrored: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let tipX: CGFloat = mirrored ? w * 0.72 : w * 0.28
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h))
        p.addCurve(to: CGPoint(x: tipX, y: 0),
                   control1: CGPoint(x: w * 0.06, y: h * 0.44),
                   control2: CGPoint(x: tipX - w * 0.08, y: h * 0.14))
        p.addCurve(to: CGPoint(x: w, y: h),
                   control1: CGPoint(x: tipX + w * 0.08, y: h * 0.14),
                   control2: CGPoint(x: w * 0.94, y: h * 0.44))
        p.closeSubpath()
        return p
    }
}
