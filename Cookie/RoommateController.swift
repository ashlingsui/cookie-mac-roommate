import AppKit
import CoreGraphics

final class RoommateController {
    private let window = OverlayWindow()
    private let spriteView = SpriteView()
    private var pose: Pose
    private var perchTimer: Timer?
    private var returnTimer: Timer?
    private var keyMonitor: Any?
    private var localKeyMonitor: Any?
    private var typePulse: Timer?
    private var typeHits = 0
    private var typeWindowStart = Date.distantPast
    private var lastSeenKeyAge: CFTimeInterval = .greatestFiniteMagnitude
    private var hiddenUntil: Date?
    private var lastFrontFrame: CGRect = .zero
    private var isDragging = false

    init() {
        pose = Pose.randomIdle()
        window.contentView = spriteView
        spriteView.onDragBegan = { [weak self] in
            self?.isDragging = true
            self?.window.lockMouse = true
            self?.window.ignoresMouseEvents = false
        }
        spriteView.onDragMoved = { [weak self] screen in self?.followDrag(screen) }
        spriteView.onDragEnded = { [weak self] velocity in self?.finishDrag(velocity) }
    }

    func start() {
        apply(pose: pose)
        window.startClickThroughTracking()
        sitOnNewPerch(animated: false)
        watchFrontWindow()
        watchTyping()
        SoundPlayer.shared.start()
    }

    deinit {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        typePulse?.invalidate()
        perchTimer?.invalidate()
        returnTimer?.invalidate()
    }

    func panicHide() {
        hideOffscreen(reason: "panic")
    }

    func revealIfHidden() {
        hiddenUntil = nil
        returnTimer?.invalidate()
        sitOnNewPerch(animated: false)
    }

    var isVisible: Bool {
        hiddenUntil == nil && window.isVisible
    }

    private func apply(pose: Pose) {
        self.pose = pose
        spriteView.image = pose.loadImage()
        let size = pose.displaySize()
        var frame = window.frame
        frame.size = size
        window.setFrame(frame, display: true)
    }

    private func sitOnNewPerch(animated: Bool) {
        hiddenUntil = nil
        let size = pose.displaySize()
        let perch = PerchFinder.next(displaySize: size)
        let feet = pose.feetOffset(displaySize: size)
        let origin = NSPoint(x: perch.feet.x - feet.x, y: perch.feet.y - feet.y)
        let frame = NSRect(origin: origin, size: size)
        window.alphaValue = 1
        window.orderFrontRegardless()
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(frame, display: true)
            }
        } else {
            window.setFrame(frame, display: true)
        }
    }

    private func watchFrontWindow() {
        perchTimer?.invalidate()
        perchTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: true) { [weak self] _ in
            self?.reconsiderPerch()
        }
        perchTimer?.tolerance = 0.4
    }

    private func reconsiderPerch() {
        if let until = hiddenUntil, Date() < until { return }
        if isDragging { return }

        let size = pose.displaySize()
        let perch = PerchFinder.next(displaySize: size)
        let front = frontmostFrame()
        let windowMoved = hypot(front.midX - lastFrontFrame.midX, front.midY - lastFrontFrame.midY) > 80
            || abs(front.width - lastFrontFrame.width) > 80
        lastFrontFrame = front

        if windowMoved {
            // New front window: pick a fresh idle pose sometimes, then sit on it.
            if Bool.random() {
                apply(pose: Pose.randomIdle())
            }
            sitOnNewPerch(animated: true)
            return
        }

        // Stay put unless we drifted far from any useful perch.
        let feet = currentFeet()
        if hypot(feet.x - perch.feet.x, feet.y - perch.feet.y) > 900 {
            sitOnNewPerch(animated: true)
        }
    }

    private func watchTyping() {
        // Accessibility is optional. Polling HID key age works without it;
        // the global monitor fires too if the user later grants trust.
        typePulse = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.pulseTyping()
        }
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.noteTyped()
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.noteTyped()
            return event
        }
    }

    private func pulseTyping() {
        let age = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .keyDown)
        if age < 0.28 && age < lastSeenKeyAge {
            noteTyped()
        }
        lastSeenKeyAge = age
    }

    /// Type-through: keys still go to the app underneath; Cookie just slides off.
    private func noteTyped() {
        if let until = hiddenUntil, Date() < until { return }
        if isDragging { return }
        guard window.alphaValue > 0.2 else { return }

        let now = Date()
        if now.timeIntervalSince(typeWindowStart) > 1.6 {
            typeHits = 0
            typeWindowStart = now
        }
        typeHits += 1
        if typeHits >= 4 {
            typeHits = 0
            shoveAside()
        }
    }

    private func followDrag(_ screen: NSPoint) {
        let size = window.frame.size
        let feet = pose.feetOffset(displaySize: size)
        let origin = NSPoint(x: screen.x - feet.x, y: screen.y - feet.y)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func finishDrag(_ velocity: CGVector) {
        isDragging = false
        window.lockMouse = false
        window.syncClickThrough()
        let speed = hypot(velocity.dx, velocity.dy)
        if speed > 40 {
            slideOff(direction: velocity)
        } else {
            shoveAside()
        }
    }

    private func shoveAside() {
        let dir = CGVector(dx: Bool.random() ? 420 : -420, dy: CGFloat.random(in: -40...80))
        slideOff(direction: dir)
    }

    private func slideOff(direction: CGVector) {
        var dx = direction.dx
        var dy = direction.dy
        let mag = max(1, hypot(dx, dy))
        dx = dx / mag * 520
        dy = dy / mag * 180
        var frame = window.frame
        frame.origin.x += dx
        frame.origin.y += dy
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.32
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(frame, display: true)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.hideOffscreen(reason: "shoo")
        }
    }

    private func hideOffscreen(reason: String) {
        window.alphaValue = 0
        window.orderOut(nil)
        let pause: TimeInterval = reason == "panic" ? 22 : TimeInterval.random(in: 7...14)
        hiddenUntil = Date().addingTimeInterval(pause)
        returnTimer?.invalidate()
        returnTimer = Timer.scheduledTimer(withTimeInterval: pause, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.apply(pose: Pose.random(excluding: self.pose))
            if self.pose.isDefaultIdle == false && Bool.random() {
                self.apply(pose: Pose.randomIdle())
            }
            self.sitOnNewPerch(animated: false)
        }
    }

    private func currentFeet() -> NSPoint {
        let feet = pose.feetOffset(displaySize: window.frame.size)
        return NSPoint(x: window.frame.minX + feet.x, y: window.frame.minY + feet.y)
    }

    private func frontmostFrame() -> CGRect {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return .zero
        }
        for window in info {
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            if layer != 0 { continue }
            let owner = window[kCGWindowOwnerName as String] as? String ?? ""
            if owner == "Cookie" { continue }
            if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
                return CGRect(
                    x: bounds["X"] ?? 0,
                    y: bounds["Y"] ?? 0,
                    width: bounds["Width"] ?? 0,
                    height: bounds["Height"] ?? 0
                )
            }
        }
        return .zero
    }
}
