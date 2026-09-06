import AppKit

final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// When true, keep receiving mouse events even if the cursor leaves the fur.
    var lockMouse: Bool = false
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 2)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        animationBehavior = .none
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }

    func startClickThroughTracking() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] _ in
            self?.syncClickThrough()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.syncClickThrough()
            return event
        }
        syncClickThrough()
    }

    func syncClickThrough() {
        if lockMouse {
            ignoresMouseEvents = false
            return
        }
        guard let sprite = contentView as? SpriteView else { return }
        let viewPoint = sprite.convert(convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        ignoresMouseEvents = !sprite.hitsOpaque(viewPoint)
    }

    /// Pass clicks through holes in the cutout so the user's app stays usable.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || event.type == .rightMouseDown {
            let local = contentView?.convert(event.locationInWindow, from: nil) ?? .zero
            if let sprite = contentView as? SpriteView, !sprite.hitsOpaque(local) {
                return
            }
        }
        super.sendEvent(event)
    }
}

final class SpriteView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    var onDragBegan: (() -> Void)?
    var onDragMoved: ((NSPoint) -> Void)?
    var onDragEnded: ((CGVector) -> Void)?

    private var dragStartScreen: NSPoint?
    private var lastDragScreen: NSPoint?
    private var lastDragTime: TimeInterval = 0

    override var isOpaque: Bool { false }
    override var wantsDefaultClipping: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        image?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
    }

    func hitsOpaque(_ point: NSPoint) -> Bool {
        guard let image, bounds.contains(point), bounds.width > 0, bounds.height > 0 else {
            return false
        }
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else {
            return true
        }
        let px = Int((point.x / bounds.width) * CGFloat(rep.pixelsWide))
        let pyFromBottom = Int((point.y / bounds.height) * CGFloat(rep.pixelsHigh))
        let py = max(0, rep.pixelsHigh - 1 - pyFromBottom)
        let x = min(max(px, 0), rep.pixelsWide - 1)
        let y = min(max(py, 0), rep.pixelsHigh - 1)
        return (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.12
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        guard hitsOpaque(local) else { return }
        dragStartScreen = NSEvent.mouseLocation
        lastDragScreen = dragStartScreen
        lastDragTime = ProcessInfo.processInfo.systemUptime
        onDragBegan?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragStartScreen != nil else { return }
        let now = NSEvent.mouseLocation
        onDragMoved?(now)
        lastDragScreen = now
        lastDragTime = ProcessInfo.processInfo.systemUptime
    }

    override func mouseUp(with event: NSEvent) {
        guard let last = lastDragScreen, let start = dragStartScreen else { return }
        let dt = max(0.016, ProcessInfo.processInfo.systemUptime - lastDragTime)
        let delta = CGVector(dx: (NSEvent.mouseLocation.x - last.x) / dt, dy: (NSEvent.mouseLocation.y - last.y) / dt)
        let travel = hypot(NSEvent.mouseLocation.x - start.x, NSEvent.mouseLocation.y - start.y)
        dragStartScreen = nil
        lastDragScreen = nil
        onDragEnded?(travel > 8 ? delta : .zero)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        hitsOpaque(point) ? self : nil
    }
}
