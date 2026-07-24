import Network
import SwiftUI
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var isRetrying  = false

    private let monitor = NWPathMonitor()
    // userInitiated: higher OS priority → path callbacks fire sooner after a network change.
    private let queue   = DispatchQueue(label: "com.compass.network", qos: .userInitiated)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
        // isConnected stays true (optimistic default) until the first pathUpdateHandler
        // callback fires. Reading monitor.currentPath immediately after start() is unreliable —
        // NWPathMonitor hasn't finished evaluating yet and returns .unsatisfied even when
        // the network is available, which caused a false-positive error screen on launch.
    }

    func retry() {
        guard !isRetrying else { return }
        isRetrying = true
        Task {
            // Brief spinner — feels intentional, not instant.
            try? await Task.sleep(nanoseconds: 350_000_000)
            let connected = monitor.currentPath.status == .satisfied
            isConnected = connected
            isRetrying  = false
            if !connected {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }
}
