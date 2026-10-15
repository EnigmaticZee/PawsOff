import SwiftUI
import AppKit

extension Notification.Name {
    static let pawsOffOpenSettings = Notification.Name("PawsOffOpenSettings")
}

/// The settings button in the window's title bar. It's installed as a native title-bar accessory
/// (NSTitlebarAccessoryViewController), so macOS keeps it vertically centred with the window
/// buttons; the trailing inset mirrors the window buttons' distance from the left edge.
struct SettingsTitlebarButton: View {
    static let size: CGFloat = 28
    static let trailingInset: CGFloat = 3

    @EnvironmentObject var blocker: KeyboardBlocker
    @State private var hovering = false

    var body: some View {
        Button {
            NotificationCenter.default.post(name: .pawsOffOpenSettings, object: nil)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: Self.size, height: Self.size)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.primary.opacity(hovering ? 0.08 : 0)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Settings")
        .opacity(blocker.isActive ? 0 : 1)
        .disabled(blocker.isActive)
        .animation(.easeInOut(duration: 0.2), value: blocker.isActive)
    }
}

/// Window setup: transparent title bar, draggable anywhere, no zoom button, the settings
/// accessory, and leaving the Dock while the window is closed (Paws Off keeps running in the menu bar).
struct WindowConfigurator: NSViewRepresentable {
    let blocker: KeyboardBlocker

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.standardWindowButton(.zoomButton)?.isHidden = true

            if !window.titlebarAccessoryViewControllers.contains(where: { $0.identifier?.rawValue == "settings" }) {
                let titleBarHeight = window.frame.height - window.contentLayoutRect.height
                let host = NSHostingView(rootView: SettingsTitlebarButton()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .environmentObject(blocker))
                host.frame = NSRect(x: 0, y: 0,
                                    width: SettingsTitlebarButton.size + SettingsTitlebarButton.trailingInset,
                                    height: max(titleBarHeight, SettingsTitlebarButton.size))
                let accessory = NSTitlebarAccessoryViewController()
                accessory.identifier = NSUserInterfaceItemIdentifier("settings")
                accessory.layoutAttribute = .trailing
                accessory.view = host
                window.addTitlebarAccessoryViewController(accessory)
            }

            NSApp.setActivationPolicy(.regular)
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
                NSApp.setActivationPolicy(.accessory)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
