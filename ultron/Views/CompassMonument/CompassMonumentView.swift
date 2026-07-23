import SwiftUI

struct CompassMonumentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = GuidanceViewModel()

    @State private var isLighthouseActive = false
    @State private var showBeamDown       = false
    @State private var showGuidanceArea   = false
    @State private var latestAnalysis: DirectionAnalysis? = nil

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Lighthouse hero (tap to activate) ─────────────────
                    LighthouseHero(isActive: isLighthouseActive) {
                        activateLighthouse()
                    }

                    // ── Alignment pill ─────────────────────────────────────
                    if let analysis = latestAnalysis {
                        NorthStarAlignmentPill(analysis: analysis)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }

                    // ── Beam shoots down from peak while loading ───────────
                    if showBeamDown {
                        BeamDownEffect()
                            .transition(.opacity)
                    }

                    // ── Guidance text reveals inline ───────────────────────
                    if showGuidanceArea, let guidance = vm.guidance {
                        GuidanceRevealView(guidance: guidance, onReset: resetAll)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 16)
                            .transition(.opacity)
                    } else if !isLighthouseActive && !showBeamDown {
                        idleHint
                    }

                    Spacer(minLength: 120)
                }
            }
            .ignoresSafeArea(edges: .top)

            // ── Back button ────────────────────────────────────────────────
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.leading, AppTheme.Spacing.m)
                .padding(.top, 56)
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .hideNavigationBar()
        .onAppear {
            latestAnalysis = JournalAnalysisRepository.shared.mostRecent()
        }
    }

    // MARK: - Idle hint

    private var idleHint: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Text("Your guiding light")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap the monument above to receive today's personalised guidance.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Flow

    private func activateLighthouse() {
        guard !isLighthouseActive else { return }

        withAnimation(.easeIn(duration: 0.4)) {
            isLighthouseActive = true
        }

        Task {
            // Beacon sweeps for a beat before the beam appears
            try? await Task.sleep(nanoseconds: 800_000_000)

            withAnimation(.easeIn(duration: 0.35)) {
                showBeamDown = true
            }

            // Beam stays visible while guidance loads (1.6 s mock delay)
            await vm.requestGuidance()

            withAnimation(.easeOut(duration: 0.4)) {
                showBeamDown = false
            }

            // Brief pause, then text starts materialising
            try? await Task.sleep(nanoseconds: 280_000_000)

            withAnimation(.easeIn(duration: 0.25)) {
                showGuidanceArea = true
            }
        }
    }

    private func resetAll() {
        withAnimation(.easeOut(duration: 0.3)) {
            showGuidanceArea   = false
            isLighthouseActive = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            vm.reset()
        }
    }
}
