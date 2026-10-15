import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct PawsOffApp {
    static func main() {
        // `PawsOff --render-previews <dir>` writes PNGs of every UI state and exits.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-previews"), i + 1 < args.count {
            PreviewRenderer.renderAll(to: URL(fileURLWithPath: args[i + 1]))
            exit(0)
        }
        PawsOffScene.main()
    }
}

struct PawsOffScene: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var blocker = KeyboardBlocker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blocker)
                .preferredColorScheme(.dark)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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
