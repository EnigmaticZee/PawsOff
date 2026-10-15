import SwiftUI

/// Colours shared by the window and the app icon (Tools/make-icon.swift mirrors these).
enum Palette {
    static let backgroundTop = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let backgroundBottom = Color(red: 0.10, green: 0.08, blue: 0.16)
    static let idle = [Color(red: 0.98, green: 0.55, blue: 0.47), Color(red: 0.76, green: 0.40, blue: 0.98)]
    static let locked = [Color(red: 0.36, green: 0.92, blue: 0.78), Color(red: 0.20, green: 0.58, blue: 0.98)]
}

struct ContentView: View {
    @EnvironmentObject var blocker: KeyboardBlocker
    @State private var pulse = false
    @State private var hovering = false

    private var accent: [Color] { blocker.isActive ? Palette.locked : Palette.idle }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 36)

                Text(blocker.isActive ? "KEYBOARD LOCKED" : "KEYBOARD ACTIVE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.55))
                    .contentTransition(.opacity)

                Spacer(minLength: 28)

                bigButton

                Spacer(minLength: 28)

                VStack(spacing: 8) {
                    Text(blocker.isActive ? "Wipe away." : "Ready to clean?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }

                Spacer(minLength: 24)

                footer
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 28)
        }
        .frame(width: 380, height: 540)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: blocker.isActive)
        .animation(.easeInOut(duration: 0.25), value: blocker.hasPermission)
        .onAppear { pulse = true }
    }

    private var subtitle: String {
        if !blocker.hasPermission {
            return "Spotless needs Accessibility access to pause your keyboard."
        }
        if blocker.isActive {
            return "Every key is ignored. Click the button with your trackpad or mouse when you're done."
        }
        if let reason = blocker.lastAutoReleaseReason {
            return "\(reason) — keyboard was released automatically so you can log back in."
        }
        return "Tap the button to pause all key presses while you wipe down your keyboard."
    }

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
                .offset(x: 110, y: 120)
        }
        .ignoresSafeArea()
    }

    private var bigButton: some View {
        Button {
            if blocker.hasPermission { blocker.toggle() } else { blocker.requestPermission() }
        } label: {
            ZStack {
                // Breathing halo while locked
                Circle()
                    .stroke(LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    .frame(width: 214, height: 214)
                    .scaleEffect(blocker.isActive && pulse ? 1.12 : 1.0)
                    .opacity(blocker.isActive ? (pulse ? 0 : 0.8) : 0)
                    .animation(
                        blocker.isActive ? .easeOut(duration: 1.8).repeatForever(autoreverses: false) : .default,
                        value: pulse && blocker.isActive
                    )

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
            .scaleEffect(hovering ? 1.03 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }

    private var icon: String {
        if !blocker.hasPermission { return "lock.shield" }
        return blocker.isActive ? "keyboard.badge.ellipsis" : "keyboard"
    }

    private var buttonLabel: String {
        if !blocker.hasPermission { return "GRANT ACCESS" }
        return blocker.isActive ? "UNLOCK" : "LOCK"
    }

    @ViewBuilder
    private var footer: some View {
        if !blocker.hasPermission {
            Button("Open Accessibility Settings") { blocker.openAccessibilitySettings() }
                .buttonStyle(PillStyle())
        } else if blocker.isActive {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("\(blocker.keysCaught) key\(blocker.keysCaught == 1 ? "" : "s") caught")
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: blocker.keysCaught)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.08)))
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
        } else {
            HStack(spacing: 6) {
                Image(systemName: "lock.open")
                Text("Auto-unlocks if your Mac locks or sleeps")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))
        }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(.white.opacity(configuration.isPressed ? 0.2 : 0.12)))
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
    }
}
