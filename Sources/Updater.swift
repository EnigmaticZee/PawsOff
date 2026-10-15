import SwiftUI
import Sparkle

/// Automatic updates via Sparkle. Checks the appcast attached to the latest GitHub release (about
/// once a day, if the user leaves that on) and installs only updates signed with our key.
@MainActor
final class Updater: ObservableObject {
    static let shared = Updater()

    private let controller: SPUStandardUpdaterController
    @Published var automaticallyChecks: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticallyChecks }
    }

    private init() {
        // Off-screen renders must not start a real updater.
        let start = !CommandLine.arguments.contains("--render-previews")
        controller = SPUStandardUpdaterController(startingUpdater: start, updaterDelegate: nil, userDriverDelegate: nil)
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
    }

    func checkForUpdates() {
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}
