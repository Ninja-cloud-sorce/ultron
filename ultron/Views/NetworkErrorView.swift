import SwiftUI

struct NetworkErrorView: View {
    @EnvironmentObject private var network: NetworkMonitor

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Hero: scaledToFill fills the full width and exactly half the screen.
                    // clipped() crops the white snow strip at the image bottom so only the
                    // sky + bird are visible — no white gaps against the dark background.
                    // geo.size.height already includes the top safe area because ignoresSafeArea
                    // is applied to the GeometryReader below.
                    Image("net-off")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.50)
                        .clipped()
                        .allowsHitTesting(false)

                    Spacer()

                    // Title
                    Text("No Internet Connection")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 12)

                    // Subtitle
                    Text("You're offline.\nReconnect to continue your journey.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 48)

                    Spacer().frame(height: 44)

                    // Retry button
                    Button(action: { network.retry() }) {
                        HStack(spacing: 10) {
                            if network.isRetrying {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.85)
                            }
                            Text(network.isRetrying ? "Checking…" : "Retry")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.Colors.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(network.isRetrying)
                    .padding(.horizontal, 40)

                    // Clears the home indicator on all devices (SE has no indicator, returns 0).
                    Spacer().frame(height: max(geo.safeAreaInsets.bottom + 16, 40))
                }
            }
        }
        // Makes geo.size.height equal to the full physical screen height (including the
        // Dynamic Island / notch safe area) so the image bleeds edge-to-edge at the top.
        .ignoresSafeArea(edges: .top)
        .accessibilityElement(children: .contain)
    }
}
