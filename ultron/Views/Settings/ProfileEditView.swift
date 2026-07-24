import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject private var settings = SettingsManager.shared
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var photosItem:      PhotosPickerItem? = nil
    @State private var showCamera       = false
    @State private var showSourcePicker = false
    @State private var showPhotosPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        avatarSection
                        fieldsSection
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.accentGold)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    if let data = image?.jpegData(compressionQuality: 0.8) {
                        settings.avatarData = data
                    }
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $photosItem, matching: .images)
            .onChange(of: photosItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        settings.avatarData = data
                    }
                }
            }
            .confirmationDialog("Choose Photo", isPresented: $showSourcePicker) {
                Button("Photo Library") { showPhotosPicker = true }
                Button("Camera")        { showCamera       = true  }
                if settings.avatarData != nil {
                    Button("Remove Photo", role: .destructive) { settings.avatarData = nil }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 16) {
            Button { showSourcePicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let img = settings.avatarImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                AppTheme.Colors.accentGold.opacity(0.2)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppTheme.Colors.accentGold)
                            }
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.Colors.accentGold.opacity(0.5), lineWidth: 2))

                    ZStack {
                        Circle().fill(AppTheme.Colors.accentGold).frame(width: 32, height: 32)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            Text("Tap to change photo")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: 16) {
            editField(label: "Display Name",  placeholder: "Your name",            text: $settings.username)
            editField(label: "Journey Quote", placeholder: "Your personal mantra…", text: $settings.journeyQuote)
        }
        .padding(.horizontal, 20)
    }

    private func editField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .tracking(0.8)

            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .tint(AppTheme.Colors.accentGold)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        }
    }
}

// MARK: - Camera picker wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    var onImage: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uvc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.onImage(info[.originalImage] as? UIImage)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImage(nil)
            parent.dismiss()
        }
    }
}
