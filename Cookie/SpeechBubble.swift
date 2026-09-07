import AppKit

final class SpeechBubble {
    private let panel: NSPanel
    private let label: NSTextField
    private var hideTimer: Timer?
    private var lastShown = Date.distantPast
    private let cooldown: TimeInterval = 9

    private static let lines = [
        "I will pee on your bed",
        "That's my keyboard now.",
        "You work. I judge.",
        "Move. This is my sun.",
        "I knocked it off on purpose.",
        "Feed me or else.",
    ]

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.animationBehavior = .none
        panel.ignoresMouseEvents = true

        let box = NSView(frame: panel.frame)
        box.autoresizingMask = [.width, .height]
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(calibratedWhite: 0.98, alpha: 0.94).cgColor
        box.layer?.cornerRadius = 12
        box.layer?.borderWidth = 1
        box.layer?.borderColor = NSColor(calibratedWhite: 0.15, alpha: 0.25).cgColor

        label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = true
        box.addSubview(label)
        panel.contentView = box
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        panel.orderOut(nil)
    }

    func show(near cookie: NSRect) {
        guard !SoundPlayer.shared.isMuted else { return }
        guard Date().timeIntervalSince(lastShown) >= cooldown else { return }
        lastShown = Date()

        let line = Self.lines.randomElement() ?? "I will pee on your bed"
        label.stringValue = line
        let textSize = label.sizeThatFits(NSSize(width: 240, height: 64))
        let pad: CGFloat = 14
        let size = NSSize(width: min(260, max(160, textSize.width + pad * 2)), height: textSize.height + pad * 2)
        label.frame = NSRect(x: pad, y: pad, width: size.width - pad * 2, height: size.height - pad * 2)

        // Sit the bubble above-left of Cookie so it stays readable in the corner.
        var origin = NSPoint(x: cookie.minX - size.width + 36, y: cookie.maxY + 8)
        let vis = Habitat.screen().visibleFrame
        origin.x = min(max(origin.x, vis.minX + 6), vis.maxX - size.width - 6)
        origin.y = min(max(origin.y, vis.minY + 6), vis.maxY - size.height - 6)

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.contentView?.frame = NSRect(origin: .zero, size: size)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.6, repeats: false) { [weak self] _ in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                self.panel.animator().alphaValue = 0
            } completionHandler: {
                self.panel.orderOut(nil)
            }
        }
    }
}
