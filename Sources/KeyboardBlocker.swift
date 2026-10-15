import AppKit
import ApplicationServices

enum LockMode: String, CaseIterable, Identifiable {
    case clean, away
    var id: String { rawValue }
    var title: String { self == .clean ? "Clean" : "Away" }
    var symbol: String { self == .clean ? "sparkles" : "pawprint.fill" }
}

/// Auto follows the macOS light/dark setting (and switches with it); Light and Dark pin one look.
enum Appearance: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var nsAppearance: NSAppearance? {
        switch self {
        case .auto: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

/// What happened during the last lock, shown after the keyboard is released.
struct LockSummary {
    let mode: LockMode
    let duration: TimeInterval
    let keys: Int
    let pawTriggered: Bool
    let reason: String? // set when released automatically (screen locked, sleep, ...)
    var endedAt = Date()
}

/// Lifetime totals, kept only on this Mac (UserDefaults) and never sent anywhere.
struct PawStats: Codable, Equatable {
    var keysStopped = 0    // every key swallowed, any mode
    var pawKeys = 0        // keys swallowed in Away mode: the pets' share
    var pawAmbushes = 0    // times paw detection locked the keyboard
    var cleanSessions = 0
    var awaySessions = 0

    var isEmpty: Bool { keysStopped == 0 && cleanSessions == 0 && awaySessions == 0 }
}

/// Owns one session-level CGEventTap for the app's lifetime. While unlocked it passes every
/// event through (watching only for the global shortcut and paw patterns); while locked it
/// swallows every keyboard event. Any lock, sleep or user switch releases the keyboard.
final class KeyboardBlocker: ObservableObject {
    // Live state
    @Published private(set) var isActive = false
    @Published private(set) var hasPermission = false
    @Published private(set) var activeMode: LockMode = .clean
    @Published private(set) var keysCaught = 0
    @Published private(set) var pawTriggered = false
    @Published private(set) var lockedAt: Date?
    @Published private(set) var endsAt: Date?
    @Published private(set) var lastSummary: LockSummary?

    // Settings, persisted in UserDefaults
    @Published var mode: LockMode = .clean { didSet { save(mode.rawValue, Keys.mode) } }
    @Published var timerSeconds = 0 { didSet { save(timerSeconds, Keys.timer) } }
    /// Last custom auto-unlock length (seconds). Custom is a one-off choice: it isn't remembered as
    /// the selection, and the app goes back to No timer once that lock ends.
    @Published private(set) var customSeconds = 180 { didSet { save(customSeconds, Keys.customSeconds) } }
    @Published private(set) var timerIsCustom = false
    @Published private(set) var stats = PawStats() { didSet { saveStats() } }
    @Published var unlockPhrase = "unlock" { didSet { save(unlockPhrase, Keys.phrase) } }
    @Published var pawDetection = true { didSet { save(pawDetection, Keys.paw) } }
    @Published var appearance: Appearance = .auto { didSet { save(appearance.rawValue, Keys.appearance) } }

    static let timerChoices = [0, 120]
    /// Custom lengths start just above the 2 min preset and go up to 99:59.
    static let customRange = 121...5999
    static let shortcutLabel = "⌃⌥⌘L"
    private static let shortcutKeyCode: Int64 = 37 // kVK_ANSI_L

    private enum Keys {
        static let mode = "mode", timer = "timerSeconds", phrase = "unlockPhrase", paw = "pawDetection"
        static let appearance = "appearance"
        static let customSeconds = "customSeconds", stats = "pawStats"
    }

    private var persists = false
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private var unlockTimer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var typed = ""
    private var heldKeys: [Int64: Date] = [:]

    init() {
        let defaults = UserDefaults.standard
        mode = LockMode(rawValue: defaults.string(forKey: Keys.mode) ?? "") ?? .clean
        timerSeconds = defaults.object(forKey: Keys.timer) as? Int ?? 0
        unlockPhrase = defaults.string(forKey: Keys.phrase) ?? "unlock"
        pawDetection = defaults.object(forKey: Keys.paw) as? Bool ?? true
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .auto
        customSeconds = Self.clampCustom(defaults.object(forKey: Keys.customSeconds) as? Int ?? 180)
        if !Self.timerChoices.contains(timerSeconds) {
            timerSeconds = 0 // old 30 s / 1 min choices, or a past custom length: back to the default
        }
        if let data = defaults.data(forKey: Keys.stats), let saved = try? JSONDecoder().decode(PawStats.self, from: data) {
            stats = saved
        }
        hasPermission = AXIsProcessTrusted()
        persists = true

        watchForLockAndSleep()
        if hasPermission { installTap() } else { pollPermission() }
    }

    /// For off-screen renders: no tap, no observers, never touches UserDefaults.
    private init(previewOnly: Void) {}

    /// Picks one of the preset timer lengths (0 = no timer).
    func selectTimer(_ seconds: Int) {
        timerIsCustom = false
        timerSeconds = seconds
    }

    /// Switches to a custom length, starting from the last one the user entered.
    func selectCustomTimer() {
        timerIsCustom = true
        timerSeconds = customSeconds
    }

    func setCustomSeconds(_ seconds: Int) {
        customSeconds = Self.clampCustom(seconds)
        if timerIsCustom { timerSeconds = customSeconds }
    }

    /// − / + move to the previous or next whole minute (2:01 → 3:00 → 4:00, and back down to 2:01).
    func stepCustom(up: Bool) {
        let s = customSeconds
        setCustomSeconds(up ? (s / 60 + 1) * 60 : (s % 60 == 0 ? s - 60 : s / 60 * 60))
    }

    func resetStats() { stats = PawStats() }

    static func clampCustom(_ seconds: Int) -> Int {
        min(max(seconds, customRange.lowerBound), customRange.upperBound)
    }

    /// "2:01", "15:00"
    static func clock(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }

    /// Accepts "5" (minutes) or "2:15" (minutes:seconds).
    static func parseClock(_ text: String) -> Int? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: ":", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count), let minutes = Int(parts[0]) else { return nil }
        let seconds = parts.count == 2 ? Int(parts[1]) : 0
        guard let seconds, (0..<60).contains(seconds) else { return nil }
        return minutes * 60 + seconds
    }

