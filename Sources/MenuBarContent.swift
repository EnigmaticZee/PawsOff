import SwiftUI

/// The menu under the paw icon in the menu bar.
struct MenuBarContent: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(blocker.isActive
             ? "Keyboard locked · \(blocker.keysCaught) keys caught"
             : "Keyboard active")

        Divider()

        if blocker.isActive {
            Button("Unlock Keyboard") { blocker.stop() }
        } else {
            Button("Lock for Cleaning") { lock(.clean) }
            Button("Lock While Away") { lock(.away) }
        }

        Divider()

        Button("Show Paws Off") { showWindow() }
        Button("Quit Paws Off") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func lock(_ mode: LockMode) {
        if blocker.hasPermission {
            blocker.start(mode: mode)
        } else {
            showWindow()
            blocker.requestPermission()
        }
    }

    private func showWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
