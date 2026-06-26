import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

// Generates the 1024x1024 App Icon: four fanned, rounded cards in the game's original
// colour palette (Theme.Palette / CLAUDE.md colour table) on a dark table-like background.
// No borrowed visual language from any existing card game (brand safety).

let size = 1024.0
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size),
    bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no context") }

func hex(_ h: UInt32, alpha: CGFloat = 1) -> CGColor {
    let r = CGFloat((h >> 16) & 0xFF) / 255
    let g = CGFloat((h >> 8) & 0xFF) / 255
    let b = CGFloat(h & 0xFF) / 255
    return CGColor(red: r, green: g, blue: b, alpha: alpha)
}

// Background: dark table colour (matches Theme.Palette.tableDark).
ctx.setFillColor(hex(0x1C2526))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Subtle radial-ish vignette for depth (kept simple: a slightly lighter centre square).
ctx.setFillColor(hex(0x222D2E))
let inset = size * 0.06
ctx.fillEllipse(in: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2))

func roundedCardPath(center: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, radius: CGFloat) -> CGPath {
    var transform = CGAffineTransform(translationX: center.x, y: center.y)
    transform = transform.rotated(by: angle)
    let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    return path.copy(using: &transform) ?? path
}

let cardWidth = size * 0.30
let cardHeight = size * 0.46
let cardRadius = size * 0.045
let centerX = size / 2
let centerY = size / 2 + size * 0.02

// Four cards fanned out, matching CLAUDE.md's canonical colour order: Crimson, Cobalt, Jade, Amber.
let cards: [(UInt32, CGFloat, CGFloat)] = [
    (0xC0392B, -0.33, -size * 0.16),  // Crimson, far left
    (0x2471A3, -0.11, -size * 0.05),  // Cobalt
    (0x1E8449,  0.11,  size * 0.05),  // Jade
    (0xD4AC0D,  0.33,  size * 0.16),  // Amber, far right
]

for (colour, angle, xOffset) in cards {
    ctx.saveGState()
    let path = roundedCardPath(
        center: CGPoint(x: centerX + xOffset, y: centerY),
        width: cardWidth, height: cardHeight, angle: angle, radius: cardRadius
    )
    // Soft shadow.
    ctx.setShadow(offset: CGSize(width: 0, height: size * 0.01), blur: size * 0.02,
                   color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.addPath(path)
    ctx.setFillColor(hex(colour))
    ctx.fillPath()
    ctx.restoreGState()

    // White border for the playing-card look.
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    ctx.setLineWidth(size * 0.006)
    ctx.strokePath()
    ctx.restoreGState()
}

guard let image = ctx.makeImage() else { fatalError("no image") }

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("no destination")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outputURL.path)")
