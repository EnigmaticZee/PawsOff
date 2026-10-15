import SwiftUI

/// Off-screen renders of each UI state, so the interface can be checked
/// without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func renderAll(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (index, state) in KeyboardBlocker.PreviewState.allCases.enumerated() {
            let view = ContentView()
                .environmentObject(KeyboardBlocker.preview(state))
                .environment(\.colorScheme, .dark)
            write(view, to: dir.appendingPathComponent("\(index + 1)-\(state.rawValue).png"))
        }
        let settings = SettingsView()
            .environmentObject(KeyboardBlocker.preview(.cleanReady))
            .environment(\.colorScheme, .dark)
        write(settings, to: dir.appendingPathComponent("\(KeyboardBlocker.PreviewState.allCases.count + 1)-settings.png"))
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
