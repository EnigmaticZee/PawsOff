import SwiftUI

/// Off-screen renders of each UI state in dark and light, so the interface can be checked
/// without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func renderAll(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let count = KeyboardBlocker.PreviewState.allCases.count
        for scheme in [ColorScheme.dark, .light] {
            let theme = scheme == .dark ? "dark" : "light"
            for (index, state) in KeyboardBlocker.PreviewState.allCases.enumerated() {
                let view = CardView()
                    .environmentObject(KeyboardBlocker.preview(state))
                    .environment(\.colorScheme, scheme)
                    .environment(\.isPreviewRender, true)
                write(view, to: dir.appendingPathComponent("\(theme)-\(index + 1)-\(state.rawValue).png"))
            }
            let panel = CardView(place: .panel)
                .environmentObject(KeyboardBlocker.preview(.withStats))
                .environment(\.colorScheme, scheme)
                .environment(\.isPreviewRender, true)
            write(panel, to: dir.appendingPathComponent("\(theme)-\(count + 2)-menu-bar-panel.png"))
            let settings = CardView(showingSettings: true)
                .environmentObject(KeyboardBlocker.preview(.withStats))
                .environment(\.colorScheme, scheme)
                .environment(\.isPreviewRender, true)
            write(settings, to: dir.appendingPathComponent("\(theme)-\(count + 1)-settings.png"))
        }
        print("Rendered previews to \(dir.path)")
    }

    private static func write(_ view: some View, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: url)
    }
}
