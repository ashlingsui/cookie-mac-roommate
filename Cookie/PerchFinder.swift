import AppKit

/// Lower-right corner of the main screen. All Cookie motion stays in this rect.
enum Habitat {
    static func screen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }

    /// Bottom-right quadrant / corner zone of `NSScreen.main.visibleFrame`.
    static func zone() -> NSRect {
        let vis = screen().visibleFrame
        let width = min(vis.width, max(300, vis.width * 0.38))
        let height = min(vis.height, max(340, vis.height * 0.42))
        return NSRect(
            x: vis.maxX - width,
            y: vis.minY,
            width: width,
            height: height
        )
    }

    static func clampFrame(_ frame: NSRect) -> NSRect {
        let z = zone()
        var f = frame
        if f.width >= z.width {
            f.origin.x = z.minX
        } else {
            f.origin.x = min(max(f.origin.x, z.minX), z.maxX - f.width)
        }
        if f.height >= z.height {
            f.origin.y = z.minY
        } else {
            f.origin.y = min(max(f.origin.y, z.minY), z.maxY - f.height)
        }
        return f
    }

    static func randomFrame(size: NSSize, avoiding: NSRect? = nil) -> NSRect {
        let z = zone()
        let maxX = max(z.minX, z.maxX - size.width)
        let maxY = max(z.minY, z.maxY - size.height)
        func pick() -> NSRect {
            let origin = NSPoint(
                x: CGFloat.random(in: z.minX...maxX),
                y: CGFloat.random(in: z.minY...maxY)
            )
            return clampFrame(NSRect(origin: origin, size: size))
        }
        var frame = pick()
        if let avoid = avoiding {
            for _ in 0..<6 {
                if hypot(frame.midX - avoid.midX, frame.midY - avoid.midY) >= 90 { break }
                frame = pick()
            }
        }
        return frame
    }
}
