import SwiftUI
import AppKit
import Combine

/// The paw in the menu bar. Left-click opens the card (the same one as the window) in a popover;
/// right-click (or Control-click) shows quick actions. Built on NSStatusItem because SwiftUI's
/// MenuBarExtra can't tell the two clicks apart.
@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var item: NSStatusItem?
    private let popover = NSPopover()
    private var watches: Set<AnyCancellable> = []
    private let blocker = KeyboardBlocker.shared

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.setAccessibilityLabel("Paws Off")
        self.item = item

        let host = NSHostingController(rootView: CardView(place: .panel).environmentObject(blocker))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        popover.contentSize = CardView.size
        popover.behavior = .transient

        blocker.$isActive.sink { [weak self] locked in self?.updateIcon(locked: locked) }.store(in: &watches)
        // A popover takes its look from the menu bar, not from the app; give it the app's
        // (the Appearance setting, or the system's when that's Auto) and follow changes live.
        Publishers.CombineLatest(blocker.$appearance, NSApp.publisher(for: \.effectiveAppearance))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, app in
                let dark = app.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                self?.popover.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            }
            .store(in: &watches)
    }

    private func updateIcon(locked: Bool) {
        let image = NSImage(systemSymbolName: locked ? "pawprint.circle.fill" : "pawprint.fill",
                            accessibilityDescription: locked ? "Paws Off: keyboard locked" : "Paws Off")
        image?.isTemplate = true
        item?.button?.image = image
    }

    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        guard let button = item?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate()
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: Right-click menu

    private func showMenu() {
        let menu = NSMenu()
        let status = NSMenuItem(title: blocker.isActive
                                    ? "Keyboard locked · \(blocker.keysCaught) keys caught"
                                    : "Keyboard active",
                                action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        if blocker.isActive {
            menu.addItem(action("Unlock Keyboard", #selector(unlock)))
        } else {
            menu.addItem(action("Lock for Cleaning", #selector(lockForCleaning)))
            menu.addItem(action("Lock While Away", #selector(lockWhileAway)))
        }
        menu.addItem(.separator())
        menu.addItem(action("Open Paws Off Window", #selector(openWindow)))
        menu.addItem(action("Check for Updates…", #selector(checkForUpdates)))
        menu.addItem(action("About Paws Off", #selector(about)))
        menu.addItem(.separator())
        menu.addItem(action("Quit Paws Off", #selector(quit), key: "q"))

        // Attach just for this click, so a plain left-click still opens the popover.
        item?.menu = menu
        item?.button?.performClick(nil)
        item?.menu = nil
    }

    private func action(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        menuItem.target = self
        return menuItem
    }

    @objc private func lockForCleaning() { lock(.clean) }
    @objc private func lockWhileAway() { lock(.away) }
    @objc private func unlock() { blocker.stop() }
    @objc private func openWindow() { MainWindow.show() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func checkForUpdates() { Updater.shared.checkForUpdates() }

    @objc private func about() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    private func lock(_ mode: LockMode) {
        if blocker.hasPermission {
            blocker.start(mode: mode)
        } else {
            MainWindow.show()
            blocker.requestPermission()
        }
    }

    // MARK: Tips

    /// The first time Paws Off starts quietly in the menu bar, point at the paw once.
    func showTipIfNeeded() {
        let key = "shownMenuBarTip"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        showTip(title: "Paws Off lives here", message: "Click the paw to lock your keyboard. Right-click for quick actions.")
    }

    /// After Paws Off has updated itself, say so once, under the paw. Returns whether it did.
    @discardableResult
    func showUpdatedNoteIfNeeded() -> Bool {
        let defaults = UserDefaults.standard, key = "lastRunVersion"
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        // Versions before 2.0.2 didn't record this; their update checks did leave a timestamp.
        let previous = defaults.string(forKey: key) ?? (defaults.object(forKey: "SULastCheckTime") != nil ? "" : nil)
        defaults.set(current, forKey: key)
        guard let previous, previous != current else { return false }
        showTip(title: "Updated to Paws Off \(current)", message: "Paws Off updated itself. See what's new on the release page.",
                link: URL(string: "https://github.com/EnigmaticZee/PawsOff/releases/tag/v\(current)"))
        return true
    }

    private func showTip(title: String, message: String, link: URL? = nil) {
        guard let button = item?.button else { return }
        let tip = NSPopover()
        tip.behavior = .transient
        tip.contentViewController = NSHostingController(rootView: MenuBarTip(title: title, message: message, link: link) { tip.performClose(nil) })
        tip.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

/// A small bubble under the menu bar paw: "Paws Off lives here" once, and "Updated to …" after an update.
struct MenuBarTip: View {
    var title: String
    var message: String
    var link: URL?
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(LinearGradient(colors: Palette.idle, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            Text(message)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if let link {
                    Button("What's New") { NSWorkspace.shared.open(link); dismiss() }
                }
                Spacer()
                Button("Got it", action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .frame(width: 250)
    }
}
