// Draws the installer artwork: the Mac DMG window background and the Windows installer wizard images.
// Usage: swift Tools/make-installer-art.swift <out-dir>
// Writes dmg-background.png + dmg-background@2x.png (660x400 window) and the Inno Setup wizard
// bitmaps (wizard-large-*.bmp, wizard-small-*.bmp). Colours mirror Palette (light look).
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: a) }
let coral = rgb(0.98, 0.55, 0.47), violet = rgb(0.76, 0.40, 0.98)
let ink = rgb(0.106, 0.090, 0.149)
let bgTop = rgb(0.984, 0.976, 0.996), bgBottom = rgb(0.941, 0.922, 0.973)

func rounded(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    return NSFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: size) ?? base
}

func glow(_ c: NSColor, _ center: NSPoint, _ radius: CGFloat, _ alpha: CGFloat) {
    NSGradient(colors: [c.withAlphaComponent(alpha), c.withAlphaComponent(0)])!
        .draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
}

/// Renders a drawing at a pixel scale into a bitmap (y up, in points).
func render(_ w: CGFloat, _ h: CGFloat, scale: CGFloat, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w * scale), pixelsHigh: Int(h * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func text(_ s: String, _ font: NSFont, _ color: NSColor, centerX: CGFloat, y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let size = (s as NSString).size(withAttributes: attrs)
    (s as NSString).draw(at: NSPoint(x: centerX - size.width / 2, y: y), withAttributes: attrs)
}

func paw(in rect: NSRect, color: NSColor) {
    let config = NSImage.SymbolConfiguration(pointSize: rect.height, weight: .regular).applying(.init(paletteColors: [color]))
    if let sym = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let s = sym.size, k = min(rect.width / s.width, rect.height / s.height)
        sym.draw(in: NSRect(x: rect.midX - s.width * k / 2, y: rect.midY - s.height * k / 2, width: s.width * k, height: s.height * k))
    }
}

func brandBackground(_ rect: NSRect) {
    NSGradient(starting: bgTop, ending: bgBottom)!.draw(in: rect, angle: -90)
    glow(coral, NSPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.1), rect.width * 0.45, 0.22)
    glow(violet, NSPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY + rect.height * 0.15), rect.width * 0.5, 0.20)
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}

/// Classic bottom-up 24-bit BMP, the format Inno Setup's wizard images expect.
func saveBMP(_ rep: NSBitmapImageRep, _ name: String) {
    let w = rep.pixelsWide, h = rep.pixelsHigh, row = (w * 3 + 3) / 4 * 4
    func le(_ v: Int, _ n: Int) -> [UInt8] { (0..<n).map { UInt8((v >> (8 * $0)) & 0xff) } }
    var bytes = [UInt8]("BM".utf8) + le(54 + row * h, 4) + le(0, 4) + le(54, 4)
    bytes += le(40, 4) + le(w, 4) + le(h, 4) + le(1, 2) + le(24, 2) + le(0, 4) + le(row * h, 4) + le(2835, 4) + le(2835, 4) + le(0, 4) + le(0, 4)
    for y in (0..<h).reversed() {
        var line = [UInt8]()
        for x in 0..<w {
            let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) ?? .black
            func ch(_ v: CGFloat) -> UInt8 { UInt8(max(0, min(255, (v * 255).rounded()))) }
            line += [ch(c.blueComponent), ch(c.greenComponent), ch(c.redComponent)]
        }
        line += [UInt8](repeating: 0, count: row - w * 3)
        bytes += line
    }
    try! Data(bytes).write(to: out.appendingPathComponent(name))
}

