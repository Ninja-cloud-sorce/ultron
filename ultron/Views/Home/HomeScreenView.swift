import SwiftUI
import AVFoundation
import CoreImage

struct HomeScreenView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showReflectionCard  = true
    @State private var showNewEntry        = false
    @State private var showAlignmentBanner = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                    // MARK: Header
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(greeting + ", Op.")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text(formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 2)

                            Text("\(journalVM.totalEntries) reflections written")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        MascotView()
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 60)

                    // MARK: North Star alignment pill — transient, auto-dismisses
                    if showAlignmentBanner, let analysis = journalVM.latestAnalysis {
                        NorthStarAlignmentPill(analysis: analysis)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: Today's Reflection card
                    if showReflectionCard {
                        TodayReflectionCard(
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showReflectionCard = false
                                }
                            },
                            onTap: { showNewEntry = true }
                        )
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: Stats row
                    HStack(spacing: AppTheme.Spacing.m) {
                        HomeStatCard(icon: "book.fill",                   value: "\(journalVM.totalEntries)", label: "Entries")
                        HomeStatCard(icon: "calendar.badge.checkmark",    value: "\(journalVM.currentStreak)", label: "This Week")
                        HomeStatCard(icon: "calendar",                    value: "31",                        label: "This Month")
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // MARK: Recent Entries
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("RECENT ENTRIES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        VStack(spacing: 0) {
                            ForEach(Array(journalVM.entries.prefix(3).enumerated()), id: \.element.id) { i, entry in
                                RecentEntryRow(entry: entry)
                                if i < min(journalVM.entries.count, 3) - 1 {
                                    Rectangle()
                                        .fill(AppTheme.Colors.borderSubtle)
                                        .frame(height: 1)
                                        .padding(.leading, AppTheme.Spacing.m)
                                }
                            }
                        }
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NewEntryView(isPresented: $showNewEntry)
                .environmentObject(journalVM)
        }
        .onChange(of: journalVM.latestAnalysis?.id) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                showAlignmentBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showAlignmentBanner = false
                }
            }
        }
    }
}

// MARK: - Mascot

struct MascotView: View {
    @EnvironmentObject var session: AppSessionState

