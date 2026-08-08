import AppKit

let W = 1284, H = 2778

struct Slide {
    let shot: String
    let headline: String
    let sub: String
    let glow: NSColor
}

let accent = NSColor(srgbRed: 1.0, green: 0.28, blue: 0.21, alpha: 1)
let slides: [Slide] = [
    Slide(shot: "01-home.png",
          headline: "Every timer\nyour box uses",
          sub: "EMOM · AMRAP · For Time · Tabata · Mix",
          glow: accent),
    Slide(shot: "02-workout.png",
          headline: "Readable from\nacross the gym",
          sub: "Huge digits, loud cues, your WOD on screen",
          glow: NSColor(srgbRed: 0.24, green: 0.86, blue: 0.44, alpha: 1)),
    Slide(shot: "03-summary-pr.png",
          headline: "It knows when\nyou set a PR",
          sub: "Name your WOD — NoRep tracks every record",
          glow: NSColor(srgbRed: 1.0, green: 0.78, blue: 0.22, alpha: 1)),
    Slide(shot: "04-journal.png",
          headline: "Your training,\none screen",
          sub: "Streak, heatmap, splits and progress charts",
          glow: NSColor(srgbRed: 0.24, green: 0.86, blue: 0.44, alpha: 1)),
    Slide(shot: "05-benchmarks.png",
          headline: "Fran, Murph\n& 23 more",
          sub: "Benchmark WODs as one-tap presets",
          glow: NSColor(srgbRed: 1.0, green: 0.78, blue: 0.22, alpha: 1)),
    Slide(shot: "06-settings.png",
          headline: "Make it\nyours",
          sub: "6 sound packs · 5 icons · 7 languages",
          glow: NSColor(srgbRed: 0.27, green: 0.60, blue: 1.0, alpha: 1)),
]

func roundedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if let desc = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: desc, size: size) {
        return f
    }
    return base
}

let inputDir = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for slide in slides {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }
    rep.size = NSSize(width: W, height: H)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Background gradient
    let bg = NSGradient(colors: [
        NSColor(srgbRed: 0.115, green: 0.115, blue: 0.15, alpha: 1),
        NSColor(srgbRed: 0.04, green: 0.04, blue: 0.06, alpha: 1)
    ])!
    bg.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

    // Accent glow behind the phone
    let glowGrad = NSGradient(colors: [
        slide.glow.withAlphaComponent(0.32),
        slide.glow.withAlphaComponent(0.0)
    ])!
    glowGrad.draw(fromCenter: NSPoint(x: W / 2, y: 1050), radius: 0,
                  toCenter: NSPoint(x: W / 2, y: 1050), radius: 950, options: [])

    // Brand chip: ring + slash + name
    let chipY = CGFloat(H - 150)
    let ringRect = NSRect(x: CGFloat(W) / 2 - 150, y: chipY - 6, width: 44, height: 44)
    let ring = NSBezierPath(ovalIn: ringRect)
    ring.lineWidth = 7
    NSColor.white.setStroke()
    ring.stroke()
    let slash = NSBezierPath()
    slash.move(to: NSPoint(x: ringRect.minX - 7, y: ringRect.minY - 7))
    slash.line(to: NSPoint(x: ringRect.maxX + 7, y: ringRect.maxY + 7))
    slash.lineWidth = 9
    slash.lineCapStyle = .round
    accent.setStroke()
    slash.stroke()
    let brand = NSAttributedString(string: "NoRep", attributes: [
        .font: roundedFont(size: 52, weight: .black),
        .foregroundColor: NSColor.white
    ])
    brand.draw(at: NSPoint(x: CGFloat(W) / 2 - 88, y: chipY - 12))

    // Headline
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineHeightMultiple = 0.95
    let headline = NSAttributedString(string: slide.headline, attributes: [
        .font: roundedFont(size: 118, weight: .heavy),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ])
    headline.draw(in: NSRect(x: 40, y: H - 560, width: W - 80, height: 330))

    // Subheadline
    let sub = NSAttributedString(string: slide.sub, attributes: [
        .font: roundedFont(size: 46, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.62),
        .paragraphStyle: paragraph
    ])
    sub.draw(in: NSRect(x: 60, y: H - 680, width: W - 120, height: 90))

    // Phone: bezel + clipped screenshot, bleeding off the bottom
    guard let shot = NSImage(contentsOfFile: "\(inputDir)/\(slide.shot)") else { continue }
    let phoneW: CGFloat = 1010
    let shotAspect = 2868.0 / 1320.0
    let phoneH = phoneW * shotAspect
    let bezelPad: CGFloat = 18
    let phoneX = (CGFloat(W) - phoneW) / 2
    let phoneTop = CGFloat(H) - 760
    let phoneRect = NSRect(x: phoneX, y: phoneTop - phoneH, width: phoneW, height: phoneH)
    let bezelRect = phoneRect.insetBy(dx: -bezelPad, dy: -bezelPad)

    // Shadow + bezel
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.75)
    shadow.shadowBlurRadius = 70
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    NSColor(srgbRed: 0.10, green: 0.10, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(roundedRect: bezelRect, xRadius: 108, yRadius: 108).fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Bezel edge highlight
    let edge = NSBezierPath(roundedRect: bezelRect, xRadius: 108, yRadius: 108)
    edge.lineWidth = 3
    NSColor.white.withAlphaComponent(0.14).setStroke()
    edge.stroke()

    // Screenshot clipped inside
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: phoneRect, xRadius: 90, yRadius: 90).addClip()
    shot.draw(in: phoneRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()

    if let png = rep.representation(using: .png, properties: [:]) {
        let out = "\(outputDir)/\(slide.shot)"
        try? png.write(to: URL(fileURLWithPath: out))
        print(out)
    }
}
