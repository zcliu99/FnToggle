// Generates AppIcon.icns: a black rounded-rectangle keycap with "fn" in black, on a white app tile.
// Usage: swift make-icon.swift <output.icns>
import Cocoa

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let k = CGFloat(pixels) / 1024.0
    let tile = NSRect(x: 100 * k, y: 100 * k, width: 824 * k, height: 824 * k)

    // App tile (standard macOS icon grid), white with a subtle top-to-bottom gradient.
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185 * k, yRadius: 185 * k)
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = 18 * k
    shadow.shadowOffset = NSSize(width: 0, height: -10 * k)
    shadow.set()
    NSColor.white.setFill()
    tilePath.fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    NSGradient(starting: .white, ending: NSColor(white: 0.90, alpha: 1))!.draw(in: tilePath, angle: -90)

    // Black rounded-rectangle keycap outline.
    let stroke = 40 * k
    let key = NSRect(x: 250 * k, y: 322 * k, width: 524 * k, height: 380 * k).insetBy(dx: stroke / 2, dy: stroke / 2)
    let keyPath = NSBezierPath(roundedRect: key, xRadius: 95 * k, yRadius: 95 * k)
    keyPath.lineWidth = stroke
    NSColor.black.setStroke()
    keyPath.stroke()

    // Black "fn" printed in a clean bold sans-serif.
    let font = NSFont(name: "HelveticaNeue-Bold", size: 250 * k) ?? NSFont.systemFont(ofSize: 250 * k, weight: .bold)
    let text = NSAttributedString(string: "fn", attributes: [.font: font, .foregroundColor: NSColor.black])
    let ts = text.size()
    text.draw(at: NSPoint(x: tile.midX - ts.width / 2, y: tile.midY - ts.height / 2 + 12 * k))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"
let iconset = NSTemporaryDirectory() + "AppIcon-\(getpid()).iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(pixels: base).write(to: URL(fileURLWithPath: "\(iconset)/icon_\(base)x\(base).png"))
    try! render(pixels: base * 2).write(to: URL(fileURLWithPath: "\(iconset)/icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset, "-o", out]
try! p.run(); p.waitUntilExit()
try? FileManager.default.removeItem(atPath: iconset)
exit(p.terminationStatus)
