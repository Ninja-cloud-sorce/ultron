import SwiftUI

struct NewEntryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var selectedMood: Mood = .calm
    @State private var title = ""
    @State private var text = ""
    @State private var tags = ""
    @FocusState private var focusedField: Field?

    enum Field { case title, text, tags }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Date + close
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Entry")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Text(Date().formatted(date: .complete, time: .omitted))
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            Spacer()
                            Button(action: { isPresented = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(10)
                                    .background(AppTheme.Colors.bgElevated)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.top, AppTheme.Spacing.m)

                        // Mood selector
                        MoodSelector(selectedMood: $selectedMood)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        // Title field
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("Title".uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .tracking(1.2)
                            TextField("Give your entry a title…", text: $title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .tint(AppTheme.Colors.accentGold)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.medium).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                                .focused($focusedField, equals: .title)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Text editor
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("Your Thoughts".uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .tracking(1.2)
                            ZStack(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text("What's on your mind today?")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .font(.system(size: 16))
                                        .padding(.top, AppTheme.Spacing.m)
                                        .padding(.leading, AppTheme.Spacing.m)
                                }
                                TextEditor(text: $text)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .tint(AppTheme.Colors.accentGold)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 180)
                                    .padding(AppTheme.Spacing.s)
                                    .focused($focusedField, equals: .text)
                            }
                            .padding(AppTheme.Spacing.s)
                            .background(AppTheme.Colors.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.medium).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Tags
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("Tags".uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .tracking(1.2)
                            TextField("morning, gratitude, growth…", text: $tags)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .tint(AppTheme.Colors.accentGold)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.medium).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                                .focused($focusedField, equals: .tags)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Save
                        GlowButton(title: "Save Entry", icon: "checkmark") {
                            saveEntry()
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .disabled(text.isEmpty)

                        Spacer(minLength: 40)
                    }
                }
            }
            .hideNavigationBar()
        }
    }

    private func saveEntry() {
        guard !text.isEmpty else { return }
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let entry = JournalEntry(mood: selectedMood, title: title, text: text, tags: tagList)
        journalVM.addEntry(entry)
        isPresented = false
    }
}
