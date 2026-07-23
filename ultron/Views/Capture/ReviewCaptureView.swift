import SwiftUI

/// Shows the scanned image alongside OCR-extracted text for review and editing.
struct ReviewCaptureView: View {
    let scannedImage: UIImage
    let initialText:  String
    let onSave:       (String, Mood, String, [String]) -> Void
    let onRetake:     () -> Void
    let onDismiss:    () -> Void

    @State private var editedText  : String
    @State private var selectedMood: Mood   = .calm
    @State private var title       : String = ""
    @State private var tags        : String = ""
    @FocusState private var focused: Field?

    private enum Field { case title, text, tags }

    init(scannedImage: UIImage, initialText: String,
         onSave: @escaping (String, Mood, String, [String]) -> Void,
         onRetake: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.scannedImage = scannedImage
        self.initialText  = initialText
        self.onSave       = onSave
        self.onRetake     = onRetake
        self.onDismiss    = onDismiss
        self._editedText  = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        headerRow
                        scannedPreview
                        MoodSelector(selectedMood: $selectedMood)
                            .padding(.horizontal, AppTheme.Spacing.m)
                        titleField
                        textEditor
                        tagsField
                        actionButtons
                        Spacer(minLength: 40)
                    }
                }
            }
            .hideNavigationBar()
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Review Capture")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            Spacer()
            Button(action: onDismiss) {
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
    }

    private var scannedPreview: some View {
        Image(uiImage: scannedImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.horizontal, AppTheme.Spacing.m)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            label("TITLE")
            TextField("Give your entry a title…", text: $title)
                .fieldStyle()
                .focused($focused, equals: .title)
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }

    private var textEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                label("EXTRACTED TEXT")
                Spacer()
                Label("OCR", systemImage: "text.viewfinder")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentGold)
            }
            ZStack(alignment: .topLeading) {
                if editedText.isEmpty {
                    Text("No text detected — type your notes here…")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.system(size: 16))
                        .padding(.top, AppTheme.Spacing.m)
                        .padding(.leading, AppTheme.Spacing.m)
                }
                TextEditor(text: $editedText)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .tint(AppTheme.Colors.accentGold)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(AppTheme.Spacing.s)
                    .focused($focused, equals: .text)
            }
            .padding(AppTheme.Spacing.s)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            label("TAGS")
            TextField("morning, gratitude, growth…", text: $tags)
                .fieldStyle()
                .focused($focused, equals: .tags)
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            GlowButton(title: "Save Entry", icon: "checkmark") {
                let tagList = tags.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                onSave(editedText, selectedMood, title, tagList)
            }
            .disabled(editedText.isEmpty)

            Button(action: onRetake) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                    Text("Retake Scan")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.Colors.textTertiary)
            .tracking(1.2)
    }
}

// MARK: - TextField helper modifier

private extension View {
    func fieldStyle() -> some View {
        self
            .font(.system(size: 15))
            .foregroundColor(AppTheme.Colors.textPrimary)
            .tint(AppTheme.Colors.accentGold)
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
    }
}
