import AppKit

/// Status item glyph: the app icon's search lens as a template image — solid
/// dark glass with the mask's eye slits cut out, plus the handle. Drawn in
/// code so it stays crisp and works without a bundle (`make run`).
enum MenuBarIcon {
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.set()

            let glass = NSBezierPath(ovalIn: NSRect(x: 1.2, y: 1.2, width: 12.6, height: 12.6))
            glass.windingRule = .evenOdd
            // Eye slits, lower at the inner end, mirrored around the lens centre.
            let leftEye: [CGPoint] = [
                CGPoint(x: 3.5, y: 6.7), CGPoint(x: 6.9, y: 7.7),
                CGPoint(x: 6.8, y: 9.2), CGPoint(x: 3.9, y: 8.4),
            ]
            glass.append(polygon(leftEye))
            glass.append(polygon(leftEye.map { CGPoint(x: 15 - $0.x, y: $0.y) }))
            glass.fill()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 11.9, y: 11.9))
            handle.line(to: NSPoint(x: 16.2, y: 16.2))
            handle.lineWidth = 2.6
            handle.lineCapStyle = .round
            handle.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Villain Caster"
        return image
    }

    private static func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: points[0])
        for point in points.dropFirst() { path.line(to: point) }
        path.close()
        return path
    }
}
