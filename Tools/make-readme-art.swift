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

func screen(_ name: String) -> NSImage {
    let files = try! FileManager.default.contentsOfDirectory(atPath: previews.path)
    let file = files.first { $0.hasSuffix("-\(name).png") }!
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
func drawWindow(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = rgb(0, 0, 0, 0.55)
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

    rgb(1, 1, 1, 0.14).setStroke()
    path.lineWidth = 2
    path.stroke()
}

func glow(_ color: NSColor, at center: NSPoint, radius: CGFloat) {
    NSGradient(colors: [color, color.withAlphaComponent(0)])!
        .draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
}

// Hero: three key screens on the app's dark, glowing background.
do {
    let size = NSSize(width: 2000, height: 1120)
    let rep = canvas(size) {
        let bounds = NSRect(origin: .zero, size: size)
        let bg = NSBezierPath(roundedRect: bounds, xRadius: 48, yRadius: 48)
        bg.addClip()
        NSGradient(starting: rgb(0.11, 0.09, 0.18), ending: rgb(0.05, 0.05, 0.09))!.draw(in: bounds, angle: -90)
        glow(rgb(0.98, 0.55, 0.47, 0.30), at: NSPoint(x: 360, y: 860), radius: 700)
        glow(rgb(0.76, 0.40, 0.98, 0.30), at: NSPoint(x: 1000, y: 200), radius: 760)
        glow(rgb(0.20, 0.58, 0.98, 0.28), at: NSPoint(x: 1680, y: 820), radius: 700)

        let side = NSSize(width: 456, height: 744)   // 380x620 window at 1.2x
        let middle = NSSize(width: 532, height: 868) // 1.4x
        let gap: CGFloat = 70
        let total = side.width * 2 + middle.width + gap * 2
        var x = (size.width - total) / 2
        drawWindow(screen("awayReady"), in: NSRect(x: x, y: (size.height - side.height) / 2 - 10, width: side.width, height: side.height), radius: 22)
        x += side.width + gap
        drawWindow(screen("cleanTimer"), in: NSRect(x: x, y: (size.height - middle.height) / 2, width: middle.width, height: middle.height), radius: 26)
        x += middle.width + gap
        drawWindow(screen("pawsDetected"), in: NSRect(x: x, y: (size.height - side.height) / 2 - 10, width: side.width, height: side.height), radius: 22)
    }
    save(rep, "hero.png")
}

// Gallery: each state as its own rounded window on a transparent background.
for name in ["cleanReady", "cleanTimer", "awayReady", "awayLocked", "pawsDetected", "backFromAway"] {
    let pad: CGFloat = 40
    let win = NSSize(width: 532, height: 868)
    let rep = canvas(NSSize(width: win.width + pad * 2, height: win.height + pad * 2)) {
        drawWindow(screen(name), in: NSRect(x: pad, y: pad + 8, width: win.width, height: win.height), radius: 26)
    }
    save(rep, "screen-\(name).png")
}
print("README art written to \(out.path)")