    var trimmedPhrase: String { unlockPhrase.trimmingCharacters(in: .whitespaces).lowercased() }

    // MARK: Lock / unlock

    func toggle() { isActive ? stop() : start() }

    func start(mode requested: LockMode? = nil, byPaws: Bool = false) {
        guard !isActive else { return }
        guard hasPermission, tap != nil else { requestPermission(); return }

        activeMode = requested ?? mode
        pawTriggered = byPaws
        keysCaught = byPaws ? heldKeys.count : 0
        typed = ""
        heldKeys = [:]
        lastSummary = nil
        let now = Date()
        lockedAt = now

        if activeMode == .clean && timerSeconds > 0 {
            let end = now.addingTimeInterval(TimeInterval(timerSeconds))
            endsAt = end
            let timer = Timer(fire: end, interval: 0, repeats: false) { [weak self] _ in self?.stop() }
            RunLoop.main.add(timer, forMode: .common)
            unlockTimer = timer
        } else {
            endsAt = nil
        }
        isActive = true
    }

    func stop(reason: String? = nil) {
        guard isActive else { return }
        unlockTimer?.invalidate()
        unlockTimer = nil
        lastSummary = LockSummary(
            mode: activeMode,
            duration: Date().timeIntervalSince(lockedAt ?? Date()),
            keys: keysCaught,
            pawTriggered: pawTriggered,
            reason: reason
        )
        var totals = stats
        totals.keysStopped += keysCaught
        if activeMode == .away {
            totals.pawKeys += keysCaught
            totals.awaySessions += 1
        } else {
            totals.cleanSessions += 1
        }
        if pawTriggered { totals.pawAmbushes += 1 }
        stats = totals
        isActive = false
        lockedAt = nil
        endsAt = nil
        pawTriggered = false
        typed = ""
        heldKeys = [:]
    }

    // MARK: Event tap

    private func installTap() {
        guard tap == nil else { return }

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
            return blocker.shouldSwallow(type, event) ? nil : Unmanaged.passUnretained(event)
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
    }

    /// Runs on the main run loop for every keyboard event. Keep it cheap.
    private func shouldSwallow(_ type: CGEventType, _ event: CGEvent) -> Bool {
        if type == .keyDown && isShortcut(event) {
            toggle()
            return true
        }
        if isActive {
            if type == .keyDown {
                keysCaught += 1
                if phraseTyped(event) { stop() }
            }
            return true
        }
        if pawDetection && looksLikePaws(type, event) {
            start(mode: .away, byPaws: true)
            return true
        }
        return false
    }

    private func isShortcut(_ event: CGEvent) -> Bool {
        let flags = event.flags
        return event.getIntegerValueField(.keyboardEventKeycode) == Self.shortcutKeyCode
            && flags.contains([.maskControl, .maskAlternate, .maskCommand])
            && !flags.contains(.maskShift)
            && event.getIntegerValueField(.keyboardEventAutorepeat) == 0
    }

