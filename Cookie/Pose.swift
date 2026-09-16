import AppKit

/// Persistent Cookie on-screen scale. `1` is one point per pixel of the signed PNG.
enum SpriteScale {
    static let defaultsKey = "cookie.spriteScale"
    static let small: CGFloat = 0.4
    static let medium: CGFloat = 0.5
    static let large: CGFloat = 0.75

    struct Option {
        let title: String
        let value: CGFloat
    }

    static let options: [Option] = [
        Option(title: "Small", value: small),
        Option(title: "Medium", value: medium),
        Option(title: "Large", value: large),
    ]

    /// Default on-screen size is half the PNG pixel dimensions.
    static var current: CGFloat {
        get {
            guard UserDefaults.standard.object(forKey: defaultsKey) != nil else {
                return medium
            }
            return CGFloat(UserDefaults.standard.double(forKey: defaultsKey))
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: defaultsKey)
        }
    }

    static func matches(_ value: CGFloat) -> Bool {
        abs(current - value) < 0.001
    }
}

/// Approved Cookie photo cutouts (Weixin 5-pack). Feet anchors are fractions of
/// image size (origin top-left, matching `_meta.json`). Suitcase is hide/box only.
struct Pose: Equatable {
    let id: String
    let filename: String
    let pixelSize: NSSize
    let feetAnchor: NSPoint
    let isDefaultIdle: Bool
    let isBox: Bool

    static let sitEyesClosed = Pose(
        id: "sit_eyes_closed",
        filename: "cookie_sit_eyes_closed.png",
        pixelSize: NSSize(width: 182, height: 320),
        feetAnchor: NSPoint(x: 0.525, y: 0.997),
        isDefaultIdle: true,
        isBox: false
    )
    static let loaf = Pose(
        id: "loaf",
        filename: "cookie_loaf.png",
        pixelSize: NSSize(width: 256, height: 320),
        feetAnchor: NSPoint(x: 0.752, y: 0.997),
        isDefaultIdle: false,
        isBox: false
    )
    static let sleep = Pose(
        id: "sleep",
        filename: "cookie_sleep.png",
        pixelSize: NSSize(width: 320, height: 316),
        feetAnchor: NSPoint(x: 0.522, y: 0.997),
        isDefaultIdle: false,
        isBox: false
    )
    static let alert = Pose(
        id: "alert",
        filename: "cookie_alert.png",
        pixelSize: NSSize(width: 161, height: 320),
        feetAnchor: NSPoint(x: 0.627, y: 0.997),
        isDefaultIdle: true,
        isBox: false
    )
    static let suitcase = Pose(
        id: "suitcase",
        filename: "cookie_suitcase.png",
        pixelSize: NSSize(width: 320, height: 268),
        feetAnchor: NSPoint(x: 0.383, y: 0.981),
        isDefaultIdle: false,
        isBox: true
    )

    static let all: [Pose] = [sitEyesClosed, loaf, sleep, alert, suitcase]
    /// Idle roam / click-dash pool. Suitcase is hide/box only.
    static let roamPoses: [Pose] = [sitEyesClosed, loaf, sleep, alert]
    static let defaultIdles: [Pose] = [sitEyesClosed, alert]

    static func randomIdle() -> Pose {
        defaultIdles.randomElement() ?? .sitEyesClosed
    }

    static func random(excluding current: Pose?) -> Pose {
        let pool = roamPoses.filter { $0.id != current?.id }
        return pool.randomElement() ?? .sitEyesClosed
    }

    /// Offset from the window's bottom-left to the feet point, in points.
    func feetOffset(displaySize: NSSize) -> NSPoint {
        NSPoint(
            x: feetAnchor.x * displaySize.width,
            y: (1 - feetAnchor.y) * displaySize.height
        )
    }

    func displaySize(scale: CGFloat = SpriteScale.current) -> NSSize {
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
