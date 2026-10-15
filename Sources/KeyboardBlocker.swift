import AppKit
import ApplicationServices

/// Swallows every keyboard event via a session-level CGEventTap while active,
/// and releases automatically whenever the Mac locks, sleeps or switches user.
final class KeyboardBlocker: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var hasPermission = AXIsProcessTrusted()
    @Published private(set) var keysCaught = 0
    @Published private(set) var lastAutoReleaseReason: String?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init() {
        watchForLockAndSleep()
        if !hasPermission { pollPermission() }
    }

    /// A static instance for off-screen renders; it never installs a tap.
    private init(preview active: Bool, permission: Bool, caught: Int, reason: String?) {
        isActive = active
        hasPermission = permission
        keysCaught = caught
        lastAutoReleaseReason = reason
    }

    static func preview(active: Bool = false, permission: Bool = true, caught: Int = 0, reason: String? = nil) -> KeyboardBlocker {
        KeyboardBlocker(preview: active, permission: permission, caught: caught, reason: reason)
    }

    func toggle() { isActive ? stop() : start() }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasPermission = AXIsProcessTrustedWithOptions(options)
        if !hasPermission { pollPermission() }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func start() {
        guard !isActive else { return }
        guard AXIsProcessTrusted() else { requestPermission(); return }

        // Key presses, key releases, modifier changes, and system-defined events
        // (media / brightness / volume keys arrive as NX_SYSDEFINED = 14).
        let types: [UInt32] = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
            14,
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let blocker = Unmanaged<KeyboardBlocker>.fromOpaque(refcon).takeUnretainedValue()

            // macOS disables taps that are slow or interrupted; switch it straight back on.
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = blocker.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                return Unmanaged.passUnretained(event)
            }
            if type == .keyDown { blocker.keysCaught += 1 }
            return nil // swallow the event
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            hasPermission = false
            pollPermission()
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        keysCaught = 0
        lastAutoReleaseReason = nil
        isActive = true
    }

    func stop(reason: String? = nil) {
        guard isActive else { return }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        isActive = false
        lastAutoReleaseReason = reason
    }

    private func pollPermission() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if AXIsProcessTrusted() {
                self.hasPermission = true
                timer.invalidate()
            }
        }
    }

    /// Any of these mean the user is heading to (or already at) the login / lock screen,
    /// so hand the keyboard back immediately.
    private func watchForLockAndSleep() {
        let distributed = DistributedNotificationCenter.default()
        let workspace = NSWorkspace.shared.notificationCenter

        let events: [(NotificationCenter, Notification.Name, String)] = [
            (distributed, Notification.Name("com.apple.screenIsLocked"), "Screen locked"),
            (distributed, Notification.Name("com.apple.screensaver.didstart"), "Screen saver started"),
            (workspace, NSWorkspace.sessionDidResignActiveNotification, "Switched user"),
            (workspace, NSWorkspace.screensDidSleepNotification, "Display slept"),
            (workspace, NSWorkspace.willSleepNotification, "Mac went to sleep"),
            (workspace, NSWorkspace.willPowerOffNotification, "Shutting down"),
        ]

        for (center, name, reason) in events {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.stop(reason: reason)
            }
            observers.append((center, token))
        }
    }

    deinit {
        stop()
        observers.forEach { $0.0.removeObserver($0.1) }
    }
}
