import AppKit

/// Approved Cookie photo cutouts. Feet anchors are fractions of image size
/// (origin top-left, matching `_meta.json`).
struct Pose: Equatable {
    let id: String
    let filename: String
    let pixelSize: NSSize
    let feetAnchor: NSPoint
    let isDefaultIdle: Bool

    static let sleep = Pose(
        id: "sleep",
        filename: "cookie_sleep.png",
        pixelSize: NSSize(width: 252, height: 312),
        feetAnchor: NSPoint(x: 0.679, y: 0.978),
        isDefaultIdle: false
    )
    static let alert = Pose(
        id: "alert",
        filename: "cookie_alert.png",
        pixelSize: NSSize(width: 248, height: 310),
        feetAnchor: NSPoint(x: 0.5, y: 0.987),
        isDefaultIdle: true
    )
    static let sit = Pose(
        id: "sit",
        filename: "cookie_sit.png",
        pixelSize: NSSize(width: 209, height: 330),
        feetAnchor: NSPoint(x: 0.431, y: 0.997),
        isDefaultIdle: true
    )
    static let sitEyesClosed = Pose(
        id: "sit_eyes_closed",
        filename: "cookie_sit_eyes_closed.png",
        pixelSize: NSSize(width: 184, height: 310),
        feetAnchor: NSPoint(x: 0.418, y: 0.977),
        isDefaultIdle: false
    )
    static let loaf = Pose(
        id: "loaf",
        filename: "cookie_loaf.png",
        pixelSize: NSSize(width: 309, height: 310),
        feetAnchor: NSPoint(x: 0.573, y: 0.974),
        isDefaultIdle: false
    )
    static let suitcase = Pose(
        id: "suitcase",
        filename: "cookie_suitcase.png",
        pixelSize: NSSize(width: 303, height: 281),
        feetAnchor: NSPoint(x: 0.139, y: 0.975),
        isDefaultIdle: false
    )

    static let all: [Pose] = [sleep, alert, sit, sitEyesClosed, loaf, suitcase]
    static let defaultIdles: [Pose] = [sit, alert]

    static func randomIdle() -> Pose {
        defaultIdles.randomElement() ?? .sit
    }

    static func random(excluding current: Pose?) -> Pose {
        let pool = all.filter { $0.id != current?.id }
        return pool.randomElement() ?? .sit
    }

    /// Offset from the window's bottom-left to the feet point, in points.
    func feetOffset(displaySize: NSSize) -> NSPoint {
        NSPoint(
            x: feetAnchor.x * displaySize.width,
            y: (1 - feetAnchor.y) * displaySize.height
        )
    }

    func displaySize(scale: CGFloat = 1) -> NSSize {
        NSSize(width: pixelSize.width * scale, height: pixelSize.height * scale)
    }

    func loadImage() -> NSImage? {
        if let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".png", with: ""), withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        if let url = Bundle.main.resourceURL?.appendingPathComponent(filename) {
            return NSImage(contentsOf: url)
        }
        return NSImage(named: filename)
    }
}
