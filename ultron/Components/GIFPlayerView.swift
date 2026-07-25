import SwiftUI
import WebKit

/// Renders an animated GIF from an NSDataAsset (Assets.xcassets .dataset)
/// using WebKit for smooth, frame-accurate playback — identical quality to Safari.
///
/// Usage:
///   GIFPlayerView(assetName: "compass_demo")
///       .frame(width: 300, height: 300)
///       .clipShape(RoundedRectangle(cornerRadius: 16))
struct GIFPlayerView: UIViewRepresentable {
    let assetName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque            = false
        webView.backgroundColor     = .clear
        webView.scrollView.isScrollEnabled  = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator   = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let asset = NSDataAsset(name: assetName) else { return }
        // Load raw GIF bytes directly — WebKit renders at native frame rate.
        webView.load(asset.data,
                     mimeType: "image/gif",
                     characterEncodingName: "",
                     baseURL: URL(fileURLWithPath: ""))
    }
}
