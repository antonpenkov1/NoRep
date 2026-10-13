import AppKit

// App Store "Search Results" creative asset, 3840×2560.
// Usage: swift Tools/search_asset.swift <screenshots dir> <output png>
let W: CGFloat = 3840, H: CGFloat = 2560
let accent = NSColor(srgbRed: 1.0, green: 0.28, blue: 0.21, alpha: 1)
let green = NSColor(srgbRed: 0.24, green: 0.86, blue: 0.44, alpha: 1)
let gold = NSColor(srgbRed: 1.0, green: 0.78, blue: 0.22, alpha: 1)

func rounded(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if let d = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: d, size: size) { return f }
    return base
}

let dir = CommandLine.arguments[1], out = CommandLine.arguments[2]
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

NSGradient(colors: [NSColor(srgbRed: 0.12, green: 0.12, blue: 0.155, alpha: 1),
                    NSColor(srgbRed: 0.04, green: 0.04, blue: 0.06, alpha: 1)])!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

func glow(_ c: NSColor, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a: CGFloat) {
    NSGradient(colors: [c.withAlphaComponent(a), c.withAlphaComponent(0)])!
        .draw(fromCenter: NSPoint(x: x, y: y), radius: 0, toCenter: NSPoint(x: x, y: y), radius: r, options: [])
}
glow(accent, 2650, 1300, 1500, 0.30)
glow(accent, 700, 1500, 1100, 0.10)

// Logo mark
let ring = NSRect(x: 260, y: 1880, width: 170, height: 170)
let rp = NSBezierPath(ovalIn: ring); rp.lineWidth = 26; NSColor.white.setStroke(); rp.stroke()
let sl = NSBezierPath(); sl.move(to: NSPoint(x: ring.minX - 24, y: ring.minY - 24))
sl.line(to: NSPoint(x: ring.maxX + 24, y: ring.maxY + 24)); sl.lineWidth = 34; sl.lineCapStyle = .round
accent.setStroke(); sl.stroke()
NSAttributedString(string: "NoRep", attributes: [.font: rounded(190, .black), .foregroundColor: NSColor.white])
    .draw(at: NSPoint(x: 500, y: 1855))

// Headline + sub
let para = NSMutableParagraphStyle(); para.lineHeightMultiple = 0.95
NSAttributedString(string: "The WOD timer\nthat knows\nyour PRs", attributes: [
    .font: rounded(215, .heavy), .foregroundColor: NSColor.white, .paragraphStyle: para])
    .draw(in: NSRect(x: 260, y: 820, width: 1950, height: 950))
NSAttributedString(string: "EMOM · AMRAP · For Time · Tabata · Mix", attributes: [
    .font: rounded(92, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.62)])
    .draw(at: NSPoint(x: 265, y: 640))
NSAttributedString(string: "iPhone + Apple Watch", attributes: [
    .font: rounded(92, .bold), .foregroundColor: accent])
    .draw(at: NSPoint(x: 265, y: 500))

// Phones
func phone(_ file: String, cx: CGFloat, cy: CGFloat, width: CGFloat, tint: NSColor) {
    guard let img = NSImage(contentsOfFile: "\(dir)/\(file)") else { return }
    let h = width * 2868 / 1320
    let r = NSRect(x: cx - width / 2, y: cy - h / 2, width: width, height: h)
    let bezel = r.insetBy(dx: -22, dy: -22)
    glow(tint, cx, cy, width * 0.9, 0.18)
    NSGraphicsContext.current?.saveGraphicsState()
    let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.8)
    sh.shadowBlurRadius = 90; sh.shadowOffset = NSSize(width: 0, height: -30); sh.set()
    NSColor(srgbRed: 0.10, green: 0.10, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(roundedRect: bezel, xRadius: 120, yRadius: 120).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    let edge = NSBezierPath(roundedRect: bezel, xRadius: 120, yRadius: 120)
    edge.lineWidth = 4; NSColor.white.withAlphaComponent(0.15).setStroke(); edge.stroke()
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: r, xRadius: 100, yRadius: 100).addClip()
    img.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()
}
phone("04-journal.png", cx: 2420, cy: 1200, width: 720, tint: green)
phone("03-summary-pr.png", cx: 3330, cy: 1200, width: 720, tint: gold)
phone("02-workout.png", cx: 2875, cy: 1280, width: 840, tint: green)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print(out)
