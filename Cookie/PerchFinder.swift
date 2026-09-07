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
        return guaranteedDockPerch(displaySize: displaySize)
    }

    /// Visible dock / bottom of `NSScreen.main` — first-sit fallback that cannot miss every display.
    static func guaranteedDockPerch(displaySize: NSSize) -> Perch {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        return dockOrDesktopPerch(displaySize: displaySize, screen: screen)
    }

    /// Keep the full overlay frame inside a screen's visible area (not just the feet point).
    static func clampWindowFrame(_ frame: NSRect, to screen: NSScreen) -> NSRect {
        let vis = screen.visibleFrame
        var f = frame
        if f.width >= vis.width {
            f.origin.x = vis.minX
        } else {
            f.origin.x = min(max(f.origin.x, vis.minX), vis.maxX - f.width)
        }
        if f.height >= vis.height {
            f.origin.y = vis.minY
        } else {
            f.origin.y = min(max(f.origin.y, vis.minY), vis.maxY - f.height)
        }
        return f
    }

    /// If `desired` would miss every display (stacked dual-display math), pin to main visibleFrame.
    static func onscreenFrame(_ desired: NSRect, preferred: NSScreen) -> NSRect {
        let onPreferred = clampWindowFrame(desired, to: preferred)
        if intersectsAnyVisibleScreen(onPreferred) {
            return onPreferred
        }
        let main = NSScreen.main ?? preferred
        let onMain = clampWindowFrame(desired, to: main)
        if intersectsAnyVisibleScreen(onMain) {
            return onMain
        }
        return clampWindowFrame(
            NSRect(origin: main.visibleFrame.origin, size: desired.size),
            to: main
        )
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
        let xLow = visible.minX + 40
        let xHigh = max(xLow + 1, visible.maxX - 40)
        let x = CGFloat.random(in: xLow...xHigh)
        let y = visible.minY + 8
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

    private static func intersectsAnyVisibleScreen(_ frame: NSRect) -> Bool {
        let probe = frame.insetBy(dx: 2, dy: 2)
        return NSScreen.screens.contains { $0.visibleFrame.intersects(probe) }
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

    /// CGWindowList: (0, 0) is the top-left of the primary display (AppKit origin-zero screen); y grows down.
    /// AppKit: (0, 0) is the bottom-left of that same display; y grows up.
    /// Using the union of all `maxY`s is wrong when a second display is stacked above the primary
    /// (e.g. Color LCD at (0,0,1470,956) + Dell at (0,956,2560,1440)).
    private static func quartzToAppKit(_ rect: CGRect) -> CGRect {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens[0]
        return CGRect(
            x: rect.origin.x,
            y: primary.frame.maxY - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
