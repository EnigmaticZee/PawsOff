import SwiftUI
import Combine
import Sparkle

/// Automatic updates via Sparkle. Checks the appcast attached to the latest GitHub release shortly
/// after launch and about once a day after that (if the user leaves that on), downloads new versions
/// quietly and installs them, accepting only updates signed with our key.
@MainActor
final class Updater: ObservableObject {
    static let shared = Updater()

    private let controller: SPUStandardUpdaterController
    private let installer = InstallWhenUnlocked()
    @Published var automaticallyChecks: Bool {
        didSet {
            controller.updater.automaticallyChecksForUpdates = automaticallyChecks
            controller.updater.automaticallyDownloadsUpdates = automaticallyChecks
        }
    }

    private init() {
        // Off-screen renders must not start a real updater.
        let start = !CommandLine.arguments.contains("--render-previews")
        controller = SPUStandardUpdaterController(startingUpdater: start, updaterDelegate: installer, userDriverDelegate: nil)
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
        if start && automaticallyChecks {
            controller.updater.automaticallyDownloadsUpdates = true
            // Sparkle skips the very first launch and then waits a day between checks; also check
            // shortly after every launch so a new version arrives promptly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [controller] in
                controller.updater.checkForUpdatesInBackground()
            }
        }
    }

    func checkForUpdates() {
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}

/// Sparkle normally installs a downloaded update when the app quits, which a menu bar app rarely
/// does. Install it straight away instead (Paws Off relaunches in a moment), but never while the
/// keyboard is locked: then wait for the unlock.
private final class InstallWhenUnlocked: NSObject, SPUUpdaterDelegate {
    private var wait: AnyCancellable?

    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem,
                 immediateInstallationBlock install: @escaping () -> Void) -> Bool {
        MainActor.assumeIsolated {
            wait = KeyboardBlocker.shared.$isActive
                .receive(on: DispatchQueue.main)
                .first { !$0 }
                .sink { _ in install() }
        }
        return true
    }
}
