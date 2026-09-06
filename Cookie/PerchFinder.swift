import AppKit
import CoreGraphics


struct Perch {
    /// Screen-space point the sprite's feet should sit on.
    let feet: NSPoint
    let screen: NSScreen
}

enum PerchFinder {
    static func next(displaySize: NSSize) -> Perch {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        if let window = frontmostWorkWindow(on: screen) {
            return perch(onWindow: window, displaySize: displaySize, screen: screen)
        }
        return dockOrDesktopPerch(displaySize: displaySize, screen: screen)
    }

    /// Cat-honest: often an edge, sometimes on the content the user is looking at.
    private static func perch(onWindow window: CGRect, displaySize: NSSize, screen: NSScreen) -> Perch {
        let inset: CGFloat = 24
        let usable = window.insetBy(dx: inset, dy: 8)
        guard usable.width > 80, usable.height > 60 else {
            return dockOrDesktopPerch(displaySize: displaySize, screen: screen)
        }

        let roll = Int.random(in: 0..<100)
        let feet: NSPoint
        if roll < 40 {
            // Title-bar / top edge.
            feet = NSPoint(
                x: CGFloat.random(in: usable.minX...usable.maxX),
                y: window.maxY - 6
            )
        } else if roll < 70 {
            // Bottom edge of the window (or just onto the dock if it's low).
            feet = NSPoint(
                x: CGFloat.random(in: usable.minX...usable.maxX),
                y: window.minY + 4
            )
        } else {
            // Overlap the work: feet land inside the content, sprite covers text.
            let x = CGFloat.random(in: usable.minX...usable.maxX)
            let yLow = usable.minY + usable.height * 0.25
            let yHigh = usable.minY + usable.height * 0.72
            feet = NSPoint(x: x, y: CGFloat.random(in: min(yLow, yHigh)...max(yLow, yHigh)))
        }
        return Perch(feet: clampFeet(feet, displaySize: displaySize, screen: screen), screen: screen)
    }

    private static func dockOrDesktopPerch(displaySize: NSSize, screen: NSScreen) -> Perch {
        let visible = screen.visibleFrame
        let frame = screen.frame
        let dockOnBottom = visible.minY > frame.minY + 8
        let x = CGFloat.random(in: (visible.minX + 40)...max(visible.minX + 41, visible.maxX - 40))
        let y: CGFloat
        if dockOnBottom {
            y = visible.minY + 2
        } else {
            y = visible.minY + 10
        }
        return Perch(feet: clampFeet(NSPoint(x: x, y: y), displaySize: displaySize, screen: screen), screen: screen)
    }

    private static func clampFeet(_ feet: NSPoint, displaySize: NSSize, screen: NSScreen) -> NSPoint {
        let vis = screen.visibleFrame
        let pad: CGFloat = 8
        return NSPoint(
            x: min(max(feet.x, vis.minX + pad), vis.maxX - pad),
            y: min(max(feet.y, vis.minY + pad), vis.maxY - pad)
        )
    }

    private static func frontmostWorkWindow(on screen: NSScreen) -> CGRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let screenFrame = screen.frame
        for window in info {
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            if layer != 0 { continue }

            let owner = window[kCGWindowOwnerName as String] as? String ?? ""
            if owner == "Cookie" || owner == "Window Server" || owner == "Dock" { continue }

            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            // Quartz coords are top-left; convert to AppKit bottom-left.
            let q = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            if q.width < 180 || q.height < 120 { continue }

            let appKit = quartzToAppKit(q)
            if !appKit.intersects(screenFrame.insetBy(dx: 4, dy: 4)) { continue }
            return appKit
        }
        return nil
    }

    private static func quartzToAppKit(_ rect: CGRect) -> CGRect {
        guard let screen = NSScreen.screens.first else { return rect }
        // Combined display space: Quartz y grows down from the top of the primary-origin space.
        let globalHeight = NSScreen.screens.map(\.frame.maxY).max() ?? screen.frame.maxY
        return CGRect(
            x: rect.origin.x,
            y: globalHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
