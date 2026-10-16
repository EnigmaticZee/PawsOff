// Builds the README images in docs/images from the app's off-screen renders.
// Usage: Tools/make-readme-art.sh  (renders previews, then runs this)
//        swift Tools/make-readme-art.swift <previews-dir> <out-dir>
import AppKit

let previews = URL(fileURLWithPath: CommandLine.arguments[1])
let out = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func screen(_ name: String, theme: String = "dark") -> NSImage {
    let files = try! FileManager.default.contentsOfDirectory(atPath: previews.path)
    let file = files.first { $0.hasPrefix("\(theme)-") && $0.hasSuffix("-\(name).png") }!
    return NSImage(contentsOf: previews.appendingPathComponent(file))!
}

func canvas(_ size: NSSize, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}

/// Draws a window render with rounded corners, a hairline edge and a soft shadow.
func drawWindow(_ image: NSImage, in rect: NSRect, radius: CGFloat, softShadow: Bool = false) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = rgb(0, 0, 0, softShadow ? 0.16 : 0.55)
    shadow.shadowBlurRadius = radius * 2.2
    shadow.shadowOffset = NSSize(width: 0, height: -radius * 0.8)
    shadow.set()
    rgb(0.06, 0.06, 0.10).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()

    (softShadow ? rgb(0, 0, 0, 0.08) : rgb(1, 1, 1, 0.14)).setStroke()
    path.lineWidth = 2
    path.stroke()
}

// Hero: three key screens (the menu bar panel, locked with a timer, a caught paw). Calm, solid
// backgrounds with just a soft fall of light, no glows; a light and a dark version, and the README
// shows whichever matches the reader's GitHub theme.
for theme in ["light", "dark"] {
    let dark = theme == "dark"
    let size = NSSize(width: 2000, height: 1120)
    let rep = canvas(size) {
        let bounds = NSRect(origin: .zero, size: size)
        let bg = NSBezierPath(roundedRect: bounds, xRadius: 48, yRadius: 48)
        bg.addClip()
        // One colour, a touch lighter at the top, like light falling on a desk.
        let top = dark ? rgb(0.118, 0.106, 0.153) : rgb(0.984, 0.976, 0.965)
        let bottom = dark ? rgb(0.075, 0.067, 0.098) : rgb(0.949, 0.937, 0.922)
        NSGradient(starting: top, ending: bottom)!.draw(in: bounds, angle: -90)

        let side = NSSize(width: 480, height: 645)   // 320x430 card at 1.5x
        let middle = NSSize(width: 560, height: 753) // 1.75x
        let gap: CGFloat = 70
        let total = side.width * 2 + middle.width + gap * 2
        var x = (size.width - total) / 2
        drawWindow(screen("menu-bar-panel", theme: "light"), in: NSRect(x: x, y: (size.height - side.height) / 2 - 10, width: side.width, height: side.height),
                   radius: 22, softShadow: !dark)
        x += side.width + gap
        drawWindow(screen("cleanTimer"), in: NSRect(x: x, y: (size.height - middle.height) / 2, width: middle.width, height: middle.height),
                   radius: 26, softShadow: !dark)
        x += middle.width + gap
        drawWindow(screen("pawsDetected", theme: "light"), in: NSRect(x: x, y: (size.height - side.height) / 2 - 10, width: side.width, height: side.height),
                   radius: 22, softShadow: !dark)
    }
    save(rep, "hero-\(theme).png")
}

// Gallery: each state as its own rounded window on a transparent background.
for name in ["cleanReady", "cleanCustom", "awayLocked", "pawsDetected", "menu-bar-panel", "settings"] {
    let pad: CGFloat = 40
    let win = NSSize(width: 512, height: 688) // 320x430 card at 1.6x
    let rep = canvas(NSSize(width: win.width + pad * 2, height: win.height + pad * 2)) {
        drawWindow(screen(name), in: NSRect(x: pad, y: pad + 8, width: win.width, height: win.height), radius: 26)
    }
    save(rep, "screen-\(name).png")
}
print("README art written to \(out.path)")
