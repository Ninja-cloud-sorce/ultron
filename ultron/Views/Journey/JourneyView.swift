import SwiftUI

struct JourneyView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showCampfire = false
    @State private var showReflection = false
    @State private var showLibrary = false
    @State private var showObservatory = false
    @State private var showMonument = false
    @State private var showMuseum = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero background
                        ZStack(alignment: .bottom) {
                            BackgroundImageView(imageName: "your path bg")
                                .frame(height: 340)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                                Text("Your Journey")
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(AppTheme.Colors.accentGold)
                                    Text("\(journalVM.currentStreak) day streak")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.bottom, AppTheme.Spacing.l)
                        }
                        .frame(height: 340)

                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Stats row
                            HStack(spacing: AppTheme.Spacing.m) {
                                StatCard(icon: "flame.fill",       value: "\(journalVM.currentStreak)", label: "Day Streak",    accentColor: AppTheme.Colors.accentGold,  trend: "+2")
                                StatCard(icon: "book.fill",        value: "\(journalVM.totalEntries)",  label: "Total Entries", accentColor: AppTheme.Colors.accentTeal)
                                StatCard(icon: "heart.fill",       value: "7",                          label: "Moods Logged",  accentColor: AppTheme.Colors.accentRose)
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)

                            // Explore section
                            VStack(spacing: AppTheme.Spacing.m) {
                                SectionHeader(title: "Explore", actionLabel: nil)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Spacing.m) {
                                        ExploreCard(title: "Campfire",        icon: "flame.fill",         color: Color(hex: "#F0B429")) { showCampfire    = true }
                                        ExploreCard(title: "Reflection",      icon: "sparkles",            color: Color(hex: "#C084FC")) { showReflection  = true }
                                        ExploreCard(title: "Library",         icon: "books.vertical.fill", color: Color(hex: "#4FC3C3")) { showLibrary     = true }
                                        ExploreCard(title: "Observatory",     icon: "chart.bar.fill",      color: Color(hex: "#86EFAC")) { showObservatory = true }
                                        ExploreCard(title: "Monument",        icon: "safari.fill",         color: Color(hex: "#F0B429")) { showMonument    = true }
                                        ExploreCard(title: "Museum",          icon: "photo.on.rectangle",  color: Color(hex: "#E8758A")) { showMuseum      = true }
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.m)
                                }
                            }

                            // Recent entries
                            VStack(spacing: AppTheme.Spacing.m) {
                                SectionHeader(title: "Recent Entries", onAction: {})
                                VStack(spacing: AppTheme.Spacing.m) {
                                    ForEach(journalVM.entries.prefix(3)) { entry in
                                        JournalEntryCard(entry: entry) {
                                            journalVM.toggleBookmark(entry.id)
                                        }
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.m)
                            }

                            // Mood this week
                            VStack(spacing: AppTheme.Spacing.m) {
                                SectionHeader(title: "Mood This Week", actionLabel: nil)
                                HStack(spacing: AppTheme.Spacing.m) {
                                    ForEach(journalVM.moodHistory, id: \.rawValue) { mood in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(mood.color)
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Image(systemName: mood.icon)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.m)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                    }
                }
                .background(AppTheme.Colors.bgPrimary)
            }
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $showCampfire)    { CampfireView().environmentObject(journalVM) }
            .navigationDestination(isPresented: $showReflection)  { ReflectionGardenView() }
            .navigationDestination(isPresented: $showLibrary)     { LibraryView().environmentObject(journalVM) }
            .navigationDestination(isPresented: $showObservatory) { ObservatoryView().environmentObject(journalVM) }
            .navigationDestination(isPresented: $showMonument)    { CompassMonumentView() }
            .navigationDestination(isPresented: $showMuseum)      { MuseumView().environmentObject(journalVM) }
        }
    }
}

struct ExploreCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(color.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
