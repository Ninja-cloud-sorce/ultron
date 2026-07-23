import SwiftUI

// MARK: - Data

struct MilestoneData {
    let icon: String
    let title: String
    let subtitle: String
    let xOffset: CGFloat
}

let milestones: [MilestoneData] = [
    MilestoneData(icon: "flame.fill",           title: "Campfire",         subtitle: "Build consistency",     xOffset:  0),
    MilestoneData(icon: "books.vertical.fill",  title: "Library",          subtitle: "Understand your world", xOffset: -8),
    MilestoneData(icon: "location.north.fill",  title: "Compass Monument", subtitle: "Discover insights",     xOffset:  8),
    MilestoneData(icon: "star.fill",            title: "First Step",       subtitle: "Start your journey",    xOffset: -4),
]

// MARK: - Curved Connector

struct CurvedConnector: View {
    let fromOffset: CGFloat
    let toOffset: CGFloat
    let isVisible: Bool

    private let height: CGFloat = 54
    private let nodeRadius: CGFloat = 18
    private let canvasWidth: CGFloat = 64

    var body: some View {
        let startX = nodeRadius + fromOffset
        let endX   = nodeRadius + toOffset

        Path { path in
            path.move(to: CGPoint(x: startX, y: 0))
            path.addCurve(
                to:       CGPoint(x: endX,   y: height),
                control1: CGPoint(x: startX, y: height * 0.5),
                control2: CGPoint(x: endX,   y: height * 0.5)
            )
        }
        .stroke(
            Color.white.opacity(isVisible ? 0.28 : 0),
            style: StrokeStyle(lineWidth: 1.5, dash: [4, 7])
        )
        .frame(width: canvasWidth, height: height)
        .animation(.easeIn(duration: 0.3), value: isVisible)
    }
}

// MARK: - Milestone Row

struct JourneyMilestoneRow: View {
    let milestone: MilestoneData
    let index: Int
    let isVisible: Bool
    let onTap: (() -> Void)?   // nil = non-tappable, no chevron shown

    private let nodeGreen = Color(hex: "#7BC67E")
    private let nodeSize: CGFloat = 36

    var body: some View {
        let rowContent = HStack(alignment: .top, spacing: 18) {
            ZStack {
                Circle()
                    .fill(nodeGreen.opacity(onTap != nil ? 0.82 : 0.45))
                    .frame(width: nodeSize, height: nodeSize)
                    .shadow(color: nodeGreen.opacity(0.35), radius: 10, y: 3)
                Image(systemName: milestone.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(onTap != nil ? 1 : 0.55))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(onTap != nil ? 1 : 0.55))
                Text(milestone.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white.opacity(onTap != nil ? 0.5 : 0.3))
            }
            .padding(.top, 7)

            Spacer()

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.top, 10)
            }
        }

        Group {
            if let action = onTap {
                Button(action: action) { rowContent }
                    .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .offset(x: milestone.xOffset, y: isVisible ? 0 : 22)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .spring(response: 0.52, dampingFraction: 0.76)
                .delay(Double(index) * 0.08),
            value: isVisible
        )
    }
}

// MARK: - Journey View

struct JourneyView: View {
    @EnvironmentObject var journalVM: JournalViewModel

    @State private var showCampfire = false
    @State private var showLibrary  = false
    @State private var showMonument = false
    @State private var showMuseum   = false

    @State private var milestonesVisible = false

    private func action(for index: Int) -> (() -> Void)? {
        switch index {
        case 0: return { showCampfire = true }
        case 1: return { showLibrary  = true }
        case 2: return { showMonument = true }
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("your path bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.42)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Journey")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Text("Your path of becoming")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color.white.opacity(0.55))
                                .tracking(0.3)
                        }
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .padding(.top, 68)
                        .padding(.bottom, AppTheme.Spacing.xl + 4)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(milestones.indices, id: \.self) { i in
                                JourneyMilestoneRow(
                                    milestone: milestones[i],
                                    index: i,
                                    isVisible: milestonesVisible,
                                    onTap: action(for: i)
                                )

                                if i < milestones.count - 1 {
                                    CurvedConnector(
                                        fromOffset: milestones[i].xOffset,
                                        toOffset:   milestones[i + 1].xOffset,
                                        isVisible: milestonesVisible
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer(minLength: 120)
                    }
                }
            }
            .onAppear {
                milestonesVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    milestonesVisible = true
                }
            }
            .navigationDestination(isPresented: $showCampfire) { CampfireView().environmentObject(journalVM) }
            .navigationDestination(isPresented: $showLibrary)  { LibraryView().environmentObject(journalVM) }
            .navigationDestination(isPresented: $showMonument) { CompassMonumentView() }
            .navigationDestination(isPresented: $showMuseum)   { MuseumView().environmentObject(journalVM) }
        }
    }
}
