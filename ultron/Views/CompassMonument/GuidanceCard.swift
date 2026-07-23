import SwiftUI

struct GuidanceRevealView: View {
    let guidance: Guidance
    let onReset: () -> Void

    @State private var revealedCount = 0
    @State private var cursorOn      = true

    private var chars: [Character] { Array(guidance.message) }
    private var isComplete: Bool    { revealedCount >= chars.count }
    private var revealed: String    { String(chars.prefix(revealedCount)) }

    private var typewriterText: AttributedString {
        var result = AttributedString(revealed)
        result.foregroundColor = .white
        if !isComplete {
            var cursor = AttributedString(cursorOn ? "▌" : " ")
            cursor.foregroundColor = Color(hex: "#FFD700")
            result += cursor
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {

            // ── Header ───────────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.accentGold)
                Text("Today's Guidance")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentGold)
                Spacer()
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
            }

            // ── Typewriter text ───────────────────────────────────────────
            // Text + Text concatenation is deprecated in iOS 26.
            // AttributedString gives the same mixed-colour result without the warning.
            Text(typewriterText)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .lineSpacing(9)
                .frame(maxWidth: .infinity, alignment: .leading)


        }
        // Explicit maxWidth ensures the VStack fills the padded column width,
        // regardless of whatever width the parent VStack may have inferred.
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            Task { await revealText() }
            Task { await blinkCursor() }
        }
    }

    // MARK: - Character reveal

    @MainActor
    private func revealText() async {
        for i in 0..<chars.count {
            let c = chars[i]
            let ns: UInt64 = c == "\n" ? 130_000_000 : (c == " " ? 28_000_000 : 48_000_000)
            try? await Task.sleep(nanoseconds: ns)
            revealedCount = i + 1
        }
        cursorOn = false
    }

    // MARK: - Cursor blink

    @MainActor
    private func blinkCursor() async {
        while !isComplete {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !isComplete { cursorOn.toggle() }
        }
        cursorOn = false
    }
}
