import SwiftUI
import AppKit
import Combine

/// The paw in the menu bar. Left-click drops down the card (the same one as the window), like the
/// system's own menu bar panels; right-click (or Control-click) shows quick actions. Built on NSStatusItem because SwiftUI's
/// MenuBarExtra can't tell the two clicks apart.
@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var item: NSStatusItem?
    private var panel: DropDownPanel?
    private var tip: DropDownPanel?
    private var watches: Set<AnyCancellable> = []
    private let blocker = KeyboardBlocker.shared

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.setAccessibilityLabel("Paws Off")
        self.item = item

        let card = NSHostingView(rootView: CardView(place: .panel).environmentObject(blocker))
        card.frame.size = CardView.size
        panel = DropDownPanel(content: card, takesFocus: true) { [weak self] in self?.item?.button?.highlight(false) }

        blocker.$isActive.sink { [weak self] locked in self?.updateIcon(locked: locked) }.store(in: &watches)
        // Give the panel the app's look (the Appearance setting, or the system's when that's Auto)
        // rather than the menu bar's, and follow changes live.
        Publishers.CombineLatest(blocker.$appearance, NSApp.publisher(for: \.effectiveAppearance))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, app in
                let dark = app.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                self?.panel?.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
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
            togglePanel()
        }
    }

    func togglePanel() {
        guard let button = item?.button, let panel else { return }
        if panel.isVisible {
            panel.dismiss()
        } else {
            tip?.dismiss()
            panel.show(under: button)
            // Like the system's items, the paw stays highlighted while its panel is open (set after
            // the click finishes, which would otherwise clear it).
            DispatchQueue.main.async { button.highlight(true) }
        }
    }

    func closePanel() { panel?.dismiss() }

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

        // Attach just for this click, so a plain left-click still opens the panel.
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
        let content = NSHostingView(rootView: MenuBarTip(title: title, message: message, link: link) { [weak self] in self?.tip?.dismiss() })
        content.frame.size = content.fittingSize
        let material = NSVisualEffectView(frame: NSRect(origin: .zero, size: content.frame.size))
        material.material = .popover
        material.state = .active
        material.addSubview(content)
        tip = DropDownPanel(content: material, takesFocus: false)
        tip?.show(under: button)
    }
}

/// A panel that drops down from the menu bar paw like the system's own (Control Center, Now
/// Playing, Battery): no arrow, rounded corners and a shadow, just below the menu bar, centred under
/// the paw and kept on screen. Clicking anywhere else or pressing Escape closes it.
final class DropDownPanel: NSPanel {
    private let takesFocus: Bool
    private let onClose: () -> Void
    private var monitors: [Any] = []

    init(content: NSView, takesFocus: Bool, onClose: @escaping () -> Void = {}) {
        self.takesFocus = takesFocus
        self.onClose = onClose
        super.init(contentRect: NSRect(origin: .zero, size: content.frame.size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        level = .popUpMenu
        isFloatingPanel = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        let rounded = NSView(frame: NSRect(origin: .zero, size: content.frame.size))
        rounded.wantsLayer = true
        rounded.layer?.cornerRadius = 16
        rounded.layer?.cornerCurve = .continuous
        rounded.layer?.masksToBounds = true
        rounded.layer?.borderWidth = 0.5
        rounded.layer?.borderColor = NSColor(white: 0.5, alpha: 0.25).cgColor
        content.frame = rounded.bounds
        content.autoresizingMask = [.width, .height]
        rounded.addSubview(content)
        contentView = rounded
    }

    override var canBecomeKey: Bool { takesFocus }

    func show(under button: NSStatusBarButton, attempt: Int = 0) {
        // Right after launch the menu bar may not have placed the paw yet; try again shortly.
        guard let buttonWindow = button.window, let screen = buttonWindow.screen, buttonWindow.frame.width > 0 else {
            if attempt < 10 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.show(under: button, attempt: attempt + 1) } }
            return
        }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = frame.size, visible = screen.visibleFrame, margin: CGFloat = 8
        let x = min(max(anchor.midX - size.width / 2, visible.minX + margin), visible.maxX - size.width - margin)
        setFrameOrigin(NSPoint(x: x, y: anchor.minY - 5 - size.height))
        if takesFocus { makeKeyAndOrderFront(nil) } else { orderFrontRegardless() }

        // Close on a click anywhere else: in other apps (global) or our own windows (local).
        // Clicks on the paw itself are left to the paw, which toggles.
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        } as Any)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self, event.window !== self, event.window !== button.window { self.dismiss() }
            return event
        } as Any)
    }

    func dismiss() {
        guard isVisible else { return }
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors = []
        orderOut(nil)
        onClose()
    }

    override func cancelOperation(_ sender: Any?) { dismiss() }
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
