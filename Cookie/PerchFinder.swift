import AppKit

/// Lower-right corner of the main screen. All Cookie motion stays in this rect.
enum Habitat {
    static func screen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }

    /// Bottom-right band of `NSScreen.main.visibleFrame`.
    /// Right ~36% of width, bottom ~28% of height — no large min-height floor
    /// (that used to let roam climb into mid/upper screen).
    static func zone() -> NSRect {
        let vis = screen().visibleFrame
        let width = vis.width * 0.36
        let height = vis.height * 0.28
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
