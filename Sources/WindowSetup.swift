import SwiftUI
import AppKit

/// Window setup: transparent title bar (the card's background runs up behind the window buttons),
/// draggable anywhere, no zoom button, and leaving the Dock while the window is closed (Paws Off
/// keeps running in the menu bar, where the same card is one click away).
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.titlebarSeparatorStyle = .none
            window.backgroundColor = .clear
            window.standardWindowButton(.zoomButton)?.isHidden = true

            NSApp.setActivationPolicy(.regular)
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
                NSApp.setActivationPolicy(.accessory)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
