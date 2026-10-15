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
        // `PawsOff --snapshot-window <file.png>` launches normally, photographs its own window
        // (title bar included) and quits. Unlike the off-screen previews this shows the real layout.
        if let i = args.firstIndex(of: "--snapshot-window"), i + 1 < args.count {
            let path = args[i + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let frame = NSApp.windows.filter({ $0.isVisible && $0.contentView != nil })
                    .max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })?.contentView?.superview,
                   let rep = frame.bitmapImageRepForCachingDisplay(in: frame.bounds) {
                    frame.cacheDisplay(in: frame.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                }
                exit(0)
            }
        }
        PawsOffScene.main()
    }
}

struct PawsOffScene: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var blocker = KeyboardBlocker()

    var body: some Scene {
        // The compact card in a small window...
        Window("Paws Off", id: "main") {
            CardView(place: .window)
                .environmentObject(blocker)
                .background(WindowConfigurator())
                // Set on the app (not .preferredColorScheme) so Auto reliably goes back to following
                // the system, live, and the menu bar panel matches the window.
                .onChange(of: blocker.appearance, initial: true) { NSApp.appearance = blocker.appearance.nsAppearance }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // ...and the same card one click away in the menu bar.
        MenuBarExtra {
            CardView(place: .panel)
                .environmentObject(blocker)
        } label: {
            Image(systemName: blocker.isActive ? "pawprint.circle.fill" : "pawprint.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
