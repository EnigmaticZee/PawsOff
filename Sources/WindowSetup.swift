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
        guard NSApp.activationPolicy() != .regular, NSApp.isActive else {
            NSApp.setActivationPolicy(.regular)
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        // A menu bar app that becomes a Dock app while it's frontmost (e.g. opened from the menu
        // bar panel) gets menus that don't open until it's activated again. So step back to the
        // Dock for a moment, switch while in the background, then come forward.
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.regular)
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
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

/// The menu bar menus shown while the window is open: the app menu, Edit (so copy and paste work
/// in text fields) and Window.
enum AppMenu {
    static func make() -> NSMenu {
        let main = NSMenu()

        let app = NSMenu()
        app.addItem(withTitle: "About Paws Off", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "Hide Paws Off", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: "Quit Paws Off", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(submenu(app, title: "Paws Off"))

        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        main.addItem(submenu(edit, title: "Edit"))

        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        main.addItem(submenu(window, title: "Window"))
        NSApp.windowsMenu = window
        return main
    }

    private static func submenu(_ menu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }
}
