// Packs PNG icon sizes into a Windows .ico. Sizes below 256 are stored as classic 32-bit
// bitmaps (what the .NET Framework tray icon code expects); 256 is stored as PNG.
// Usage: swift Tools/make-ico.swift <out.ico> <16.png> <32.png> ... <256.png>
import AppKit

let out = CommandLine.arguments[1]
let inputs = CommandLine.arguments.dropFirst(2)

func le16(_ v: Int) -> [UInt8] { [UInt8(v & 0xff), UInt8((v >> 8) & 0xff)] }
func le32(_ v: Int) -> [UInt8] { le16(v & 0xffff) + le16((v >> 16) & 0xffff) }

func dib(_ rep: NSBitmapImageRep) -> [UInt8] {
    let w = rep.pixelsWide, h = rep.pixelsHigh
    var bytes = le32(40) + le32(w) + le32(h * 2) + le16(1) + le16(32) + le32(0) + le32(w * h * 4) + le32(0) + le32(0) + le32(0) + le32(0)
    for y in (0..<h).reversed() { // bottom-up rows, BGRA
        for x in 0..<w {
            let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) ?? .clear
            let a = c.alphaComponent
            func ch(_ v: CGFloat) -> UInt8 { UInt8(max(0, min(255, (v * 255).rounded()))) }
            bytes += [ch(c.blueComponent), ch(c.greenComponent), ch(c.redComponent), ch(a)]
        }
    }
    let maskRow = ((w + 31) / 32) * 4 // AND mask: all zero, alpha does the work
    bytes += [UInt8](repeating: 0, count: maskRow * h)
    return bytes
}

var entries: [UInt8] = []
var blobs: [UInt8] = []
var offset = 6 + 16 * inputs.count
for path in inputs {
    let data = try! Data(contentsOf: URL(fileURLWithPath: path))
    let rep = NSBitmapImageRep(data: data)!
    let size = rep.pixelsWide
    let blob = size >= 256 ? [UInt8](data) : dib(rep)
    entries += [UInt8(size % 256), UInt8(size % 256), 0, 0] + le16(1) + le16(32) + le32(blob.count) + le32(offset)
    blobs += blob
    offset += blob.count
}
let ico = le16(0) + le16(1) + le16(inputs.count) + entries + blobs
try! Data(ico).write(to: URL(fileURLWithPath: out))
print("Wrote \(out)")
