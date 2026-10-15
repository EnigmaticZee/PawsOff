import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep running in the menu bar (and keep the shortcut and paw detection alive) when the window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@main
struct PawsOffApp {
    static func main() {
        // `PawsOff --render-previews <dir>` writes PNGs of every UI state and exits.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-previews"), i + 1 < args.count {
            MainActor.assumeIsolated {
                PreviewRenderer.renderAll(to: URL(fileURLWithPath: args[i + 1]))
            }
            exit(0)
        }
        PawsOffScene.main()
    }
}

struct PawsOffScene: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var blocker = KeyboardBlocker()

    var body: some Scene {
        Window("Paws Off", id: "main") {
            ContentView()
                .environmentObject(blocker)
                .background(WindowConfigurator())
                // Set on the app (not .preferredColorScheme) so Auto reliably goes back to following
                // the system, live, and the Settings sheet and menu bar menu match the window.
                .onChange(of: blocker.appearance, initial: true) { NSApp.appearance = blocker.appearance.nsAppearance }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarContent().environmentObject(blocker)
        } label: {
            Image(systemName: blocker.isActive ? "pawprint.circle.fill" : "pawprint.fill")
        }
    }
}

/// Transparent title bar, draggable anywhere, no zoom button.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
