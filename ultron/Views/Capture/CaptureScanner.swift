import SwiftUI
import PhotosUI

#if !targetEnvironment(simulator)
import VisionKit
#endif

/// SwiftUI view wrapper for the document capture image source.
///
/// Public contract is identical on both paths — onScan([UIImage]) feeds straight
/// into OCRService → ReviewCaptureView → JournalViewModel with zero duplication.
///
///   Real device  →  VNDocumentCameraViewController (VisionKit)
///   Simulator    →  PHPickerViewController (PhotosUI) — VisionKit is unavailable
struct CaptureScanner: View {
    let onScan:   ([UIImage]) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
#if targetEnvironment(simulator)
        _PhotoPicker(
            onScan:   { pages in dismiss(); onScan(pages) },
            onCancel: { dismiss(); onCancel() }
        )
        .ignoresSafeArea()
#else
        _DocumentCamera(
            onScan:   { pages in dismiss(); onScan(pages) },
            onCancel: { dismiss(); onCancel() }
        )
        .ignoresSafeArea()
#endif
    }
}

// MARK: - Simulator path: PHPickerViewController

#if targetEnvironment(simulator)
private struct _PhotoPicker: UIViewControllerRepresentable {
    var onScan:   ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {
        context.coordinator.onScan   = onScan
        context.coordinator.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan, onCancel: onCancel) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onScan:   ([UIImage]) -> Void
        var onCancel: () -> Void

        init(onScan: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScan   = onScan
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let first = results.first else { onCancel(); return }
            first.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.onScan([image])
                    } else {
                        self?.onCancel()
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Device path: VNDocumentCameraViewController

#if !targetEnvironment(simulator)
private struct _DocumentCamera: UIViewControllerRepresentable {
    var onScan:   ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc      = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {
        context.coordinator.onScan   = onScan
        context.coordinator.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan, onCancel: onCancel) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScan:   ([UIImage]) -> Void
        var onCancel: () -> Void

        init(onScan: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScan   = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            onScan((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onCancel()
        }
    }
}
#endif
