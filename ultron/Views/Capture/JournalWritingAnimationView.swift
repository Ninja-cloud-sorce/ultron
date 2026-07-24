import SwiftUI

/// Full-screen notebook-page animation where cleaned journal text writes itself word by word.
/// When the animation finishes a premium pill "Continue" button fades in.
struct JournalWritingAnimationView: View {
    let scannedImage: UIImage
    let text: String
    let onContinue: (String) -> Void
    let onDismiss: () -> Void

    @State private var visibleWordCount = 0
    @State private var showContinue     = false

    // Parsed once from `text`; each element is one paragraph's word list + global start index.
    private struct Para {
        let words: [String]
        let start: Int   // index of first word in the global words array
    }

    private var paras: [Para] {
        var idx = 0
        return text
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line in
                let ws = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                let p  = Para(words: ws, start: idx)
                idx   += ws.count
                return p
            }
    }

    private var words: [String] { paras.flatMap { $0.words } }

    // page bg: 1055×1491 px → scales to 659×932 pt on a 430-pt-wide screen.
    // Ruled-line pitch measured from source: ~48 px → 48 × (932/1491) ≈ 30 pt.
    private let linePitch: CGFloat = 30

    // Margins: 28 pt left (clear of spiral), 20 pt right.
    private let hLeading:  CGFloat = 28
    private let hTrailing: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let W       = proxy.size.width
            let H       = proxy.size.height
            let topSafe = proxy.safeAreaInsets.top
            let botSafe = proxy.safeAreaInsets.bottom

            ZStack(alignment: .topLeading) {

                // ── Notebook background ─────────────────────────────────────────────
                // Explicit W×H frame + clipped stops the ZStack from expanding to the
                // image's scaledToFill width (659 pt), which shifted text off-screen.
                Image("page bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: W, height: H)
                    .clipped()

                // ── Main content ────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    // Header row: date right-aligned on the DATE: ruled line.
                    // The "DATE:" label is pre-printed on the image; the formatted
                    // date fills in the blank beside it, mirroring a physical journal.
                    HStack(alignment: .center) {
                        Spacer()
                        Text(Date().formatted(
                            .dateTime.month(.abbreviated).day().year()
                        ))
                        .font(.custom("Georgia", size: 14).italic())
                        .foregroundColor(.black.opacity(0.62))

                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black.opacity(0.32))
                                .padding(7)
                                .background(Color.black.opacity(0.07))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 6)
                    }
                    .padding(.trailing, hTrailing)
                    .padding(.top, topSafe + 8)

                    // Gap: one ruled-line pitch → first word lands on the next line.
                    Spacer().frame(height: linePitch + 2)

                    // Animated journal text, respecting notebook margins.
                    ScrollView(showsIndicators: false) {
                        animatedTextView
                            .padding(.leading,  hLeading)
                            .padding(.trailing, hTrailing)
                            .padding(.bottom, 120)
                    }
                }
                .frame(width: W)

                // ── Pill Continue button (pinned at bottom, appears after animation) ─
                VStack {
                    Spacer()
                    if showContinue {
                        pillButton(bottomInset: botSafe)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.88, anchor: .bottom))
                            )
                    }
                }
                .frame(width: W, height: H)
                .animation(.spring(response: 0.48, dampingFraction: 0.78), value: showContinue)
            }
            .frame(width: W, height: H)
        }
        .ignoresSafeArea()
        .onAppear { startAnimation() }
    }

    // MARK: - Animated text
    // Paragraphs sit in a VStack with 18 pt spacing so blank lines between
    // thoughts are clearly visible. Within each paragraph, lineSpacing is tuned
    // to keep each line on a printed notebook rule.
    private var animatedTextView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(paras.enumerated()), id: \.offset) { _, para in
                paraView(para)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paraView(_ para: Para) -> some View {
        var attributed = AttributedString()
        for (i, word) in para.words.enumerated() {
            let global = para.start + i
            var chunk  = AttributedString(i < para.words.count - 1 ? word + " " : word)
            chunk.foregroundColor = global < visibleWordCount
                ? UIColor.black.withAlphaComponent(0.80)
                : UIColor.clear
            attributed += chunk
        }
        return Text(attributed)
            .font(.custom("Georgia", size: 15))
            .lineSpacing(linePitch - 20)   // Georgia-15 natural height ≈ 20 pt
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Premium pill button
    private func pillButton(bottomInset: CGFloat) -> some View {
        Button { onContinue(text) } label: {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.80))
                    .shadow(color: .black.opacity(0.20), radius: 16, x: 0, y: 6)
            )
        }
        .buttonStyle(PillPressStyle())
        .padding(.bottom, max(bottomInset, 16) + 16)
    }

    // MARK: - Animation engine

    private func startAnimation() {
        guard !words.isEmpty else { showContinue = true; return }
        scheduleWord(at: 0)
    }

    private func scheduleWord(at index: Int) {
        guard index < words.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showContinue = true }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + wordDelay(at: index)) {
            visibleWordCount = index + 1
            scheduleWord(at: index + 1)
        }
    }

    private func wordDelay(at index: Int) -> TimeInterval {
        guard index > 0 else { return 0 }
        let prev = words[index - 1]
        if prev.hasSuffix(".") || prev.hasSuffix("!") || prev.hasSuffix("?") { return 0.30 }
        if prev.hasSuffix(",") || prev.hasSuffix(";") || prev.hasSuffix(":") { return 0.14 }
        return 0.065 + TimeInterval(min(prev.count, 10)) * 0.003
    }
}

// MARK: - Spring-press style for the pill button
private struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
