import SwiftUI

struct ContentView: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @State private var pulse = false
    @State private var hovering = false
    @State private var showSettings = false

    private var locked: Bool { blocker.isActive }
    private var shownMode: LockMode { locked ? blocker.activeMode : blocker.mode }
    private var accent: [Color] { locked ? Palette.locked : Palette.idle }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background

            VStack(spacing: 0) {
                ModePicker(mode: $blocker.mode, shown: shownMode, disabled: locked || !blocker.hasPermission)
                    .padding(.top, 46)

                Text(statusLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.55))
                    .contentTransition(.opacity)
                    .padding(.top, 20)

                Spacer(minLength: 16)

                bigButton

                Spacer(minLength: 20)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }

                Spacer(minLength: 16)

                detailRow
                    .frame(height: 34)

                Spacer(minLength: 12)

                footer
                    .frame(minHeight: 44)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")
            .padding(.top, 4)
            .padding(.trailing, 8)
            .opacity(locked ? 0 : 1)
            .disabled(locked)
        }
        .frame(width: 380, height: 620)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(blocker)
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
            LinearGradient(colors: [Palette.backgroundTop, Palette.backgroundBottom], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(accent[0].opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -90, y: -130)
            Circle()
                .fill(accent[1].opacity(0.35))
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
                    .shadow(color: accent[1].opacity(0.55), radius: 40, y: 14)

                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 168, height: 168)
                    .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))

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

    private func countdownRing(start: Date, end: Date) -> some View {
        TimelineView(.animation(minimumInterval: 0.1)) { context in
            let total = end.timeIntervalSince(start)
            let left = max(0, end.timeIntervalSince(context.date))
            ZStack {
                Circle().stroke(.white.opacity(0.08), lineWidth: 3)
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
                .foregroundStyle(.white.opacity(0.45))
            ForEach(KeyboardBlocker.timerChoices, id: \.self) { seconds in
                Button(seconds == 0 ? "No timer" : seconds < 60 ? "\(seconds) s" : "\(seconds / 60) min") {
                    blocker.timerSeconds = seconds
                }
                .buttonStyle(ChipStyle(selected: blocker.timerSeconds == seconds))
            }
        }
    }

    private var phraseRow: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "character.cursor.ibeam")
                Text("Unlock phrase")
                Text(blocker.trimmedPhrase.isEmpty ? "off" : blocker.trimmedPhrase)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)))
                Image(systemName: "pencil")
                    .foregroundStyle(.white.opacity(0.4))
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.65))
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
                Text("·").foregroundStyle(.white.opacity(0.4))
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let left = Int(max(0, end.timeIntervalSince(context.date)).rounded(.up))
                    Text(String(format: "%d:%02d left", left / 60, left % 60)).monospacedDigit()
                }
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.75))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.08)))
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private var footer: some View {
        if !blocker.hasPermission {
            Button("Open Accessibility Settings") { blocker.openAccessibilitySettings() }
                .buttonStyle(PillStyle())
        } else if locked {
            hint("lock.open", "Releases by itself if your Mac locks or sleeps")
        } else if let summary = blocker.lastSummary {
            summaryCard(summary)
        } else {
            hint("keyboard", "Press \(KeyboardBlocker.shortcutLabel) to lock from anywhere")
        }
    }

    private func hint(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.4))
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
            .foregroundStyle(.white.opacity(0.85))
            Text(detail)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            if let reason = s.reason {
                Text("\(reason), so it unlocked by itself")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}
