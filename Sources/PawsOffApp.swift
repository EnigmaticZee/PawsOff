import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceWatch: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let blocker = KeyboardBlocker.shared
        // Set on the app so the window and the menu bar panel match, and Auto follows the system live.
        appearanceWatch = blocker.$appearance.sink { NSApp.appearance = $0.nsAppearance }

        // Paws Off starts as a menu bar app (LSUIElement), so nothing flashes in the Dock. The window
        // opens when the user chose it, and always while keyboard access still needs granting.
        let snapshot = CommandLine.arguments.contains("--snapshot-window")
        if snapshot || blocker.launchPlace == .window || !blocker.hasPermission {
            MainWindow.show()
        }
    }

    /// Opening the app again (Finder, Spotlight, Dock) brings up the window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindow.show()
        return false
    }

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
    @ObservedObject private var blocker = KeyboardBlocker.shared

    var body: some Scene {
        // The card one click away in the menu bar. The window (same card) is opened by MainWindow.
        MenuBarExtra {
            CardView(place: .panel)
                .environmentObject(blocker)
        } label: {
            Image(systemName: blocker.isActive ? "pawprint.circle.fill" : "pawprint.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
