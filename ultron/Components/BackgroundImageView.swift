import SwiftUI

struct BackgroundImageView: View {
    let imageName: String
    var gradientFromTop: Bool = false
    var overlayOpacity: Double = 0.35

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                if gradientFromTop {
                    LinearGradient(
                        colors: [AppTheme.Colors.bgPrimary, AppTheme.Colors.bgPrimary.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }

                LinearGradient(
                    colors: [.clear, AppTheme.Colors.bgPrimary.opacity(0.7), AppTheme.Colors.bgPrimary],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct SolidBackgroundView: View {
    var body: some View {
        AppTheme.Colors.bgPrimary.ignoresSafeArea()
    }
}
