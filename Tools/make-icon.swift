// Renders the Paws Off app icon: a white keycap with a paw on it, on the Lock button's
// coral-to-violet. Usage: swift Tools/make-icon.swift <out-dir>   (or run Tools/make-icons.sh)
// Writes <out-dir>/AppIcon.iconset (for iconutil) and <out-dir>/ico/<size>.png (for the Windows .ico).
// Everything is drawn here (no SF Symbols: their licence doesn't allow use in app icons).
// Colours follow Palette.idle in Sources/Theme.swift, warmed slightly at the coral end.
import AppKit
import SwiftUI

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = out.appendingPathComponent("AppIcon.iconset"), icoDir = out.appendingPathComponent("ico")
for d in [iconset, icoDir] { try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true) }

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }
func hex(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    c(CGFloat((h >> 16) & 255) / 255, CGFloat((h >> 8) & 255) / 255, CGFloat(h & 255) / 255, a)
}
func grad(_ cols: [CGColor], _ locs: [CGFloat]? = nil) -> CGGradient { CGGradient(colorsSpace: cs, colors: cols as CFArray, locations: locs)! }
func top(_ r: CGRect) -> CGPoint { CGPoint(x: r.midX, y: r.maxY) }
func bottom(_ r: CGRect) -> CGPoint { CGPoint(x: r.midX, y: r.minY) }

let tileColours = [hex(0xFF9672), hex(0xE77E9E), hex(0xA96CF0)]
let pawColours = [hex(0xFF8A6C), hex(0xE06CB4), hex(0x9C5CF2)]

/// Apple's continuous-corner tile on the macOS icon grid (824 of 1024, radius 185).
func tile(_ s: CGFloat) -> (CGRect, CGPath) {
    let inset = s * 100 / 1024
    let r = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    return (r, RoundedRectangle(cornerRadius: r.width * 185 / 824, style: .continuous).path(in: r).cgPath)
}

/// Cat paw: four toes and a pad with two soft lobes, centred at `center`, `size` wide.
func pawPath(center: CGPoint, size s: CGFloat) -> CGPath {
    let p = CGMutablePath()
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: center.x + x * s, y: center.y + y * s) }
    p.move(to: pt(0, 0))
    p.addCurve(to: pt(0.28, -0.22), control1: pt(0.17, 0), control2: pt(0.28, -0.11))
    p.addCurve(to: pt(0.15, -0.43), control1: pt(0.30, -0.35), control2: pt(0.24, -0.43))
    p.addCurve(to: pt(0, -0.39), control1: pt(0.08, -0.43), control2: pt(0.05, -0.39))
    p.addCurve(to: pt(-0.15, -0.43), control1: pt(-0.05, -0.39), control2: pt(-0.08, -0.43))
    p.addCurve(to: pt(-0.28, -0.22), control1: pt(-0.24, -0.43), control2: pt(-0.30, -0.35))
    p.addCurve(to: pt(0, 0), control1: pt(-0.28, -0.11), control2: pt(-0.17, 0))
    p.closeSubpath()
    for (x, y, rot) in [(-0.355, 0.10, 0.42), (-0.13, 0.30, 0.12), (0.13, 0.30, -0.12), (0.355, 0.10, -0.42)] as [(CGFloat, CGFloat, CGFloat)] {
        let t = CGAffineTransform(translationX: center.x + x * s, y: center.y + y * s).rotated(by: rot)
        p.addEllipse(in: CGRect(x: -0.095 * s, y: -0.13 * s, width: 0.19 * s, height: 0.26 * s), transform: t)
    }
    return p
}

func fillDiagonal(_ ctx: CGContext, _ path: CGPath, _ cols: [CGColor], _ locs: [CGFloat]? = nil) {
    let b = path.boundingBox
    ctx.saveGState(); ctx.addPath(path); ctx.clip()
    ctx.drawLinearGradient(grad(cols, locs), start: CGPoint(x: b.minX + b.width * 0.1, y: b.maxY),
                           end: CGPoint(x: b.maxX - b.width * 0.1, y: b.minY), options: [])
    ctx.restoreGState()
}

