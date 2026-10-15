import SwiftUI

/// Colours shared by the window and the app icon (Tools/make-icon.swift mirrors these).
enum Palette {
    static let backgroundTop = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let backgroundBottom = Color(red: 0.10, green: 0.08, blue: 0.16)
    static let idle = [Color(red: 0.98, green: 0.55, blue: 0.47), Color(red: 0.76, green: 0.40, blue: 0.98)]
    static let locked = [Color(red: 0.36, green: 0.92, blue: 0.78), Color(red: 0.20, green: 0.58, blue: 0.98)]
}

/// Clean / Away segmented switch with a sliding selection pill.
struct ModePicker: View {
    @Binding var mode: LockMode
    var shown: LockMode
    var disabled: Bool
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(LockMode.allCases) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = option }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.symbol)
                        Text(option.title)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(shown == option ? 0.95 : 0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background {
                        if shown == option {
                            Capsule()
                                .fill(.white.opacity(0.14))
                                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.06)))
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
        .opacity(disabled ? 0.45 : 1)
        .disabled(disabled)
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

struct ChipStyle: ButtonStyle {
    var selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(selected ? 0.95 : 0.55))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(selected ? 0.16 : (configuration.isPressed ? 0.1 : 0.05))))
            .overlay(Capsule().stroke(.white.opacity(selected ? 0.25 : 0.1), lineWidth: 1))
            .contentShape(Capsule())
    }
}

/// Switch drawn in SwiftUI (the AppKit one can't be rendered off-screen).
struct GlowSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            Capsule()
                .fill(configuration.isOn
                      ? AnyShapeStyle(LinearGradient(colors: Palette.locked, startPoint: .leading, endPoint: .trailing))
                      : AnyShapeStyle(Color.white.opacity(0.14)))
                .frame(width: 38, height: 22)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle().fill(.white).padding(2).shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                }
                .contentShape(Capsule())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { configuration.isOn.toggle() }
                }
        }
    }
}

struct Keycap: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.16), lineWidth: 1))
    }
}
