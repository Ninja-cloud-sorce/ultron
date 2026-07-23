import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var journalVM = JournalViewModel()
    @StateObject private var captureVM = CaptureViewModel()

    @State private var showCaptureSheet   = false
    @State private var showNewEntry       = false
    @State private var showScanner        = false
    @State private var captureSheetAction = CaptureSheetAction.none

    private enum CaptureSheetAction { case none, write, capture }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch appVM.selectedTab {
                case 0:  HomeScreenView().environmentObject(journalVM)
                case 1:  JourneyView().environmentObject(journalVM)
                case 3:  CalendarView().environmentObject(journalVM)
                case 4:  SettingsView().environmentObject(journalVM)
                default: HomeScreenView().environmentObject(journalVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.2), value: appVM.selectedTab)

            CustomTabBar(selectedTab: $appVM.selectedTab) {
                showCaptureSheet = true
            }
        }
        // ── Write or Capture chooser ──────────────────────────────────
        .sheet(isPresented: $showCaptureSheet, onDismiss: {
            switch captureSheetAction {
            case .write:   showNewEntry = true
            case .capture: showScanner  = true
            case .none:    break
            }
            captureSheetAction = .none
        }) {
            CaptureSheet(
                onWrite:   { captureSheetAction = .write;   showCaptureSheet = false },
                onCapture: { captureSheetAction = .capture; showCaptureSheet = false }
            )
        }
        // ── Typed journal entry ───────────────────────────────────────
        .sheet(isPresented: $showNewEntry) {
            NewEntryView(isPresented: $showNewEntry)
                .environmentObject(journalVM)
        }
        // ── Document scanner ──────────────────────────────────────────
        .fullScreenCover(isPresented: $showScanner) {
            CaptureScanner(
                onScan: { pages in
                    showScanner = false
                    captureVM.handleScannedPages(pages)
                },
                onCancel: { showScanner = false }
            )
        }
        // ── Review / edit OCR result ──────────────────────────────────
        .fullScreenCover(isPresented: $captureVM.isReviewing,
                         onDismiss: { captureVM.reset() }) {
            if case .reviewing(let image, let text) = captureVM.flowState {
                ReviewCaptureView(
                    scannedImage: image,
                    initialText:  text,
                    onSave: { extractedText, mood, title, tags in
                        captureVM.save(image: image, text: extractedText,
                                       mood: mood, title: title, tags: tags,
                                       into: journalVM)
                    },
                    onRetake: {
                        captureVM.reset()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showScanner = true
                        }
                    },
                    onDismiss: { captureVM.reset() }
                )
            }
        }
        // ── OCR processing overlay ────────────────────────────────────
        .overlay {
            if captureVM.isProcessing {
                ProcessingOverlay()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: captureVM.isProcessing)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Processing overlay

private struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.l) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.Colors.accentGold)
                    .scaleEffect(1.4)

                VStack(spacing: 6) {
                    Text("Reading your journal…")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Extracting text with Vision AI")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xlarge))
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onFABTap: () -> Void

    private let items: [(icon: String, label: String, tag: Int)] = [
        ("house.fill",     "Home",     0),
        ("map.fill",       "Journey",  1),
        ("calendar",       "Calendar", 3),
        ("gearshape.fill", "Settings", 4),
    ]

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(items.prefix(2), id: \.tag) { item in
                    TabBarItem(icon: item.icon, label: item.label, isSelected: selectedTab == item.tag) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = item.tag }
                    }
                }
                Spacer().frame(maxWidth: .infinity)
                ForEach(items.suffix(2), id: \.tag) { item in
                    TabBarItem(icon: item.icon, label: item.label, isSelected: selectedTab == item.tag) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = item.tag }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, 28)
            .background(
                AppTheme.Colors.bgSurface
                    .shadow(color: .black.opacity(0.45), radius: 20, y: -4)
            )

            Button(action: onFABTap) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGold)
                        .frame(width: 58, height: 58)
                        .shadow(color: AppTheme.Colors.accentGold.opacity(0.55), radius: 14, y: 4)
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -18)
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
