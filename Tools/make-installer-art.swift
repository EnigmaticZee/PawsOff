// Draws the installer artwork: the Mac DMG window background and the Windows installer wizard images.
// Usage (from the repo root, after the icon is built): swift Tools/make-installer-art.swift <out-dir>
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

/// The app icon (Assets/AppIcon.icns, from Tools/make-icon.swift). Its artwork fills 824/1024 of the
/// image, so `rect` is grown to make the visible tile fill it.
let appIcon = NSImage(contentsOfFile: "Assets/AppIcon.icns")!
func icon(in rect: NSRect) {
    let grow = rect.width * (1024.0 / 824.0 - 1) / 2
    appIcon.draw(in: rect.insetBy(dx: -grow, dy: -grow), from: .zero, operation: .sourceOver, fraction: 1)
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

// MARK: Mac DMG window. Finder places the icons at y = 200 from the top (Tools/dmg-settings.py).
// Two versions:
// - dmg-background: today's, 660 x 596. Below the drag arrow, a step-by-step guide to the one-time
//   "Open Anyway" prompt (the app isn't notarized yet).
// - dmg-background-notarized: the clean 660 x 400 window with no guide, for once the app is notarized
//   (Tools/make-dmg.sh: NOTARIZED=1).

func paragraph(_ string: String, _ font: NSFont, _ color: NSColor, bold: [String] = [], align: NSTextAlignment = .left) -> NSAttributedString {
    let style = NSMutableParagraphStyle(); style.alignment = align; style.lineSpacing = 2
    let a = NSMutableAttributedString(string: string, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    for b in bold {
        let r = (string as NSString).range(of: b)
        if r.location != NSNotFound { a.addAttribute(.font, value: rounded(font.pointSize, .bold), range: r); a.addAttribute(.foregroundColor, value: ink, range: r) }
    }
    return a
}

/// A small drawing of the button to look for, so it's easy to spot on screen.
func mockButton(_ label: String, at origin: NSPoint, filled: Bool = false) -> CGFloat {
    let font = NSFont.systemFont(ofSize: 11.5, weight: .medium)
    let w = (label as NSString).size(withAttributes: [.font: font]).width + 26
    let r = NSRect(x: origin.x, y: origin.y, width: w, height: 22)
    let path = NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow(); shadow.shadowColor = rgb(0, 0, 0, 0.12); shadow.shadowBlurRadius = 2; shadow.shadowOffset = NSSize(width: 0, height: -1); shadow.set()
    (filled ? coral : rgb(1, 1, 1)).setFill(); path.fill()
    NSGraphicsContext.restoreGraphicsState()
    if !filled { rgb(0, 0, 0, 0.12).setStroke(); path.lineWidth = 0.75; path.stroke() }
    (label as NSString).draw(at: NSPoint(x: r.minX + 13, y: r.minY + 4), withAttributes: [.font: font, .foregroundColor: filled ? rgb(1, 1, 1) : ink])
    return w
}

let dmgW: CGFloat = 660

func drawDMG(height dmgH: CGFloat, guide: Bool) {
    brandBackground(NSRect(x: 0, y: 0, width: dmgW, height: dmgH))

    // Title block: icon + name, centred as one unit
    let title = "Paws Off"
    let titleFont = rounded(22, .bold)
    let tw = (title as NSString).size(withAttributes: [.font: titleFont]).width
    let iconSize: CGFloat = 26, gap: CGFloat = 9
    let left = dmgW / 2 - (iconSize + gap + tw) / 2
    icon(in: NSRect(x: left, y: dmgH - 64, width: iconSize, height: iconSize))
    (title as NSString).draw(at: NSPoint(x: left + iconSize + gap, y: dmgH - 65), withAttributes: [.font: titleFont, .foregroundColor: ink])
    text("Drag the app into Applications to install", rounded(13, .medium), ink.withAlphaComponent(0.6), centerX: dmgW / 2, y: dmgH - 92)

    // Arrow between the two icons (icon centres at x = 170 and 490, y = 200 from top)
    let y = dmgH - 200
    let shaft = NSBezierPath()
    shaft.move(to: NSPoint(x: 262, y: y))
    shaft.line(to: NSPoint(x: 392, y: y))
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 380, y: y + 11))
    head.line(to: NSPoint(x: 394, y: y))
    head.line(to: NSPoint(x: 380, y: y - 11))
    let outline = NSBezierPath()
    outline.append(shaft)
    outline.append(head)
    // Gradient stroke: clip to the stroked outline, then draw the gradient through it.
    if let ctx = NSGraphicsContext.current?.cgContext {
        ctx.saveGState()
        ctx.setLineWidth(3); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.addPath(outline.cgPath)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        NSGradient(starting: coral, ending: violet)!.draw(in: NSRect(x: 255, y: y - 14, width: 145, height: 28), angle: 0)
        ctx.restoreGState()
    }
    guard guide else { return }

    // The guide: a soft panel with three numbered steps, each with the button to look for. The bottom
    // 96 points stay clear: Finder may show its path bar and status bar there, over the window.
    let panel = NSRect(x: 24, y: 96, width: dmgW - 48, height: dmgH - 290 - 96)
    let panelPath = NSBezierPath(roundedRect: panel, xRadius: 16, yRadius: 16)
    rgb(1, 1, 1, 0.72).setFill(); panelPath.fill()
    rgb(0, 0, 0, 0.06).setStroke(); panelPath.lineWidth = 1; panelPath.stroke()
    paragraph("First time opening Paws Off? macOS asks you to confirm once:", rounded(14, .bold), ink)
        .draw(at: NSPoint(x: panel.minX + 20, y: panel.maxY - 34))

    let steps: [(text: String, bold: [String], button: String, filled: Bool, after: String)] = [
        ("Open Paws Off in Applications. When macOS blocks it, click", ["Paws Off"], "Done", false, ""),
        ("Go to System Settings → Privacy & Security and click", ["System Settings → Privacy & Security"], "Open Anyway", false, "Near the bottom. Then confirm with your password."),
        ("Click Grant Access, then switch on Paws Off in the list.", ["Grant Access"], "Grant Access", true, "That's it: look for the paw in your menu bar."),
    ]
    let colW = (panel.width - 40 - 2 * 20) / 3
    for (i, step) in steps.enumerated() {
        let x = panel.minX + 20 + CGFloat(i) * (colW + 20)
        let top = panel.maxY - 52
        // number badge
        let badge = NSBezierPath(ovalIn: NSRect(x: x, y: top - 22, width: 22, height: 22))
        NSGradient(starting: coral, ending: violet)!.draw(in: badge, angle: -45)
        text("\(i + 1)", rounded(12, .bold), .white, centerX: x + 11, y: top - 19)
        // text, wrapped to the column
        let body = paragraph(step.text, rounded(12, .regular), ink.withAlphaComponent(0.75), bold: step.bold)
        let size = body.boundingRect(with: NSSize(width: colW, height: 200), options: .usesLineFragmentOrigin).size
        let lineHeight = paragraph("A", rounded(12, .regular), ink).boundingRect(with: NSSize(width: colW, height: 200), options: .usesLineFragmentOrigin).height
        precondition(size.height < lineHeight * 2.5, "Step \(i + 1) wraps to more than two lines: widen the window or shorten it")
        body.draw(with: NSRect(x: x, y: top - 32 - size.height, width: colW, height: size.height), options: .usesLineFragmentOrigin)
        let buttonY = top - 32 - size.height - 30
        _ = mockButton(step.button, at: NSPoint(x: x, y: buttonY), filled: step.filled)
        if !step.after.isEmpty {
            let after = paragraph(step.after, rounded(11, .regular), ink.withAlphaComponent(0.5))
            let aSize = after.boundingRect(with: NSSize(width: colW, height: 100), options: .usesLineFragmentOrigin).size
            let noteLine = paragraph("A", rounded(11, .regular), ink).boundingRect(with: NSSize(width: colW, height: 100), options: .usesLineFragmentOrigin).height
            precondition(aSize.height < noteLine * 2.5, "The note under step \(i + 1) wraps to more than two lines")
            after.draw(with: NSRect(x: x, y: buttonY - 8 - aSize.height, width: colW, height: aSize.height), options: .usesLineFragmentOrigin)
        }
    }

}

