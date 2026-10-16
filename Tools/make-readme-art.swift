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

func symbol(_ name: String, size: CGFloat, color: NSColor, at center: NSPoint) {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold).applying(.init(paletteColors: [color]))
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) else { return }
    image.draw(in: NSRect(x: center.x - image.size.width / 2, y: center.y - image.size.height / 2, width: image.size.width, height: image.size.height))
}

// Hero: a desktop scene, no text (the README title sits above it). The menu bar with the panel
// dropping down from the paw, and the window floating beside it: both places Paws Off lives.
// One solid background, no glows; a light and a dark version, and the README shows whichever
// matches the reader's GitHub theme.
for theme in ["light", "dark"] {
    let dark = theme == "dark"
    let ink = dark ? rgb(0.96, 0.95, 0.98) : rgb(0.106, 0.090, 0.149)
    let size = NSSize(width: 2000, height: 940)
    let rep = canvas(size) {
        let bounds = NSRect(origin: .zero, size: size)
        let bg = NSBezierPath(roundedRect: bounds, xRadius: 40, yRadius: 40)
        bg.addClip()
        (dark ? rgb(0.086, 0.075, 0.114) : rgb(0.969, 0.961, 0.949)).setFill()
        bounds.fill()

        // Menu bar: the paw (highlighted, its panel is open), Wi-Fi and the clock.
        let barH: CGFloat = 46, barY = size.height - barH
        (dark ? rgb(1, 1, 1, 0.06) : rgb(1, 1, 1, 0.75)).setFill()
        NSRect(x: 0, y: barY, width: size.width, height: barH).fill()
        let pawX: CGFloat = 1340
        (dark ? rgb(1, 1, 1, 0.16) : rgb(0, 0, 0, 0.10)).setFill()
        NSBezierPath(roundedRect: NSRect(x: pawX - 24, y: barY + 8, width: 48, height: 30), xRadius: 15, yRadius: 15).fill()
        symbol("pawprint.fill", size: 19, color: ink, at: NSPoint(x: pawX, y: barY + barH / 2))
        symbol("wifi", size: 18, color: ink, at: NSPoint(x: size.width - 190, y: barY + barH / 2))
        ("Thu 9:41" as NSString).draw(at: NSPoint(x: size.width - 160, y: barY + 11),
                                      withAttributes: [.font: NSFont.systemFont(ofSize: 20, weight: .medium), .foregroundColor: ink])

        // The panel, centred under the paw, and the window (locked, timer running) beside it.
        let card = NSSize(width: 512, height: 688) // 320x430 card at 1.6x
        drawWindow(screen("menu-bar-panel", theme: theme), in: NSRect(x: pawX - card.width / 2, y: barY - 14 - card.height, width: card.width, height: card.height),
                   radius: 26, softShadow: !dark)
        drawWindow(screen("cleanTimer", theme: theme), in: NSRect(x: 420, y: (barY - card.height) / 2 - 6, width: card.width, height: card.height),
                   radius: 26, softShadow: !dark)
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
