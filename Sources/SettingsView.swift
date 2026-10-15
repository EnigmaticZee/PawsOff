import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                label("Unlock phrase", "Type it while locked to release the keyboard. Pets can't spell. Leave it empty to unlock by clicking only.")
                TextField("unlock", text: $blocker.unlockPhrase)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.14), lineWidth: 1))
            }

            Toggle(isOn: $blocker.pawDetection) {
                label("Paw detection", "Locks by itself when several keys are pressed at once or held down, like a cat walking or sitting on the keyboard.")
            }
            .toggleStyle(GlowSwitchStyle())

            HStack(alignment: .top) {
                label("Shortcut", "Locks and unlocks from anywhere.")
                Spacer()
                Keycap(text: KeyboardBlocker.shortcutLabel)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(PillStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(
            LinearGradient(colors: [Palette.backgroundBottom, Palette.backgroundTop], startPoint: .top, endPoint: .bottom)
        )
        .preferredColorScheme(.dark)
    }

    private func label(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Text(detail)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
