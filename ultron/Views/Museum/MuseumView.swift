import SwiftUI

struct MuseumView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "Lessons"

    private let tabs = MemoryType.allCases.map { $0.rawValue }

    private var memories: [MuseumMemory] {
        MuseumMemory.samples.filter { $0.type.rawValue == selectedTab }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.bottom, AppTheme.Spacing.s)

                    Text("Museum")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your greatest compass")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(0.3)
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.top, 60)
                .padding(.bottom, AppTheme.Spacing.l)

                // ── Tab filter ────────────────────────────────────────────
                TimeFilterPicker(options: tabs, selected: $selectedTab)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.l)

                // ── Content ───────────────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.l) {
                        if memories.isEmpty {
                            MuseumEmptyState(tab: selectedTab)
                                .padding(.top, 60)
                        } else {
                            ForEach(Array(memories.enumerated()), id: \.element.id) { i, memory in
                                Group {
                                    if memory.type == .memories {
                                        MuseumMemoryCard(memory: memory, index: i)
                                    } else {
                                        MuseumQuoteCard(memory: memory, index: i)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                }
            }
        }
        .hideNavigationBar()
    }
}

// MARK: - Quote Card (Lessons + Quotes)

private struct MuseumQuoteCard: View {
    let memory: MuseumMemory
    let index: Int
    @State private var appeared = false

    private var accentColor: Color {
        memory.type == .lessons ? AppTheme.Colors.accentGold : AppTheme.Colors.accentTeal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Label chip
            HStack(spacing: 5) {
                Image(systemName: memory.type == .lessons ? "graduationcap.fill" : "quote.bubble.fill")
                    .font(.system(size: 11))
                    .foregroundColor(accentColor)
                Text(memory.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            // Content quote
            Text(memory.content)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // Date
            Text(memory.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.35))
        }
        .padding(AppTheme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.14), AppTheme.Colors.bgElevated],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                        .stroke(accentColor.opacity(0.22), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.07), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Memory Card

private struct MuseumMemoryCard: View {
    let memory: MuseumMemory
    let index: Int
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: 5) {
                Text(memory.formattedDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)

                Text(memory.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(memory.content)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .lineSpacing(3)
            }

            Spacer()

            // Mood thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(AppTheme.Colors.accentRose.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "photo.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.accentRose.opacity(0.6))
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.07), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Empty State

private struct MuseumEmptyState: View {
    let tab: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "archivebox")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("Nothing here yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("Keep journaling to fill your \(tab.lowercased())")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}
