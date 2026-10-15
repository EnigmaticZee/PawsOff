import SwiftUI
import AppKit
import Combine

extension Notification.Name {
    static let pawsOffOpenSettings = Notification.Name("PawsOffOpenSettings")
}

/// Height of the window's title bar + toolbar, measured from the real window once it exists
/// (it differs between macOS versions). The layout reads it so the window is exactly 620 pt tall.
final class WindowMetrics: ObservableObject {
    static let shared = WindowMetrics()
    @Published var titleBarHeight: CGFloat = 40
}

/// The settings button lives in a real window toolbar, so macOS places it: vertically centred with
/// the window buttons, inset from the rounded corner the way that macOS version's design expects,
/// with the system's own hover and press states.
final class SettingsToolbar: NSObject, NSToolbarDelegate {
    static let settingsID = NSToolbarItem.Identifier("settings")
    private var item: NSToolbarItem?
    private var lockWatch: AnyCancellable?

    init(blocker: KeyboardBlocker) {
        super.init()
        // Hidden while the keyboard is locked, like the rest of the controls.
        lockWatch = blocker.$isActive.receive(on: DispatchQueue.main).sink { [weak self] locked in
            guard let item = self?.item else { return }
            if #available(macOS 15.0, *) { item.isHidden = locked } else { item.isEnabled = !locked }
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.settingsID]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.settingsID]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard id == Self.settingsID else { return nil }
        let item = NSToolbarItem(itemIdentifier: id)
        item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
        item.label = "Settings"
        item.toolTip = "Settings"
        item.isBordered = false
        item.target = self
        item.action = #selector(openSettings)
        self.item = item
        return item
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .pawsOffOpenSettings, object: nil)
    }
}

/// Window setup: transparent title bar, draggable anywhere, no zoom button, the settings toolbar,
/// and leaving the Dock while the window is closed (Paws Off keeps running in the menu bar).
struct WindowConfigurator: NSViewRepresentable {
    let blocker: KeyboardBlocker

    final class Coordinator {
        var toolbarDelegate: SettingsToolbar? // NSToolbar holds its delegate weakly
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

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

            if window.toolbar == nil {
                let delegate = SettingsToolbar(blocker: blocker)
                context.coordinator.toolbarDelegate = delegate
                let toolbar = NSToolbar(identifier: "PawsOffMain")
                toolbar.delegate = delegate
                toolbar.displayMode = .iconOnly
                toolbar.allowsUserCustomization = false
                window.toolbar = toolbar
                window.toolbarStyle = .unifiedCompact
            }
            WindowMetrics.shared.titleBarHeight = window.frame.height - window.contentLayoutRect.height

            NSApp.setActivationPolicy(.regular)
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
                NSApp.setActivationPolicy(.accessory)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
