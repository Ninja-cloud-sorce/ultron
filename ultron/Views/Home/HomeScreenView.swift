import SwiftUI
import AVFoundation
import CoreImage

struct HomeScreenView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showReflectionCard  = true
    @State private var showNewEntry        = false
    @State private var showAlignmentBanner = false
    @State private var showBackfillEntry   = false
    @State private var backfillDate        = Calendar.current.startOfDay(for: .now)
    @State private var cachedMissedDays: [Date] = []

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 6  { return "Good night" }
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        if h < 21 { return "Good evening" }
        return "Good night"
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
                            Text("\(greeting), \(settings.username).")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text(formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 2)

                            Text("\(journalVM.totalEntries) reflections written")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)

                            if journalVM.currentStreak > 0 {
                                HStack(spacing: 5) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#F4845F"))
                                    Text("\(journalVM.currentStreak) day streak")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F4845F"))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "#F4845F").opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color(hex: "#F4845F").opacity(0.3), lineWidth: 1))
                            }
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

                    // MARK: Missed Days — driven by cachedMissedDays (updated via onChange, not recomputed every render)
                    if !cachedMissedDays.isEmpty {
                        MissedDaysSection(missedDays: cachedMissedDays) { date in
                            backfillDate = date
                            showBackfillEntry = true
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    // MARK: Recent Entries
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("RECENT ENTRIES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        if journalVM.entries.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.45))
                                Text("No entries yet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Text("Tap the card above to write your first reflection.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal, AppTheme.Spacing.m)
                        } else {
                            VStack(spacing: AppTheme.Spacing.s) {
                                ForEach(journalVM.entries.prefix(3)) { entry in
                                    RecentEntryRow(entry: entry)
                                        .background {
                                            ZStack {
                                                Image("entry bg")
                                                    .resizable()
                                                    .scaledToFill()
                                                LinearGradient(
                                                    colors: [
                                                        AppTheme.Colors.bgPrimary.opacity(0.78),
                                                        AppTheme.Colors.bgPrimary.opacity(0.1),
                                                        .clear
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                LinearGradient(
                                                    colors: [.black.opacity(0.25), .clear, .clear, .black.opacity(0.15)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        .shadow(color: .black.opacity(0.38), radius: 16, y: 8)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NewEntryView(isPresented: $showNewEntry)
                .environmentObject(journalVM)
        }
        .sheet(isPresented: $showBackfillEntry) {
            NewEntryView(isPresented: $showBackfillEntry, presetDate: backfillDate)
                .environmentObject(journalVM)
        }
        .onAppear {
            cachedMissedDays = journalVM.missedDays()
        }
        .onChange(of: journalVM.entries.count) {
            cachedMissedDays = journalVM.missedDays()
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
                    .transition(.opacity)
            } else {
                // First appearance this session — play the greeting video.
                MascotVideoPlayer {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        session.hasPlayedMascotGreeting = true
                    }
                }
                .transition(.opacity)
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
        // The video lives inside the reference/ folder within the bundle.
        guard let url = Bundle.main.url(forResource: "mascot_transparent_3s", withExtension: "mov", subdirectory: "reference")
                     ?? Bundle.main.url(forResource: "mascot_transparent_3s", withExtension: "mov") else {
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
            .background {
                Image("reflection card bg")
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

    private var timeLabel: String {
        if entry.wasBackfilled {
            // Show the day it was written for, not the creation time
            return entry.entryDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
        let diff = Date().timeIntervalSince(entry.date)
        if diff < 3600 { return "\(max(1, Int(diff / 60)))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    private var preview: String {
        entry.text.isEmpty ? entry.title : entry.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                if entry.wasBackfilled {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.55))
                }
                Text(timeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Text(preview)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, 18)
    }
}

// MARK: - Missed Days Section
private struct MissedDaysSection: View {
    let missedDays: [Date]
    let onSelect: (Date) -> Void

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentGold.opacity(0.7))
                Text("MISSED DAYS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.2)
                Text("• tap to add")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.s) {
                    ForEach(missedDays, id: \.self) { day in
                        Button { onSelect(day) } label: {
                            VStack(spacing: 2) {
                                Text(Self.dayFormatter.string(from: day))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.accentGold.opacity(0.75))
                                Text(Self.dateFormatter.string(from: day))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.Colors.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.accentGold.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Indicate that only 14 days back are available if there are more misses
                    // before the window — omitting this here since missedDays() already
                    // caps at the window boundary. The label below surfaces the policy.
                }
            }

            Text("Entries can be added up to 14 days back")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
        }
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