for (name, height, guide) in [("dmg-background", 596, true), ("dmg-background-notarized", 400, false)] as [(String, CGFloat, Bool)] {
    for scale in [1, 2] as [CGFloat] {
        save(render(dmgW, height, scale: scale) { drawDMG(height: height, guide: guide) }, scale == 1 ? "\(name).png" : "\(name)@2x.png")
    }
}

// MARK: Windows installer wizard images (Inno Setup, modern style). 24-bit BMP, no alpha.
func wizardLarge(_ w: CGFloat, _ h: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: w, height: h)
    NSGradient(colors: [rgb(0.13, 0.11, 0.20), rgb(0.06, 0.06, 0.10)])!.draw(in: rect, angle: -90)
    glow(coral, NSPoint(x: w * 0.1, y: h * 0.85), w * 1.0, 0.45)
    glow(violet, NSPoint(x: w * 0.95, y: h * 0.25), w * 1.1, 0.45)
    // The app icon
    let d = w * 0.56, cx = w / 2, cy = h * 0.58
    icon(in: NSRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d))
    text("Paws Off", rounded(w * 0.125, .bold), .white, centerX: cx, y: h * 0.25)
    text("Made by Zaid", rounded(w * 0.06, .medium), NSColor.white.withAlphaComponent(0.6), centerX: cx, y: h * 0.19)
}

func wizardSmall(_ s: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    NSColor.white.setFill()
    rect.fill()
    icon(in: rect.insetBy(dx: s * 0.08, dy: s * 0.08))
}

// Modern wizard image is 202x386 at 100% DPI; small image 64x64. Extra sizes for 150% and 200%.
for (i, scale) in ([1.0, 1.5, 2.0] as [CGFloat]).enumerated() {
    let pct = [100, 150, 200][i]
    saveBMP(render((202 * scale).rounded(), (386 * scale).rounded(), scale: 1) { wizardLarge((202 * scale).rounded(), (386 * scale).rounded()) }, "wizard-large-\(pct).bmp")
    saveBMP(render(64 * scale, 64 * scale, scale: 1) { wizardSmall(64 * scale) }, "wizard-small-\(pct).bmp")
}
print("Installer art written to \(out.path)")
