import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Draws the Inly app icon: white "inly" wordmark in the app's rounded system font on near-black,
// with a blue dot over a dotless i. Usage: swift make_icon.swift <output.png>
let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

let night = CGColor(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0F / 255, alpha: 1)
let blue = CGColor(red: 0x5B / 255, green: 0x9D / 255, blue: 0xFF / 255, alpha: 1)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

let space = CGColorSpaceCreateDeviceRGB()
// No alpha channel: App Store icons must be opaque.
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("no context") }

ctx.setFillColor(night)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let fontSize: CGFloat = 342          // 60 / 180 of the canvas, as in the preview
let base = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
let rounded = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
let font = NSFont(descriptor: rounded, size: fontSize) ?? base

func line(_ text: String) -> CTLine {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
}
func width(_ l: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil)) }

let dotless = line("\u{0131}")       // i without its dot
let rest = line("nly")
let gap: CGFloat = 4
let total = width(dotless) + gap + width(rest)
let startX = (CGFloat(size) - total) / 2
let baseline = CGFloat(size) * (1 - 112.0 / 180.0)   // 112/180 down from the top

ctx.textPosition = CGPoint(x: startX, y: baseline)
CTLineDraw(dotless, ctx)
ctx.textPosition = CGPoint(x: startX + width(dotless) + gap, y: baseline)
CTLineDraw(rest, ctx)

// The dot: centred over the stem, 0.8 em above the baseline, radius 8/60 em.
let stemCenter = startX + width(dotless) / 2
let radius = fontSize * 8 / 60
let dotCenterY = baseline + fontSize * 0.8
ctx.setFillColor(blue)
ctx.fillEllipse(in: CGRect(x: stemCenter - radius, y: dotCenterY - radius, width: radius * 2, height: radius * 2))

guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("cannot write") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("finalize failed") }
print("wrote \(out)")
