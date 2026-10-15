import SwiftUI

/// Settings, shown inside the card at the card's own size: one compact row per setting, with the
/// longer explanations in hover tooltips. Slides in from the gear; the back button returns.
struct SettingsPage: View {
    var place: CardView.Place
    var onClose: () -> Void

    @EnvironmentObject var blocker: KeyboardBlocker
    @StateObject private var loginItem = LaunchAtLogin()
    @ObservedObject private var updater = Updater.shared
    @Environment(\.ink) private var ink
    @Environment(\.isPreviewRender) private var isPreviewRender

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Button(action: onClose) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                        Text("Settings").font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(ink.primary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)

            VStack(spacing: 0) {
                row("Appearance", help: "Auto matches your Mac's light or dark setting.") {
                    CapsulePicker(options: Appearance.allCases, selection: $blocker.appearance,
                                  shown: blocker.appearance, horizontalPadding: 9) { ($0.title, nil) }
                        .scaleEffect(0.86)
                        .frame(height: 26)
                }
                divider
                row("Start in", help: "Where Paws Off opens when it starts. Menu bar: quietly, with just the paw in the menu bar. Window: the window opens too. Either way the other is one click away.") {
                    CapsulePicker(options: LaunchPlace.allCases, selection: $blocker.launchPlace,
                                  shown: blocker.launchPlace, horizontalPadding: 9) { ($0.title, nil) }
                        .fixedSize()
                        .scaleEffect(0.86)
                        .frame(height: 26)
                }
                divider
                row("Unlock phrase", help: "Type it while locked to release the keyboard. Pets can't spell. Leave it empty to unlock by clicking only.") {
                    phraseField
                }
                divider
                row("Paw detection", help: "Locks by itself when several keys are pressed at once or held down, like a cat walking or sitting on the keyboard.") {
                    Toggle("", isOn: $blocker.pawDetection).toggleStyle(GlowSwitchStyle()).fixedSize()
                }
                divider
                row("Launch at login", help: loginItem.error ?? "Opens Paws Off when you log in, so the shortcut and paw detection are always ready.") {
                    Toggle("", isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.set($0) }))
                        .toggleStyle(GlowSwitchStyle()).fixedSize()
                }
                divider
                row("Shortcut", help: "Locks and unlocks from any app.") {
                    Keycap(text: KeyboardBlocker.shortcutLabel)
                }
                divider
                row("Updates", help: "Checks GitHub about once a day and offers new versions. Nothing else is sent.") {
                    HStack(spacing: 8) {
                        Button("Check") { updater.checkForUpdates() }
                            .buttonStyle(ChipStyle(selected: false))
                            .fixedSize()
                        Toggle("", isOn: $updater.automaticallyChecks).toggleStyle(GlowSwitchStyle()).fixedSize()
                            .help("Check for updates automatically")
                    }
                }
                divider
                row("Paw stats", help: statsHelp) {
                    HStack(spacing: 8) {
                        Text("\(blocker.stats.keysStopped.formatted()) keys")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(ink.text(0.55))
                            .monospacedDigit()
                        if !blocker.stats.isEmpty {
                            Button("Reset") { blocker.resetStats() }
                                .buttonStyle(ChipStyle(selected: false))
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ink.fill(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(ink.stroke(0.08), lineWidth: 1))
            .padding(.horizontal, 12)

            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Rectangle().fill(ink.stroke(0.1)).frame(height: 1)
                HStack {
                    Text(credit)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.text(0.45))
                    Spacer()
                    Button("Quit Paws Off") { NSApp.terminate(nil) }
                        .buttonStyle(ChipStyle(selected: false))
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(ink.stroke(0.08)).frame(height: 1).padding(.horizontal, 10)
    }

    private func row(_ title: String, help: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ink.text(0.9))
            Spacer(minLength: 8)
            control()
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .contentShape(Rectangle())
        .help(help)
    }

    @ViewBuilder
    private var phraseField: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        Group {
            if isPreviewRender {
                Text(blocker.unlockPhrase.isEmpty ? "off" : blocker.unlockPhrase)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField("off", text: $blocker.unlockPhrase)
                    .textFieldStyle(.plain)
            }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundStyle(ink.primary)
        .padding(.horizontal, 8)
        .frame(width: 110, height: 24)
        .background(shape.fill(ink.fill(0.08)))
        .overlay(shape.stroke(ink.stroke(0.14), lineWidth: 1))
    }

    private var credit: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version.map { "Made by Zaid · v\($0)" } ?? "Made by Zaid"
    }

    private var statsHelp: String {
        let s = blocker.stats
        if s.isEmpty { return "Kept only on this Mac. Lock the keyboard to start counting." }
        return "\(s.keysStopped.formatted()) keys stopped, \(s.pawKeys.formatted()) of them by paws, \(s.pawAmbushes.formatted()) paw ambushes. Kept only on this Mac."
    }
}
