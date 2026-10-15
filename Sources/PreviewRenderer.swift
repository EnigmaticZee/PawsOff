import SwiftUI

/// Off-screen renders of each UI state, so the interface can be checked
/// without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func renderAll(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let states: [(String, KeyboardBlocker)] = [
            ("1-needs-permission", .preview(permission: false)),
            ("2-ready", .preview()),
            ("3-locked", .preview(active: true, caught: 42)),
            ("4-auto-released", .preview(reason: "Screen locked")),
        ]
        for (name, blocker) in states {
            let view = ContentView().environmentObject(blocker).environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
            else { continue }
            try? png.write(to: dir.appendingPathComponent("\(name).png"))
        }
        print("Rendered previews to \(dir.path)")
    }
}
