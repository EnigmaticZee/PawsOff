import SwiftUI

/// The whole app UI as one compact card. The same card is shown in the app window and in the
/// menu bar panel; settings slide in inside it, at the same size.
struct CardView: View {
    /// Where the card is shown. The panel gets a button to open the window.
    enum Place { case window, panel }

    static let size = CGSize(width: 320, height: 430)

    var place: Place = .window
    @EnvironmentObject var blocker: KeyboardBlocker
    @State private var pulse = false
    @State private var hovering = false
    @State private var showSettings: Bool

    init(place: Place = .window, showingSettings: Bool = false) {
        self.place = place
        _showSettings = State(initialValue: showingSettings)
    }
    @State private var customText = ""
    @FocusState private var customFieldFocused: Bool
    @Environment(\.ink) private var ink
    @Environment(\.isPreviewRender) private var isPreviewRender

    private var locked: Bool { blocker.isActive }
    private var shownMode: LockMode { locked ? blocker.activeMode : blocker.mode }
    private var accent: [Color] { locked ? Palette.locked : Palette.idle }

    var body: some View {
        ZStack {
            background
                // Clicking empty space cancels a custom timer that's being set.
                .contentShape(Rectangle())
                .onTapGesture { cancelCustomTimer() }

            Group {
                if showSettings {
                    SettingsPage(place: place) { withAnimation(.snappy(duration: 0.3)) { showSettings = false } }
                        .transition(.move(edge: .trailing))
                } else {
                    mainPage
                        .transition(.move(edge: .leading))
                }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .onChange(of: blocker.mode) { cancelCustomTimer() }
        // A custom length is a one-off: once that lock ends, go back to No timer.
        .onChange(of: blocker.isActive) { _, active in
            if active { showSettings = false }
            if !active && blocker.timerIsCustom { blocker.selectTimer(0) }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: blocker.isActive)
        .animation(.easeInOut(duration: 0.25), value: blocker.mode)
        .animation(.easeInOut(duration: 0.25), value: blocker.hasPermission)
        .onAppear { pulse = true }
    }

    /// Mode switch on top, the button with its title in the middle, the session's controls under
    /// it, and a bottom bar with your stats and the settings button.
    private var mainPage: some View {
        VStack(spacing: 0) {
            ModePicker(mode: $blocker.mode, shown: shownMode, disabled: locked || !blocker.hasPermission)
                .padding(.top, 16)

            Spacer(minLength: 4)

            bigButton

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(ink.primary)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(ink.text(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 270)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, 20)

            detailRow
                .frame(height: 30)
                .padding(.top, 14)

            Spacer(minLength: 4)

            bottomBar
        }
    }

    // MARK: Copy

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
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -80, y: -110)
            Circle()
                .fill(accent[1].opacity(0.35 * ink.glow))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: 90, y: 120)
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
                        .frame(width: 166, height: 166)
                        .scaleEffect(locked && pulse ? 1.12 : 1.0)
                        .opacity(locked ? (pulse ? 0 : 0.8) : 0)
                        .animation(
                            locked ? .easeOut(duration: 1.8).repeatForever(autoreverses: false) : .default,
                            value: pulse && locked
                        )
                }

                Circle()
                    .fill(LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 148, height: 148)
                    .shadow(color: accent[1].opacity(0.55 * ink.glow), radius: 28, y: 10)

                glass
                    .frame(width: 130, height: 130)
                    .overlay(Circle().stroke(.white.opacity(ink.dark ? 0.18 : 0.35), lineWidth: 1))

                VStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 38, weight: .regular))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect(.replace))
                    Text(buttonLabel)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 190, height: 190)
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
            .frame(width: 164, height: 164)
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
            Button("Open Accessibility Settings") { blocker.openAccessibilitySettings() }
                .buttonStyle(PillStyle())
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

    private var phraseRow: some View {
        Button { withAnimation(.snappy(duration: 0.3)) { showSettings = true } } label: {
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

    /// Hairline, then one row: what's happening (or your stats) on the left, controls on the right.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(ink.stroke(0.1)).frame(height: 1)
            HStack(spacing: 6) {
                bottomText
                    .frame(maxWidth: .infinity, alignment: .leading)
                if place == .panel && !locked {
                    barButton("macwindow", help: "Open the Paws Off window") { MainWindow.show() }
                }
                if !locked {
                    barButton("gearshape", help: "Settings") {
                        cancelCustomTimer()
                        withAnimation(.snappy(duration: 0.3)) { showSettings = true }
                    }
                }
                if place == .panel {
                    barButton("power", help: "Quit Paws Off") { NSApp.terminate(nil) }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .frame(height: 44)
        }
    }

    @ViewBuilder
    private var bottomText: some View {
        if !blocker.hasPermission {
            Button("Already switched on? Reset and ask again") { blocker.resetPermission() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(ink.text(0.5))
                .underline()
        } else if locked {
            hint("lock.open", "Releases if your Mac locks or sleeps")
        } else {
            // Re-evaluated every few seconds: rotates the stats line and retires the session summary.
            TimelineView(.periodic(from: .now, by: 6)) { context in
                idleLine(at: context.date)
            }
        }
    }

    /// Last session for a minute after unlocking, then your lifetime paw stats (rotating jokes),
    /// or the shortcut hint until there are any stats.
    @ViewBuilder
    private func idleLine(at date: Date) -> some View {
        let lines = Self.statsLines(blocker.stats)
        if let s = blocker.lastSummary, date.timeIntervalSince(s.endedAt) < 60 {
            let headline = s.pawTriggered ? "Paws caught" : s.mode == .away ? "Welcome back" : "All clean"
            HStack(spacing: 6) {
                Image(systemName: s.pawTriggered ? "pawprint.fill" : "checkmark.circle.fill")
                Text("\(headline) · \(s.keys.formatted()) \(s.keys == 1 ? "key" : "keys") stopped").lineLimit(1)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.text(0.75))
            .help(s.reason.map { "\($0), so it unlocked by itself" } ?? "Stopped in \(Self.format(s.duration))")
        } else if !lines.isEmpty {
            let line = lines[Int(date.timeIntervalSince1970 / 6) % lines.count]
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(LinearGradient(colors: Palette.idle, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(line)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .id(line)
                    .transition(.opacity)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(ink.text(0.6))
            .animation(.easeInOut(duration: 0.5), value: line)
        } else {
            hint("keyboard", "\(KeyboardBlocker.shortcutLabel) locks from anywhere")
        }
    }

    private func barButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        BarIconButton(symbol: symbol, action: action).help(help)
    }

    /// Short, quirky one-liners built from the lifetime totals. Only lines with a number > 0 show.
    static func statsLines(_ s: PawStats) -> [String] {
        func n(_ x: Int) -> String { x.formatted() }
        func plural(_ x: Int, _ one: String, _ many: String) -> String { x == 1 ? one : many }
        var lines: [String] = []
        if s.pawKeys > 0 {
            lines.append("\(n(s.pawKeys)) \(plural(s.pawKeys, "key", "keys")) your cat didn't type")
            if s.pawKeys >= 5 { lines.append("≈ \(n(s.pawKeys / 5)) \(plural(s.pawKeys / 5, "word", "words")) by paws, never sent") }
            lines.append("\(n(s.pawKeys)) \(plural(s.pawKeys, "key", "keys")) of unpublished cat poetry")
        }
        if s.pawAmbushes > 0 {
            lines.append("\(n(s.pawAmbushes)) keyboard \(plural(s.pawAmbushes, "ambush", "ambushes")) foiled")
        }
        if s.awaySessions > 0 {
            lines.append("\(n(s.awaySessions)) unsupervised pet \(plural(s.awaySessions, "session", "sessions"))")
        }
        if s.cleanSessions > 0 {
            lines.append("\(n(s.cleanSessions)) spotless \(plural(s.cleanSessions, "wipe-down", "wipe-downs")), zero typos")
        }
        if s.keysStopped > 0 {
            lines.append("\(n(s.keysStopped)) \(plural(s.keysStopped, "key", "keys")) politely ignored")
        }
        return lines
    }

    private func hint(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(ink.text(0.45))
        .lineLimit(1)
    }

    private static func format(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds < 60 ? [.second] : [.hour, .minute]
        f.unitsStyle = .short
        f.maximumUnitCount = 2
        return f.string(from: max(1, seconds)) ?? ""
    }
}

/// A small icon button with a circular hover highlight, sized like the window buttons.
struct BarIconButton: View {
    var symbol: String
    var action: () -> Void
    @State private var hovering = false
    @Environment(\.ink) private var ink

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(ink.text(hovering ? 0.8 : 0.55))
                .frame(width: 28, height: 28)
                .background(Circle().fill(ink.fill(hovering ? 0.1 : 0)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
