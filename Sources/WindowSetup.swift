import SwiftUI
import AppKit

/// The app window: the same card as the menu bar panel, in a small window. Paws Off opens it
/// itself (rather than SwiftUI opening it at launch), so it can start in the menu bar only.
/// While it's open Paws Off is in the Dock; once it closes, Paws Off leaves the Dock and keeps
/// running in the menu bar.
@MainActor
enum MainWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil { window = makeWindow() }
        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private static func makeWindow() -> NSWindow {
        // The card sits below the title bar and its background runs up behind the window buttons;
        // SwiftUI sizes the window to card + title bar.
        let size = CardView.size
        let card = CardView(place: .window)
            .environmentObject(KeyboardBlocker.shared)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: card)
        window.title = "Paws Off"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.standardWindowButton(.zoomButton)?.isHidden = true
        // Remember where the user put the window, but always use the card's exact size.
        window.center()
        window.setFrameAutosaveName("PawsOffMain")
        window.setContentSize(size)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            NSApp.setActivationPolicy(.accessory)
        }
        return window
    }
}