    var body: some View {
        Group {
            if session.hasPlayedMascotGreeting {
                // Greeting already played this session — render static PNG, no cost.
                Image("mascot")
                    .resizable()
                    .scaledToFit()
            } else {
                // First appearance this session — play the ProRes 4444 greeting video.
                MascotVideoPlayer {
                    session.hasPlayedMascotGreeting = true
                }
            }
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Mascot video player (alpha-preserving)

// AVPlayerLayer and VideoPlayer both composite the video as opaque, losing the
// alpha channel. Instead, AVPlayerItemVideoOutput pulls CVPixelBuffers each frame;
// we convert them CIImage → CGImage → UIImage and draw into a transparent UIImageView.

private struct MascotVideoPlayer: UIViewRepresentable {
    let onFinished: () -> Void

    func makeUIView(context: Context) -> MascotPlayerUIView {
        let view = MascotPlayerUIView()
        view.onFinished = onFinished
        return view
    }

    func updateUIView(_ uiView: MascotPlayerUIView, context: Context) {}
}

final class MascotPlayerUIView: UIView {
    var onFinished: (() -> Void)?

    private let player = AVPlayer()
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?

    // One CIContext per view, shared across all frames — expensive to create per-frame.
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: false
    ])

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        iv.isOpaque = false
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        imageView.frame = bounds
        addSubview(imageView)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        guard let url = Bundle.main.url(forResource: "mascot_greeting", withExtension: "mov") else {
            // File not in bundle yet — skip straight to static image.
            DispatchQueue.main.async { self.onFinished?() }
            return
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        videoOutput = output

        let item = AVPlayerItem(url: url)
        item.add(output)

        player.isMuted = true
        player.replaceCurrentItem(with: item)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link

        player.play()
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard let output = videoOutput else { return }

        // Use the display link's target timestamp so the frame we pick is the
        // one the screen will actually show on this vsync.
        let itemTime = output.itemTime(forHostTime: link.targetTimestamp)
        guard itemTime.isValid,
              output.hasNewPixelBuffer(forItemTime: itemTime),
              let pixelBuffer = output.copyPixelBuffer(
                  forItemTime: itemTime, itemTimeForDisplay: nil)
        else { return }

        // CVPixelBuffer row-0 is the visual top; CIImage uses bottom-left origin,
        // so the image appears upside-down without the flip.
        var ci = CIImage(cvPixelBuffer: pixelBuffer)
        ci = ci.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -ci.extent.height)
        )

        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return }
        imageView.image = UIImage(cgImage: cg)
    }

    @objc private func playerItemDidPlayToEnd(_ notification: Notification) {
        displayLink?.invalidate()
        displayLink = nil
        DispatchQueue.main.async { self.onFinished?() }
    }

    deinit {
        displayLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Today's Reflection Card
struct TodayReflectionCard: View {
    let onDismiss: () -> Void
    let onTap:     () -> Void

    private let prompts = [
        "What's on your mind today?",
        "What are you grateful for right now?",
        "What did you learn about yourself this week?",
        "Describe something that brought you peace today.",
        "What is one thing you want to let go of?",
    ]

    // Start on today's prompt, then cycle from there
    @State private var currentIndex = 0
    @State private var promptOpacity: Double = 1

    var body: some View {
        // Outer Button fires onTap (open New Entry).
        // Inner × Button fires onDismiss — SwiftUI routes touches to the
        // innermost interactive control, so × never triggers onTap.
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                // Header row
                HStack {
                    Text("TODAY'S REFLECTION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.Colors.accentGold)
                        .tracking(1.5)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(6)
                    }
                }

                // Cycling prompt text — cross-fades between prompts
                Text(prompts[currentIndex])
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(promptOpacity)

                // "Tap to write →" — mirrors the reference affordance
                HStack(spacing: 4) {
                    Text("Tap to write")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.m)
            // Left accent bar — overlaid before clip so corners round naturally
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#7BC67E"))
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            // Seed to today's slot so the first prompt matches the day
            currentIndex = Calendar.current.component(.dayOfYear, from: Date()) % prompts.count
        }
        .task {
            await cyclePrompts()
        }
    }

    // Cycles through prompts: 4 s display → 0.45 s fade out → swap → 0.45 s fade in → repeat
    @MainActor
    private func cyclePrompts() async {
        // Wait before first cycle so the seeded prompt is visible for a full interval
        do    { try await Task.sleep(for: .seconds(4.0)) }
        catch { return }

        while true {
            // Fade out
            withAnimation(.easeInOut(duration: 0.45)) { promptOpacity = 0 }
            do    { try await Task.sleep(for: .seconds(0.45)) }
            catch { withAnimation { promptOpacity = 1 }; return }

            // Advance to next prompt
            currentIndex = (currentIndex + 1) % prompts.count

            // Fade in
            withAnimation(.easeInOut(duration: 0.45)) { promptOpacity = 1 }

            // Hold the new prompt
            do    { try await Task.sleep(for: .seconds(4.0)) }
            catch { return }
        }
    }
}

// MARK: - North Star Alignment Pill
struct NorthStarAlignmentPill: View {
    let analysis: DirectionAnalysis
    @State private var gaugeProgress: CGFloat = 0

    var body: some View {
        HStack(spacing: 14) {
            // Half-circle gauge with score in center
            ZStack {
                // Background track
                SemiArcShape()
                    .trim(from: 0, to: 1)
                    .stroke(Color.white.opacity(0.1),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 54, height: 27)

                // Progress arc
                SemiArcShape()
                    .trim(from: 0, to: gaugeProgress)
                    .stroke(Color(hex: analysis.direction.hexColor),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 54, height: 27)

                Text("\(analysis.alignmentScore)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: 10)
            }
            .frame(width: 54, height: 40)

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.direction.shortLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: analysis.direction.hexColor))
                Text("with your North Star")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Text(analysis.direction.emoji)
                .font(.system(size: 20))
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(Color(hex: analysis.direction.hexColor).opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                gaugeProgress = CGFloat(analysis.alignmentScore) / 100.0
            }
        }
    }
}

