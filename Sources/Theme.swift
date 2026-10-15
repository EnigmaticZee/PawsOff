import SwiftUI

/// Colours shared by the window and the app icon (Tools/make-icon.swift mirrors these).
/// windows/Theme.cs mirrors both the dark and the light set.
enum Palette {
    static let backgroundTop = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let backgroundBottom = Color(red: 0.10, green: 0.08, blue: 0.16)
    static let lightBackgroundTop = Color(red: 0xFB / 255, green: 0xF9 / 255, blue: 0xFE / 255)
    static let lightBackgroundBottom = Color(red: 0xF0 / 255, green: 0xEB / 255, blue: 0xF8 / 255)
    /// Text and line colour in light mode (white in dark mode).
    static let lightInk = Color(red: 0x1B / 255, green: 0x17 / 255, blue: 0x26 / 255)
    static let idle = [Color(red: 0.98, green: 0.55, blue: 0.47), Color(red: 0.76, green: 0.40, blue: 0.98)]
    static let locked = [Color(red: 0.36, green: 0.92, blue: 0.78), Color(red: 0.20, green: 0.58, blue: 0.98)]
}

/// Colours that change with the appearance. Opacities are written as the dark-mode values;
/// light mode maps them onto the ink tiers in windows/Theme.cs.
struct Ink: Equatable {
    var dark: Bool

    var primary: Color { dark ? .white : Palette.lightInk }
    /// Text and icons. Dark grey text needs a little more weight than white text to read the same.
    func text(_ opacity: Double) -> Color { dark ? .white.opacity(opacity) : Palette.lightInk.opacity(min(1, opacity + 0.1)) }
    func fill(_ opacity: Double) -> Color { dark ? .white.opacity(opacity) : Palette.lightInk.opacity(opacity * 0.62) }
    func stroke(_ opacity: Double) -> Color { dark ? .white.opacity(opacity) : Palette.lightInk.opacity(opacity * 0.75) }
    /// Selected tabs and chips: a lighter pill on dark, a white card on light.
    func selectedFill(_ opacity: Double) -> Color { dark ? .white.opacity(opacity) : .white }
    func selectedStroke(_ opacity: Double) -> Color { dark ? .white.opacity(opacity) : Palette.lightInk.opacity(0.08) }
    var background: [Color] {
        dark ? [Palette.backgroundTop, Palette.backgroundBottom] : [Palette.lightBackgroundTop, Palette.lightBackgroundBottom]
    }
    /// Accent glows are softer on a light background.
    var glow: Double { dark ? 1 : 0.75 }
}

extension EnvironmentValues {
    var ink: Ink { Ink(dark: colorScheme == .dark) }
}

/// Segmented switch with a sliding selection pill (Clean / Away, and Appearance in Settings).
struct CapsulePicker<Option: Hashable>: View {
    var options: [Option]
    @Binding var selection: Option
    var shown: Option
    var disabled = false
    var horizontalPadding: CGFloat = 16
    var label: (Option) -> (title: String, symbol: String?)
    @Environment(\.ink) private var ink
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = option }
                } label: {
                    let item = label(option)
                    HStack(spacing: 6) {
                        if let symbol = item.symbol { Image(systemName: symbol) }
                        Text(item.title)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.text(shown == option ? 0.95 : 0.5))
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 7)
                    .background {
                        if shown == option {
                            Capsule()
                                .fill(ink.selectedFill(0.14))
                                .overlay(Capsule().stroke(ink.selectedStroke(0.12), lineWidth: 1))
                                .shadow(color: .black.opacity(ink.dark ? 0 : 0.06), radius: 2, y: 1)
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(ink.fill(0.06)))
        .overlay(Capsule().stroke(ink.stroke(0.1), lineWidth: 1))
        .opacity(disabled ? 0.45 : 1)
        .disabled(disabled)
    }
}

/// Clean / Away switch.
struct ModePicker: View {
    @Binding var mode: LockMode
    var shown: LockMode
    var disabled: Bool

    var body: some View {
        CapsulePicker(options: LockMode.allCases, selection: $mode, shown: shown, disabled: disabled) {
            ($0.title, $0.symbol)
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
    @Environment(\.ink) private var ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(ink.fill(configuration.isPressed ? 0.2 : 0.12)))
            .overlay(Capsule().stroke(ink.stroke(0.2), lineWidth: 1))
    }
}

struct ChipStyle: ButtonStyle {
    var selected: Bool
    @Environment(\.ink) private var ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.text(selected ? 0.95 : 0.55))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? ink.selectedFill(0.16) : ink.fill(configuration.isPressed ? 0.1 : 0.05)))
            .overlay(Capsule().stroke(selected ? ink.selectedStroke(0.25) : ink.stroke(0.1), lineWidth: 1))
            .shadow(color: .black.opacity(selected && !ink.dark ? 0.06 : 0), radius: 2, y: 1)
            .contentShape(Capsule())
    }
}

/// Switch drawn in SwiftUI (the AppKit one can't be rendered off-screen).
struct GlowSwitchStyle: ToggleStyle {
    @Environment(\.ink) private var ink
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            Capsule()
                .fill(configuration.isOn
                      ? AnyShapeStyle(LinearGradient(colors: Palette.locked, startPoint: .leading, endPoint: .trailing))
                      : AnyShapeStyle(ink.fill(0.14)))
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
    @Environment(\.ink) private var ink
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.text(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(ink.fill(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(ink.stroke(0.16), lineWidth: 1))
    }
}