// MARK: Mac DMG window (660 x 400 points). Finder places the icons at y = 200 from the top.
let dmgW: CGFloat = 660, dmgH: CGFloat = 400
for scale in [1, 2] as [CGFloat] {
    let rep = render(dmgW, dmgH, scale: scale) {
        brandBackground(NSRect(x: 0, y: 0, width: dmgW, height: dmgH))

        // Title block: paw + name, centred as one unit
        let title = "Paws Off"
        let titleFont = rounded(22, .bold)
        let tw = (title as NSString).size(withAttributes: [.font: titleFont]).width
        let pawSize: CGFloat = 20, gap: CGFloat = 8
        let left = dmgW / 2 - (pawSize + gap + tw) / 2
        paw(in: NSRect(x: left, y: dmgH - 61, width: pawSize, height: pawSize), color: violet)
        (title as NSString).draw(at: NSPoint(x: left + pawSize + gap, y: dmgH - 65), withAttributes: [.font: titleFont, .foregroundColor: ink])
        text("Drag the app into Applications to install", rounded(13, .medium), ink.withAlphaComponent(0.6), centerX: dmgW / 2, y: dmgH - 92)

        // Arrow between the two icons (icon centres at x = 170 and 490, y = 200 from top)
        let y = dmgH - 200
        let shaft = NSBezierPath()
        shaft.move(to: NSPoint(x: 262, y: y))
        shaft.line(to: NSPoint(x: 392, y: y))
        shaft.lineWidth = 3
        shaft.lineCapStyle = .round
        let head = NSBezierPath()
        head.move(to: NSPoint(x: 380, y: y + 11))
        head.line(to: NSPoint(x: 394, y: y))
        head.line(to: NSPoint(x: 380, y: y - 11))
        head.lineWidth = 3
        head.lineCapStyle = .round
        head.lineJoinStyle = .round
        NSGraphicsContext.saveGraphicsState()
        let outline = shaft.copy() as! NSBezierPath
        outline.append(head)
        let stroked = NSBezierPath()
        stroked.append(outline)
        // Gradient stroke: clip to a widened outline by drawing the gradient through a stroke mask.
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.setLineWidth(3); ctx.setLineCap(.round); ctx.setLineJoin(.round)
            ctx.addPath(stroked.cgPath)
            ctx.replacePathWithStrokedPath()
            ctx.clip()
            NSGradient(starting: coral, ending: violet)!.draw(in: NSRect(x: 255, y: y - 14, width: 145, height: 28), angle: 0)
            ctx.restoreGState()
        }
        NSGraphicsContext.restoreGraphicsState()

        // First-launch tip
        text("First time opening it? System Settings → Privacy & Security → Open Anyway",
             rounded(11, .medium), ink.withAlphaComponent(0.45), centerX: dmgW / 2, y: 26)
    }
    save(rep, scale == 1 ? "dmg-background.png" : "dmg-background@2x.png")
}

// MARK: Windows installer wizard images (Inno Setup, modern style). 24-bit BMP, no alpha.
func wizardLarge(_ w: CGFloat, _ h: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: w, height: h)
    NSGradient(colors: [rgb(0.13, 0.11, 0.20), rgb(0.06, 0.06, 0.10)])!.draw(in: rect, angle: -90)
    glow(coral, NSPoint(x: w * 0.1, y: h * 0.85), w * 1.0, 0.45)
    glow(violet, NSPoint(x: w * 0.95, y: h * 0.25), w * 1.1, 0.45)
    // Gradient disc with a white paw, like the app's big button
    let d = w * 0.62, cx = w / 2, cy = h * 0.58
    let disc = NSBezierPath(ovalIn: NSRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d))
    NSGradient(starting: coral, ending: violet)!.draw(in: disc, angle: -45)
    let inner = NSBezierPath(ovalIn: NSRect(x: cx - d * 0.41, y: cy - d * 0.41, width: d * 0.82, height: d * 0.82))
    rgb(0.10, 0.08, 0.16, 0.30).setFill()
    inner.fill()
    paw(in: NSRect(x: cx - d * 0.2, y: cy - d * 0.2, width: d * 0.4, height: d * 0.4), color: .white)
    text("Paws Off", rounded(w * 0.125, .bold), .white, centerX: cx, y: h * 0.25)
    text("Made by Zaid", rounded(w * 0.06, .medium), NSColor.white.withAlphaComponent(0.6), centerX: cx, y: h * 0.19)
}

func wizardSmall(_ s: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    NSColor.white.setFill()
    rect.fill()
    let disc = NSBezierPath(ovalIn: rect.insetBy(dx: s * 0.06, dy: s * 0.06))
    NSGradient(starting: coral, ending: violet)!.draw(in: disc, angle: -45)
    paw(in: rect.insetBy(dx: s * 0.28, dy: s * 0.28), color: .white)
}

// Modern wizard image is 202x386 at 100% DPI; small image 64x64. Extra sizes for 150% and 200%.
for (i, scale) in ([1.0, 1.5, 2.0] as [CGFloat]).enumerated() {
    let pct = [100, 150, 200][i]
    saveBMP(render((202 * scale).rounded(), (386 * scale).rounded(), scale: 1) { wizardLarge((202 * scale).rounded(), (386 * scale).rounded()) }, "wizard-large-\(pct).bmp")
    saveBMP(render(64 * scale, 64 * scale, scale: 1) { wizardSmall(64 * scale) }, "wizard-small-\(pct).bmp")
}
print("Installer art written to \(out.path)")