private struct SemiArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                 radius: rect.width / 2,
                 startAngle: .degrees(180),
                 endAngle: .degrees(0),
                 clockwise: false)
        return p
    }
}

// MARK: - Home Stat Card
struct HomeStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Recent Entry Row
struct RecentEntryRow: View {
    let entry: JournalEntry

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(entry.date)
        if diff < 3600 { return "\(max(1, Int(diff / 60)))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    private var preview: String {
        let text = entry.text.isEmpty ? entry.title : entry.text
        return text
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Text(preview)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(timeAgo)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .fixedSize()
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, 14)
    }
}

// MARK: - Direction Card
struct DirectionCard: View {
    let analysis: DirectionAnalysis
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack(alignment: .top) {
                    Text("YOUR DIRECTION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1.5)
                    Spacer()
                    Text("\(analysis.alignmentScore)%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: analysis.direction.hexColor))
                }

                HStack(spacing: 6) {
                    Text(analysis.direction.emoji)
                        .font(.system(size: 15))
                    Text(analysis.direction.shortLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                Text(analysis.reason)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text("View Analysis")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.m)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: analysis.direction.hexColor))
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            DirectionDetailSheet(analysis: analysis)
        }
    }
}

// MARK: - Direction Detail Sheet
struct DirectionDetailSheet: View {
    let analysis: DirectionAnalysis
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showClarification     = false
    @State private var clarificationAccepted = false

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                    // Close
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .padding(10)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Direction + score
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        Text("YOUR DIRECTION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)

                        HStack(spacing: 10) {
                            Text(analysis.direction.emoji)
                                .font(.system(size: 28))
                            Text(analysis.direction.shortLabel)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Alignment Score")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Spacer()
                                Text("\(analysis.alignmentScore)%")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: analysis.direction.hexColor))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.Colors.borderSubtle)
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: analysis.direction.hexColor))
                                        .frame(width: geo.size.width * CGFloat(analysis.alignmentScore) / 100.0, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }

                        Text(analysis.reason)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.Colors.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .stroke(Color(hex: analysis.direction.hexColor).opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Coach recommendation
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("COACH'S RECOMMENDATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.accentGold)
                            Text(analysis.coachRecommendation)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    // Themes
                    if !analysis.themes.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("THEMES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .tracking(1.5)
                                .padding(.horizontal, AppTheme.Spacing.m)

                            HStack(spacing: AppTheme.Spacing.s) {
                                ForEach(analysis.themes, id: \.self) { theme in
                                    Text(theme)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.accentGold)
                                        .padding(.horizontal, AppTheme.Spacing.m)
                                        .padding(.vertical, 7)
                                        .background(AppTheme.Colors.accentGold.opacity(0.1))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppTheme.Colors.accentGold.opacity(0.3), lineWidth: 1))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                        }
                    }

                    // Summary
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("ENTRY SUMMARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        Text(analysis.summary)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    // Clarification nudge — only when AI found a suggestion
                    if analysis.clarificationSuggestion != nil {
                        Rectangle()
                            .fill(AppTheme.Colors.borderSubtle)
                            .frame(height: 1)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.top, AppTheme.Spacing.m)

                        if clarificationAccepted {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#7BC67E"))
                                Text("Clarification applied to this entry.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.top, AppTheme.Spacing.s)
                            .transition(.opacity)
                        } else {
                            Button { showClarification = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.Colors.accentGold.opacity(0.65))
                                    Text("I want to make sure I understood this entry correctly.")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.4))
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.top, AppTheme.Spacing.s)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, AppTheme.Spacing.m)
            }
        }
        .sheet(isPresented: $showClarification) {
            if let suggestion = analysis.clarificationSuggestion {
                ClarificationSheet(
                    analysis:   analysis,
                    suggestion: suggestion,
                    onAccepted: {
                        withAnimation(.easeOut(duration: 0.3)) { clarificationAccepted = true }
                    }
                )
                .environmentObject(journalVM)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.hidden)
            }
        }
    }
}