    /// Keeps the last few typed characters and reports when they spell the unlock phrase.
    private func phraseTyped(_ event: CGEvent) -> Bool {
        let phrase = trimmedPhrase
        guard !phrase.isEmpty,
              let chars = NSEvent(cgEvent: event)?.charactersIgnoringModifiers?.lowercased(),
              !chars.isEmpty
        else { return false }
        typed = String((typed + chars).suffix(phrase.count))
        return typed == phrase
    }

    /// A paw walking across the keyboard holds several letter keys at once; a sitting cat
    /// holds a couple of keys down for seconds. People rarely do either while typing.
    private func looksLikePaws(_ type: CGEventType, _ event: CGEvent) -> Bool {
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        let now = Date()
        switch type {
        case .keyDown:
            if heldKeys[key] == nil { heldKeys[key] = now }
        case .keyUp:
            heldKeys[key] = nil
            return false
        default:
            return false // modifiers arrive as flagsChanged and never count
        }

        heldKeys = heldKeys.filter { now.timeIntervalSince($0.value) < 30 } // forget missed key-ups
        let mashing = heldKeys.count >= 4
        let sitting = heldKeys.count >= 2 && heldKeys.values.allSatisfy { now.timeIntervalSince($0) >= 3 }
        return (mashing || sitting) && !Self.screenIsLocked()
    }

    private static func screenIsLocked() -> Bool {
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return session["CGSSessionScreenIsLocked"] as? Bool ?? false
    }

    // MARK: Permission

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasPermission = AXIsProcessTrustedWithOptions(options)
        if hasPermission { installTap() } else { pollPermission() }
    }

    /// Clears a stale grant (e.g. one left by an older build) so macOS asks again.
    func resetPermission() {
        let tccutil = Process()
        tccutil.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        tccutil.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "local.pawsoff"]
        try? tccutil.run()
        tccutil.waitUntilExit()
        requestPermission()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func pollPermission() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if AXIsProcessTrusted() {
                timer.invalidate()
                self.hasPermission = true
                self.installTap()
            }
        }
    }

    private func saveStats() {
        if persists, let data = try? JSONEncoder().encode(stats) { UserDefaults.standard.set(data, forKey: Keys.stats) }
    }

    private func save(_ value: Any, _ key: String) {
        if persists { UserDefaults.standard.set(value, forKey: key) }
    }

    // MARK: Auto-release

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
        unlockTimer?.invalidate()
        permissionTimer?.invalidate()
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        observers.forEach { $0.0.removeObserver($0.1) }
    }
}

// MARK: - Preview states

extension KeyboardBlocker {
    enum PreviewState: String, CaseIterable {
        case needsPermission, cleanReady, cleanCustom, withStats, cleanTimer, awayReady, awayLocked, pawsDetected, backFromAway, autoReleased
    }

    static func preview(_ state: PreviewState) -> KeyboardBlocker {
        let b = KeyboardBlocker(previewOnly: ())
        b.hasPermission = state != .needsPermission
        let now = Date()
        func lock(_ mode: LockMode, keys: Int, since: TimeInterval) {
            b.mode = mode
            b.activeMode = mode
            b.isActive = true
            b.keysCaught = keys
            b.lockedAt = now.addingTimeInterval(-since)
        }
        switch state {
        case .needsPermission:
            break
        case .cleanReady:
            b.timerSeconds = 120
        case .cleanCustom:
            b.setCustomSeconds(150)
            b.selectCustomTimer()
        case .withStats:
            b.stats = PawStats(keysStopped: 3_118, pawKeys: 2_431, pawAmbushes: 9, cleanSessions: 14, awaySessions: 22)
        case .cleanTimer:
            b.timerSeconds = 60
            b.stats = PawStats(keysStopped: 40, cleanSessions: 2)
            lock(.clean, keys: 18, since: 20)
            b.endsAt = now.addingTimeInterval(40)
        case .awayReady:
            b.mode = .away
        case .awayLocked:
            lock(.away, keys: 7, since: 300)
        case .pawsDetected:
            lock(.away, keys: 63, since: 45)
            b.pawTriggered = true
        case .backFromAway:
            b.mode = .away
            b.lastSummary = LockSummary(mode: .away, duration: 47 * 60, keys: 214, pawTriggered: true, reason: nil)
        case .autoReleased:
            b.lastSummary = LockSummary(mode: .clean, duration: 95, keys: 31, pawTriggered: false, reason: "Screen locked")
        }
        return b
    }
}