func render(_ px: Int) -> NSBitmapImageRep {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let s = CGFloat(px)
    let (r, shape) = tile(s)

    // Tile with a soft drop shadow, the brand gradient and a little daylight from above.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.010), blur: s * 0.025, color: c(0, 0, 0, 0.30))
    ctx.addPath(shape); ctx.setFillColor(hex(0xC772C8)); ctx.fillPath()
    ctx.restoreGState()
    fillDiagonal(ctx, shape, tileColours, [0, 0.45, 1])
    ctx.saveGState(); ctx.addPath(shape); ctx.clip()
    ctx.drawLinearGradient(grad([c(1, 1, 1, 0.16), c(1, 1, 1, 0)]), start: top(r), end: CGPoint(x: r.midX, y: r.midY), options: [])
    ctx.restoreGState()

    if px <= 24 {
        // Tiny sizes (Finder lists, the Windows tray): just a white paw, so it stays legible.
        ctx.addPath(pawPath(center: CGPoint(x: r.midX, y: r.midY + r.height * 0.08), size: r.width * 0.78))
        ctx.setFillColor(c(1, 1, 1)); ctx.fillPath()
    } else {
        drawKey(ctx, center: CGPoint(x: r.midX, y: r.midY - s * 0.012), u: r.width * 0.62, s: s)
    }

    // Glassy rim, brightest along the top edge.
    ctx.saveGState()
    ctx.addPath(shape.copy(strokingWithWidth: s * 0.005, lineCap: .round, lineJoin: .round, miterLimit: 1)); ctx.clip()
    ctx.drawLinearGradient(grad([c(1, 1, 1, 0.55), c(1, 1, 1, 0.06), c(1, 1, 1, 0.15)], [0, 0.6, 1]), start: top(r), end: bottom(r), options: [])
    ctx.restoreGState()

    return NSBitmapImageRep(cgImage: ctx.makeImage()!)
}

/// A porcelain keycap seen from slightly in front: sides below, a dished top face, the paw printed on it.
func drawKey(_ ctx: CGContext, center: CGPoint, u: CGFloat, s: CGFloat) {
    let outer = CGRect(x: center.x - u / 2, y: center.y - u / 2, width: u, height: u)
    let body = CGPath(roundedRect: outer, cornerWidth: u * 0.16, cornerHeight: u * 0.16, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.019), blur: s * 0.035, color: hex(0x5A2A9A, 0.42))
    ctx.addPath(body); ctx.setFillColor(hex(0xCFC9DA)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(body); ctx.clip()
    ctx.drawLinearGradient(grad([hex(0xFFFFFF), hex(0xCFC9DA)]), start: top(outer), end: bottom(outer), options: [])
    ctx.restoreGState()

    let face = CGRect(x: outer.minX + u * 0.11, y: outer.minY + u * 0.17, width: u * 0.78, height: u * 0.78)
    let facePath = CGPath(roundedRect: face, cornerWidth: u * 0.11, cornerHeight: u * 0.11, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.003), blur: s * 0.010, color: c(0, 0, 0, 0.25))
    ctx.addPath(facePath); ctx.setFillColor(hex(0xFFFFFF)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(facePath); ctx.clip()
    ctx.drawLinearGradient(grad([hex(0xECE8F2), hex(0xFFFFFF), hex(0xFFFFFF)]), start: top(face), end: bottom(face), options: [])
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(facePath.copy(strokingWithWidth: max(1, s * 0.003), lineCap: .round, lineJoin: .round, miterLimit: 1)); ctx.clip()
    ctx.drawLinearGradient(grad([c(1, 1, 1, 0), c(1, 1, 1, 0.55)]), start: top(face), end: bottom(face), options: [])
    ctx.restoreGState()

    fillDiagonal(ctx, pawPath(center: CGPoint(x: face.midX, y: face.midY + face.height * 0.055), size: face.width * 0.74),
                 pawColours, [0, 0.5, 1])
}

func write(_ rep: NSBitmapImageRep, _ url: URL) throws {
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

for base in [16, 32, 128, 256, 512] {
    try write(render(base), iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try write(render(base * 2), iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
for size in [16, 20, 24, 32, 40, 48, 64, 128, 256] {
    try write(render(size), icoDir.appendingPathComponent("\(size).png"))
}
print("Icon written to \(out.path)")
