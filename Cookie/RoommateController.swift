import AppKit

final class RoommateController {
    private let window = OverlayWindow()
    private let spriteView = SpriteView()
    private let bubble = SpeechBubble()
    private var pose: Pose
    private var roamTimer: Timer?
    private var returnTimer: Timer?
    private var hiddenUntil: Date?
    private var isDragging = false
    private var isBusy = false
    private var pendingBubble = false
    private var pendingBubbleLines: [String]?
    private var pendingEnterBox = false
    private var inBox = false
    private var moveGeneration = 0
    /// Hold still on first sit so launch is visible before idle roam starts.
    private var roamAllowedAt = Date.distantFuture

    private static let boxSpeech = ["mine", "busy"]

    init() {
        pose = Pose.randomIdle()
        window.contentView = spriteView
        spriteView.onDragBegan = { [weak self] in
            guard let self, !self.isInBox else { return }
            self.isDragging = true
            self.window.lockMouse = true
            self.window.ignoresMouseEvents = false
        }
        spriteView.onDragMoved = { [weak self] screen in self?.followDrag(screen) }
        spriteView.onDragEnded = { [weak self] in self?.finishDrag() }
        spriteView.onClicked = { [weak self] in self?.clicked() }
    }

    func start() {
        apply(pose: pose)
        window.startClickThroughTracking()
        goTo(Habitat.randomFrame(size: pose.displaySize()), animated: false, dash: false)
        roamAllowedAt = Date().addingTimeInterval(4)
        watchIdle()
        SoundPlayer.shared.start()
    }

    deinit {
        roamTimer?.invalidate()
        returnTimer?.invalidate()
    }

    /// Photo suitcase in the habitat. No auto-return timer.
    var isInBox: Bool { inBox || pendingEnterBox }

    func panicHide() {
        leaveBoxState()
        bubble.hide()
        hideOffscreen()
    }

    /// Dash into the lower-right habitat, then stay as the photo suitcase until click or Come out.
    func hideInBox() {
        if isInBox { return }
        bubble.hide()
        pendingBubble = false
        pendingBubbleLines = nil
        hiddenUntil = nil
        returnTimer?.invalidate()
        pendingEnterBox = true
        spriteView.allowsDrag = false
        goTo(
            Habitat.randomFrame(size: pose.displaySize(), avoiding: window.frame),
            animated: true,
            dash: true
        )
    }

    /// Leave the suitcase and dash to another habitat spot.
    func comeOut() {
        guard isInBox else { return }
        leaveBoxState()
        pendingBubble = true
        pendingBubbleLines = Self.boxSpeech
        apply(pose: Pose.randomIdle())
        goTo(
            Habitat.randomFrame(size: pose.displaySize(), avoiding: window.frame),
            animated: true,
            dash: true
        )
    }

    /// Persist a Size-menu scale and resize the current pose in place.
    func setSpriteScale(_ scale: CGFloat) {
        SpriteScale.current = scale
        apply(pose: pose)
    }

    var isVisible: Bool {
        hiddenUntil == nil && window.isVisible
    }

    private func leaveBoxState() {
        inBox = false
        pendingEnterBox = false
        spriteView.allowsDrag = true
    }

    private func apply(pose: Pose) {
        self.pose = pose
        spriteView.image = pose.loadImage()
        let size = pose.displaySize()
        var frame = window.frame
        frame.size = size
        window.setFrame(Habitat.clampFrame(frame), display: true)
    }

    private func goTo(_ desired: NSRect, animated: Bool, dash: Bool) {
        hiddenUntil = nil
        let frame = Habitat.clampFrame(desired)
        present(frame: frame, animated: animated, dash: dash)
    }

    private func present(frame: NSRect, animated: Bool, dash: Bool) {
        moveGeneration += 1
        let generation = moveGeneration
        window.alphaValue = 1
        window.orderFrontRegardless()
        if animated {
            isBusy = true
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = dash ? 0.18 : 0.45
                ctx.timingFunction = CAMediaTimingFunction(name: dash ? .easeInEaseOut : .easeInEaseOut)
                window.animator().setFrame(frame, display: true)
            } completionHandler: { [weak self] in
                guard let self, generation == self.moveGeneration else { return }
                self.isBusy = false
                self.finishPresent()
            }
        } else {
            window.setFrame(frame, display: true)
            finishPresent()
        }
    }

    private func finishPresent() {
        window.alphaValue = 1
        window.setFrame(Habitat.clampFrame(window.frame), display: true)
        window.orderFrontRegardless()
        if !window.isVisible {
            NSLog("Cookie: overlay not visible after sit; retrying orderFrontRegardless")
            window.orderFrontRegardless()
        }
        if !window.isVisible {
            NSLog("Cookie: overlay still not visible (frame \(NSStringFromRect(window.frame)))")
        }
        if pendingEnterBox {
            pendingEnterBox = false
            apply(pose: .suitcase)
            inBox = true
            spriteView.allowsDrag = false
        }
        if pendingBubble {
            pendingBubble = false
            let lines = pendingBubbleLines
            pendingBubbleLines = nil
            bubble.show(near: window.frame, choosingFrom: lines)
        }
    }

    private func watchIdle() {
        roamTimer?.invalidate()
        roamTimer = Timer.scheduledTimer(withTimeInterval: 6.5, repeats: true) { [weak self] _ in
            self?.idleStep()
        }
        roamTimer?.tolerance = 0.8
    }

    /// Roam / pace / pose-swap inside the right-corner habitat only.
    private func idleStep() {
        if isInBox { return }
        if Date() < roamAllowedAt { return }
        if let until = hiddenUntil, Date() < until { return }
        if isDragging || isBusy { return }

        if Bool.random() {
            apply(pose: Pose.random(excluding: pose))
        }
        goTo(
            Habitat.randomFrame(size: pose.displaySize(), avoiding: window.frame),
            animated: true,
            dash: false
        )
    }

    /// Out: dash + speech (not hide). In box: come out.
    private func clicked() {
        if let until = hiddenUntil, Date() < until { return }
        if isBusy { return }
        if isInBox {
            comeOut()
            return
        }
        pendingBubble = true
        pendingBubbleLines = nil
        apply(pose: Pose.random(excluding: pose))
        goTo(
            Habitat.randomFrame(size: pose.displaySize(), avoiding: window.frame),
            animated: true,
            dash: true
        )
    }

    private func followDrag(_ screen: NSPoint) {
        if isInBox { return }
        let size = window.frame.size
        let feet = pose.feetOffset(displaySize: size)
        let origin = NSPoint(x: screen.x - feet.x, y: screen.y - feet.y)
        window.setFrame(Habitat.clampFrame(NSRect(origin: origin, size: size)), display: true)
    }

    private func finishDrag() {
        isDragging = false
        window.lockMouse = false
        window.syncClickThrough()
        window.setFrame(Habitat.clampFrame(window.frame), display: true)
        window.orderFrontRegardless()
    }

    private func hideOffscreen() {
        window.alphaValue = 0
        window.orderOut(nil)
        hiddenUntil = Date().addingTimeInterval(22)
        returnTimer?.invalidate()
        returnTimer = Timer.scheduledTimer(withTimeInterval: 22, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.apply(pose: Pose.randomIdle())
            self.goTo(Habitat.randomFrame(size: self.pose.displaySize()), animated: false, dash: false)
        }
    }
}
