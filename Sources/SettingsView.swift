import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loginItem = LaunchAtLogin()
    @Environment(\.ink) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ink.primary)

            VStack(alignment: .leading, spacing: 10) {
                label("Appearance", "Auto matches your Mac's light or dark setting.")
                CapsulePicker(options: Appearance.allCases, selection: $blocker.appearance, shown: blocker.appearance) {
                    ($0.title, nil)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                label("Unlock phrase", "Type it while locked to release the keyboard. Pets can't spell. Leave it empty to unlock by clicking only.")
                TextField("unlock", text: $blocker.unlockPhrase)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(ink.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ink.fill(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ink.stroke(0.14), lineWidth: 1))
            }

            Toggle(isOn: $blocker.pawDetection) {
                label("Paw detection", "Locks by itself when several keys are pressed at once or held down, like a cat walking or sitting on the keyboard.")
            }
            .toggleStyle(GlowSwitchStyle())

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.set($0) })) {
                    label("Launch at login", "Opens Paws Off when you log in, so the shortcut and paw detection are always ready.")
                }
                .toggleStyle(GlowSwitchStyle())
                if let error = loginItem.error {
                    Text(error)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.idle[0])
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top) {
                label("Shortcut", "Locks and unlocks from anywhere.")
                Spacer()
                Keycap(text: KeyboardBlocker.shortcutLabel)
            }

            HStack(alignment: .top) {
                label("Your paw stats", statsDetail)
                Spacer()
                if !blocker.stats.isEmpty {
                    Button("Reset") { blocker.resetStats() }
                        .buttonStyle(ChipStyle(selected: false))
                }
            }

            HStack {
                Text(credit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.text(0.4))
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(PillStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(
            LinearGradient(colors: ink.background.reversed(), startPoint: .top, endPoint: .bottom)
        )
    }

    private var credit: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version.map { "Made by Zaid · v\($0)" } ?? "Made by Zaid"
    }

    private var statsDetail: String {
        let s = blocker.stats
        if s.isEmpty { return "Kept only on this Mac. Lock the keyboard to start counting." }
        return "\(s.keysStopped.formatted()) keys stopped, \(s.pawKeys.formatted()) of them by paws. Kept only on this Mac."
    }

        private func label(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ink.text(0.9))
            Text(detail)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ink.text(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
