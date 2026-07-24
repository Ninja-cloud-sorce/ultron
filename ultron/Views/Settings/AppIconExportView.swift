import SwiftUI

// MARK: - Compass App Icon Design

struct AppIconView: View {
    let size: CGFloat

    private var s: CGFloat { size / 1024 }

    var body: some View {
        ZStack {
            // Background — deep navy with radial glow
            RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#1A1D2E"),
                            Color(hex: "#0D0F1A"),
                        ],
                        center: .init(x: 0.5, y: 0.38),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )

            // Subtle outer ring
            Circle()
                .stroke(Color(hex: "#F0B429").opacity(0.12), lineWidth: s * 3)
                .frame(width: s * 720, height: s * 720)

            // Mid ring
            Circle()
                .stroke(Color(hex: "#F0B429").opacity(0.07), lineWidth: s * 1.5)
                .frame(width: s * 560, height: s * 560)

            // Cardinal tick marks (N / E / S / W)
            ForEach([0.0, 90.0, 180.0, 270.0], id: \.self) { angle in
                RoundedRectangle(cornerRadius: s * 2)
                    .fill(Color(hex: "#F0B429").opacity(angle == 0 ? 0.9 : 0.3))
                    .frame(width: s * (angle == 0 ? 6 : 4),
                           height: s * (angle == 0 ? 32 : 20))
                    .offset(y: -(s * 316))
                    .rotationEffect(.degrees(angle))
            }

            // Diagonal tick marks (NE / SE / SW / NW)
            ForEach([45.0, 135.0, 225.0, 315.0], id: \.self) { angle in
                RoundedRectangle(cornerRadius: s * 1.5)
                    .fill(Color(hex: "#F0B429").opacity(0.15))
                    .frame(width: s * 3, height: s * 14)
                    .offset(y: -(s * 316))
                    .rotationEffect(.degrees(angle))
            }

            // South needle — slate/dark
            needleShape(tipLength: s * 210, waistOffset: s * 10, baseLength: s * 50)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2A2D42"), Color(hex: "#1E2133")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(180))

            // North needle — gold, dominant
            needleShape(tipLength: s * 270, waistOffset: s * 12, baseLength: s * 50)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFD166"), Color(hex: "#F0B429"), Color(hex: "#C9963A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Glow behind north needle
                .shadow(color: Color(hex: "#F0B429").opacity(0.55), radius: s * 22, y: -(s * 60))

            // Center jewel
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#FFE5A0"), Color(hex: "#F0B429")],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: s * 18
                    )
                )
                .frame(width: s * 32, height: s * 32)
                .shadow(color: Color(hex: "#F0B429").opacity(0.8), radius: s * 14)

            // Center ring
            Circle()
                .stroke(Color(hex: "#0D0F1A"), lineWidth: s * 4)
                .frame(width: s * 32, height: s * 32)
        }
        .frame(width: size, height: size)
        .clipped()
    }

    // Diamond needle shape: tip at top, widens at waist, closes at base below center
    private func needleShape(tipLength: CGFloat, waistOffset: CGFloat, baseLength: CGFloat) -> some Shape {
        NeedleShape(tipLength: tipLength, waistOffset: waistOffset, baseLength: baseLength)
    }
}

private struct NeedleShape: Shape {
    let tipLength: CGFloat
    let waistOffset: CGFloat
    let baseLength: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - tipLength))
        p.addLine(to: CGPoint(x: cx + waistOffset, y: cy))
        p.addLine(to: CGPoint(x: cx, y: cy + baseLength))
        p.addLine(to: CGPoint(x: cx - waistOffset, y: cy))
        p.closeSubpath()
        return p
    }
}

// MARK: - Export helper (Settings → About or run once)

struct AppIconExportView: View {
    @State private var exported = false
    @State private var savedPath = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                AppIconView(size: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 300 * 0.2237, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 10)

                if exported {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#7BC67E"))
                        Text("Saved to Documents")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(savedPath)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    Button("Export 1024×1024 PNG") { exportIcon() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#F0B429"))
                        .clipShape(Capsule())
                }
            }
        }
    }

    @MainActor
    private func exportIcon() {
        let renderer = ImageRenderer(content: AppIconView(size: 1024))
        renderer.scale = 1.0
        guard let uiImage = renderer.uiImage,
              let data = uiImage.pngData() else { return }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("compass_app_icon_1024.png")
        try? data.write(to: url)
        savedPath = url.path
        exported = true
    }
}

#Preview {
    AppIconExportView()
}
