// Original geometric icon for Finder Menu Tools.
// Copyright 2026 Byron Delgado. Distributed under FSL-1.1-MIT.
// Regenerate from the repository root with: swift scripts/generate-icon.swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("MenuHelper/Assets.xcassets")
let iconSet = assets.appendingPathComponent("ForkAppIcon.appiconset")
let imageSet = assets.appendingPathComponent("ForkIcon.imageset")
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: imageSet, withIntermediateDirectories: true)

func render(pixels: Int, to destination: URL) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(pixels) / 1024)
    transform.concat()
    func rounded(_ rect: NSRect, radius: CGFloat, colour: NSColor) {
        colour.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
    rounded(NSRect(x: 64, y: 64, width: 896, height: 896), radius: 206,
            colour: NSColor(srgbRed: 0.10, green: 0.19, blue: 0.31, alpha: 1))
    rounded(NSRect(x: 194, y: 650, width: 285, height: 130), radius: 40,
            colour: NSColor(srgbRed: 0.34, green: 0.76, blue: 0.82, alpha: 1))
    rounded(NSRect(x: 194, y: 244, width: 636, height: 474), radius: 62,
            colour: NSColor(srgbRed: 0.91, green: 0.96, blue: 0.98, alpha: 1))
    let ink = NSColor(srgbRed: 0.10, green: 0.19, blue: 0.31, alpha: 1)
    for y in [568, 456, 344] {
        rounded(NSRect(x: 292, y: y, width: 44, height: 44), radius: 14, colour: ink)
        rounded(NSRect(x: 384, y: y, width: 342, height: 44), radius: 18, colour: ink)
    }
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: destination)
}

var icons: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)_\(scale)x.png"
        try render(pixels: size * scale, to: iconSet.appendingPathComponent(name))
        icons.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
var images: [[String: String]] = []
for scale in [1, 2, 3] {
    let name = "icon_\(scale)x.png"
    try render(pixels: 128 * scale, to: imageSet.appendingPathComponent(name))
    images.append(["filename": name, "idiom": "universal", "scale": "\(scale)x"])
}
for (directory, entries) in [(iconSet, icons), (imageSet, images)] {
    let json: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        .write(to: directory.appendingPathComponent("Contents.json"))
}
