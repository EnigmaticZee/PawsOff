import SwiftUI

struct ContentView: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @State private var pulse = false
    @State private var hovering = false
    @State private var showSettings = false
    @State private var customText = ""
    @FocusState private var customFieldFocused: Bool
    @Environment(\.ink) private var ink
    @Environment(\.isPreviewRender) private var isPreviewRender

    /// The window is 620 pt tall in total. Its hidden title bar (32 pt) is part of that: the
    /// content runs up underneath it, and the window buttons sit centred in it.
    private let windowHeight: CGFloat = 620
    private let titleBarHeight: CGFloat = 32

    private var locked: Bool { blocker.isActive }
    private var shownMode: LockMode { locked ? blocker.activeMode : blocker.mode }
    private var accent: [Color] { locked ? Palette.locked : Palette.idle }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background
                // Clicking empty space cancels a custom timer that's being set.
                .contentShape(Rectangle())
                .onTapGesture { cancelCustomTimer() }

            // Spacing follows one rhythm: the top group hangs from the title bar, everything else
            // stacks from the bottom edge with even 20 pt gaps, and the one flexible space sits
            // above the button. The footer has a fixed height, so nothing jumps between states.
            VStack(spacing: 0) {
                ModePicker(mode: $blocker.mode, shown: shownMode, disabled: locked || !blocker.hasPermission)
                    .padding(.top, titleBarHeight + 14)

                Text(statusLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(ink.text(0.55))
                    .contentTransition(.opacity)
                    .padding(.top, 16)

                Spacer(minLength: 0)

                bigButton

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(ink.primary)
                        .contentTransition(.opacity)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(ink.text(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                .padding(.top, 2)

                detailRow
                    .frame(height: 34)
                    .padding(.top, 20)

                footer
                    .frame(height: 64, alignment: .top)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)

            // The settings button itself is a native title-bar accessory (see SettingsTitlebarButton);
            // renders only show stand-ins for the title-bar controls.
            if isPreviewRender { previewTitleBar }
        }
        // Off-screen renders have no title bar, so they get the full height directly. In the real
        // window the frame covers the area below the title bar and the content extends up into it.
        .ignoresSafeArea()
        .frame(width: 380, height: isPreviewRender ? windowHeight : windowHeight - titleBarHeight)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(blocker)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pawsOffOpenSettings)) { _ in
            cancelCustomTimer()
            showSettings = true
        }
        .onChange(of: blocker.mode) { cancelCustomTimer() }
        // A custom length is a one-off: once that lock ends, go back to No timer.
        .onChange(of: blocker.isActive) { _, active in
            if !active && blocker.timerIsCustom { blocker.selectTimer(0) }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: blocker.isActive)
        .animation(.easeInOut(duration: 0.25), value: blocker.mode)
        .animation(.easeInOut(duration: 0.25), value: blocker.hasPermission)
        .onAppear { pulse = true }
    }

    // MARK: Copy

    private var statusLabel: String {
        if locked { return blocker.pawTriggered ? "PAWS DETECTED" : "KEYBOARD LOCKED" }
        return "KEYBOARD ACTIVE"
    }

    private var title: String {
        if !blocker.hasPermission { return "Welcome to Paws Off" }
        if locked {
            if blocker.pawTriggered { return "Caught a paw." }
            return blocker.activeMode == .clean ? "Wipe away." : "Paws off."
        }
        return blocker.mode == .clean ? "Ready to clean?" : "Stepping away?"
    }

    private var unlockHint: String {
        let phrase = blocker.trimmedPhrase
        return phrase.isEmpty
            ? "Click the button when you're back."
            : "Type “\(phrase)” or click the button when you're back."
    }

    private var subtitle: String {
        if !blocker.hasPermission {
            return "Paws Off needs Accessibility access to pause your keyboard."
        }
        if locked {
            if blocker.pawTriggered {
                return "Something walked across your keyboard, so it's locked now. " + unlockHint
            }
            if blocker.activeMode == .clean {
                return blocker.endsAt != nil
                    ? "Every key is ignored. It unlocks by itself when the timer runs out."
                    : "Every key is ignored. Click the button with your trackpad when you're done."
            }
            return "Nothing gets typed while you're gone. " + unlockHint
        }
        return blocker.mode == .clean
            ? "Lock the keyboard while you wipe it down. Your trackpad stays on so you can unlock."
            : "Leave your Mac running without curious paws typing into it."
    }

    // MARK: Pieces

    private var background: some View {
        ZStack {
            LinearGradient(colors: ink.background, startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(accent[0].opacity(0.35 * ink.glow))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -90, y: -130)
            Circle()
                .fill(accent[1].opacity(0.35 * ink.glow))
                .frame(width: 300, height: 300)
                .blur(radius: 110)
                .offset(x: 110, y: 140)
        }
        .ignoresSafeArea()
    }

    private var bigButton: some View {
        Button {
            if blocker.hasPermission { blocker.toggle() } else { blocker.requestPermission() }
        } label: {
            ZStack {
                if locked, let end = blocker.endsAt, let start = blocker.lockedAt {
                    countdownRing(start: start, end: end)
                } else {
                    // Breathing halo while locked
                    Circle()
                        .stroke(LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        .frame(width: 214, height: 214)
                        .scaleEffect(locked && pulse ? 1.12 : 1.0)
                        .opacity(locked ? (pulse ? 0 : 0.8) : 0)
                        .animation(
                            locked ? .easeOut(duration: 1.8).repeatForever(autoreverses: false) : .default,
                            value: pulse && locked
                        )
                }

                Circle()
                    .fill(LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 190, height: 190)
                    .shadow(color: accent[1].opacity(0.55 * ink.glow), radius: 40, y: 14)

                glass
                    .frame(width: 168, height: 168)
                    .overlay(Circle().stroke(.white.opacity(ink.dark ? 0.18 : 0.35), lineWidth: 1))

                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .regular))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect(.replace))
                    Text(buttonLabel)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 240, height: 240)
            .scaleEffect(hovering ? 1.03 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }

    /// Frosted centre of the big button: tinted dark glass, or bright milky glass in light mode.
    @ViewBuilder
    private var glass: some View {
        if ink.dark {
            Circle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        } else {
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().fill(LinearGradient(
                    stops: [.init(color: .white.opacity(0.33), location: 0), .init(color: .white.opacity(0), location: 0.55)],
                    startPoint: .top, endPoint: .bottom)))
        }
    }

    private func countdownRing(start: Date, end: Date) -> some View {
        TimelineView(.animation(minimumInterval: 0.1)) { context in
            let total = end.timeIntervalSince(start)
            let left = max(0, end.timeIntervalSince(context.date))
            ZStack {
                Circle().stroke(ink.stroke(0.08), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: total > 0 ? left / total : 0)
                    .stroke(
                        LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 212, height: 212)
        }
    }

    private var icon: String {
        if !blocker.hasPermission { return "lock.shield" }
        if locked { return blocker.activeMode == .away ? "pawprint.fill" : "keyboard.badge.ellipsis" }
        return blocker.mode == .away ? "pawprint" : "keyboard"
    }

    private var buttonLabel: String {
        if !blocker.hasPermission { return "GRANT ACCESS" }
        return locked ? "UNLOCK" : "LOCK"
    }

    @ViewBuilder
    private var detailRow: some View {
        if !blocker.hasPermission {
            Color.clear
        } else if locked {
            lockedInfo
        } else if blocker.mode == .clean {
            timerChips
        } else {
            phraseRow
        }
    }

    private var timerChips: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ink.text(0.45))
            ForEach(KeyboardBlocker.timerChoices, id: \.self) { seconds in
                Button(seconds == 0 ? "No timer" : "\(seconds / 60) min") {
                    customFieldFocused = false
                    blocker.selectTimer(seconds)
                }
                .buttonStyle(ChipStyle(selected: !blocker.timerIsCustom && blocker.timerSeconds == seconds))
            }
            customTimerChip
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: blocker.timerIsCustom)
    }

    /// "Custom" chip that turns into an inline "− 2:30 +" entry when chosen.
    @ViewBuilder
    private var customTimerChip: some View {
        if blocker.timerIsCustom && !locked {
            HStack(spacing: 2) {
                stepButton("minus") { blocker.stepCustom(up: false); customText = KeyboardBlocker.clock(blocker.customSeconds) }
                    .disabled(blocker.customSeconds <= KeyboardBlocker.customRange.lowerBound)
                customEntry
                stepButton("plus") { blocker.stepCustom(up: true); customText = KeyboardBlocker.clock(blocker.customSeconds) }
                    .disabled(blocker.customSeconds >= KeyboardBlocker.customRange.upperBound)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.text(0.95))
            .fixedSize()
            .padding(3)
            .background(Capsule().fill(ink.selectedFill(0.16)))
            .overlay(Capsule().stroke(ink.selectedStroke(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(ink.dark ? 0 : 0.06), radius: 2, y: 1)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else {
            Button("Custom") {
                blocker.selectCustomTimer()
                customText = KeyboardBlocker.clock(blocker.customSeconds)
                customFieldFocused = true
            }
            .buttonStyle(ChipStyle(selected: false))
        }
    }

    /// Minutes:seconds entry, e.g. "2:30" or just "5".
    @ViewBuilder
    private var customEntry: some View {
        if isPreviewRender {
            Text(KeyboardBlocker.clock(blocker.customSeconds))
                .monospacedDigit()
                .frame(width: 38)
        } else {
            TextField("m:ss", text: $customText)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .monospacedDigit()
                .frame(width: 38)
                .focused($customFieldFocused)
                .onSubmit(commitCustomText)
                .onChange(of: customFieldFocused) { _, focused in if !focused { commitCustomText() } }
        }
    }

    private func commitCustomText() {
        if let seconds = KeyboardBlocker.parseClock(customText) { blocker.setCustomSeconds(seconds) }
        customText = KeyboardBlocker.clock(blocker.customSeconds)
    }

    private func cancelCustomTimer() {
        guard blocker.timerIsCustom, !locked else { return }
        customFieldFocused = false
        blocker.selectTimer(0)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(ink.text(0.6))
                .frame(width: 20, height: 20)
                .background(Circle().fill(ink.fill(0.08)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    /// Stand-ins for the window buttons and the settings accessory, drawn only in off-screen
    /// renders so the title bar can be judged (positions match the real window).
    private var previewTitleBar: some View {
        ZStack {
            HStack(spacing: 9) {
                Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18))
            }
            .frame(width: 37, height: 14)
            .position(x: 9 + 18.5, y: titleBarHeight / 2)
            SettingsTitlebarButton()
                .position(x: 380 - SettingsTitlebarButton.trailingInset - SettingsTitlebarButton.size / 2, y: titleBarHeight / 2)
                .opacity(locked ? 0 : 1)
        }
    }

    private var phraseRow: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "character.cursor.ibeam")
                Text("Unlock phrase")
                Text(blocker.trimmedPhrase.isEmpty ? "off" : blocker.trimmedPhrase)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ink.text(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(ink.fill(0.1)))
                Image(systemName: "pencil")
                    .foregroundStyle(ink.text(0.4))
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(ink.text(0.65))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var lockedInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: blocker.activeMode == .away ? "pawprint.fill" : "sparkles")
            Text("\(blocker.keysCaught) key\(blocker.keysCaught == 1 ? "" : "s") caught")
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: blocker.keysCaught)
            if let end = blocker.endsAt {
                Text("·").foregroundStyle(ink.text(0.4))
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let left = Int(max(0, end.timeIntervalSince(context.date)).rounded(.up))
                    Text(String(format: "%d:%02d left", left / 60, left % 60)).monospacedDigit()
                }
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(ink.text(0.75))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(ink.fill(0.08)))
        .overlay(Capsule().stroke(ink.stroke(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private var footer: some View {
        if !blocker.hasPermission {
            VStack(spacing: 10) {
                Button("Open Accessibility Settings") { blocker.openAccessibilitySettings() }
                    .buttonStyle(PillStyle())
                Button("Already switched on? Reset and ask again") { blocker.resetPermission() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.text(0.45))
                    .underline()
            }
        } else if locked {
            hint("lock.open", "Releases by itself if your Mac locks or sleeps")
        } else {
            // Re-evaluated every few seconds: rotates the stats line and retires the summary card.
            TimelineView(.periodic(from: .now, by: 6)) { context in
                idleFooter(at: context.date)
            }
        }
    }

    /// Last session's card for a minute after unlocking, then your lifetime paw stats (rotating
    /// jokes), or the shortcut hint until there are any stats.
    @ViewBuilder
    private func idleFooter(at date: Date) -> some View {
        let lines = Self.statsLines(blocker.stats)
        if let summary = blocker.lastSummary, date.timeIntervalSince(summary.endedAt) < 60 {
            summaryCard(summary)
        } else if !lines.isEmpty {
            let line = lines[Int(date.timeIntervalSince1970 / 6) % lines.count]
            HStack(spacing: 7) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(LinearGradient(colors: Palette.idle, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(line)
                    .id(line)
                    .transition(.opacity)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(ink.text(0.6))
            .animation(.easeInOut(duration: 0.5), value: line)
            .padding(.top, 12)
        } else {
            hint("keyboard", "Press \(KeyboardBlocker.shortcutLabel) to lock from anywhere")
                .padding(.top, 12)
        }
    }

    /// Short, quirky one-liners built from the lifetime totals. Only lines with a number > 0 show.
    static func statsLines(_ s: PawStats) -> [String] {
        func n(_ x: Int) -> String { x.formatted() }
        func plural(_ x: Int, _ one: String, _ many: String) -> String { x == 1 ? one : many }
        var lines: [String] = []
        if s.pawKeys > 0 {
            lines.append("\(n(s.pawKeys)) \(plural(s.pawKeys, "key", "keys")) your cat didn't get to type")
            if s.pawKeys >= 5 { lines.append("≈ \(n(s.pawKeys / 5)) \(plural(s.pawKeys / 5, "word", "words")) typed by paws, never sent") }
            lines.append("\(n(s.pawKeys)) \(plural(s.pawKeys, "keystroke", "keystrokes")) of cat poetry, unpublished")
        }
        if s.pawAmbushes > 0 {
            lines.append("\(n(s.pawAmbushes)) keyboard \(plural(s.pawAmbushes, "ambush", "ambushes")) foiled")
        }
        if s.awaySessions > 0 {
            lines.append("\(n(s.awaySessions)) \(plural(s.awaySessions, "time", "times")) the pets were left unsupervised")
        }
        if s.cleanSessions > 0 {
            lines.append("\(n(s.cleanSessions)) spotless \(plural(s.cleanSessions, "wipe-down", "wipe-downs")), zero typos")
        }
        if s.keysStopped > 0 {
            lines.append("\(n(s.keysStopped)) \(plural(s.keysStopped, "key", "keys")) pressed and politely ignored")
        }
        return lines
    }

    private func hint(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(ink.text(0.4))
    }

    private static func format(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds < 60 ? [.second] : [.hour, .minute]
        f.unitsStyle = .short
        f.maximumUnitCount = 2
        return f.string(from: max(1, seconds)) ?? ""
    }

    private func summaryCard(_ s: LockSummary) -> some View {
        let headline = s.pawTriggered ? "Paws detected while you were away"
            : s.mode == .away ? "Welcome back" : "All clean"
        let detail = "\(s.keys) key\(s.keys == 1 ? "" : "s") stopped in \(Self.format(s.duration))"

        return VStack(spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: s.pawTriggered ? "pawprint.fill" : "checkmark.circle.fill")
                Text(headline)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.text(0.85))
            Text(detail)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ink.text(0.5))
                .multilineTextAlignment(.center)
            if let reason = s.reason {
                Text("\(reason), so it unlocked by itself")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(ink.text(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 14).fill(ink.fill(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ink.stroke(0.12), lineWidth: 1))
    }
}
