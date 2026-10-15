// Renders the Spotless app icon. Usage: swift Tools/make-icon.swift <out.iconset>
// Then: iconutil -c icns <out.iconset> -o Assets/AppIcon.icns
// Colours mirror `Palette` in Sources/ContentView.swift: the dark window background
// with a faint glow of the idle accent, nothing louder.
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)

    // macOS icon grid: 824/1024 body, centred.
    let inset = s * 100 / 1024
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.225
    let shape = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = rgb(0, 0, 0, 0.35)
    shadow.shadowBlurRadius = s * 0.025
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    shadow.set()
    rgb(0.08, 0.07, 0.13).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    // Base: same top-to-bottom tones as the window.
    NSGradient(starting: rgb(0.13, 0.11, 0.20), ending: rgb(0.06, 0.06, 0.10))!.draw(in: rect, angle: -90)
    // Two faint glows, like the blurred orbs behind the window content.
    let glowR = rect.width * 0.75
    NSGradient(colors: [rgb(0.76, 0.40, 0.98, 0.32), rgb(0.76, 0.40, 0.98, 0)])!
        .draw(fromCenter: NSPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.15), radius: 0,
              toCenter: NSPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.15), radius: glowR,
              options: [])
    NSGradient(colors: [rgb(0.98, 0.55, 0.47, 0.18), rgb(0.98, 0.55, 0.47, 0)])!
        .draw(fromCenter: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.15), radius: 0,
              toCenter: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.15), radius: glowR * 0.8,
              options: [])
    NSGraphicsContext.restoreGraphicsState()

    // Hairline highlight on the edge.
    let edge = NSBezierPath(roundedRect: rect.insetBy(dx: s * 0.002, dy: s * 0.002), xRadius: radius, yRadius: radius)
    edge.lineWidth = max(1, s * 0.004)
    rgb(1, 1, 1, 0.12).setStroke()
    edge.stroke()

    // Glass disc echoing the main button.
    let disc = rect.insetBy(dx: rect.width * 0.19, dy: rect.width * 0.19)
    let discPath = NSBezierPath(ovalIn: disc)
    NSGradient(starting: rgb(1, 1, 1, 0.10), ending: rgb(1, 1, 1, 0.03))!.draw(in: discPath, angle: -90)
    discPath.lineWidth = max(1, s * 0.004)
    rgb(1, 1, 1, 0.16).setStroke()
    discPath.stroke()

    // Keyboard glyph.
    let config = NSImage.SymbolConfiguration(pointSize: s * 0.22, weight: .light)
        .applying(.init(paletteColors: [rgb(1, 1, 1, 0.92)]))
    if let sym = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let sz = sym.size
        sym.draw(in: NSRect(x: (s - sz.width) / 2, y: (s - sz.height) / 2, width: sz.width, height: sz.height))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: out.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(base * 2).write(to: out.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
