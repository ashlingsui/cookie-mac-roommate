import AppKit
import Foundation

final class SoundPlayer {
    static let shared = SoundPlayer()

    private let defaultsKey = "cookie.muted"
    private var timer: Timer?

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    func start() {
        scheduleNext()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func playIfAllowed() {
        guard !isMuted else { return }
        if let url = Bundle.main.url(forResource: "cookie_soft", withExtension: "wav"),
           let sound = NSSound(contentsOf: url, byReference: true) {
            sound.volume = 0.18
            sound.play()
            return
        }
        // Stub fallback if the wav is missing from the bundle.
        NSSound.beep()
    }

    private func scheduleNext() {
        timer?.invalidate()
        // Soft and rare: 8–20 minutes.
        let wait = TimeInterval.random(in: 8 * 60...20 * 60)
        timer = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { [weak self] _ in
            self?.playIfAllowed()
            self?.scheduleNext()
        }
        timer?.tolerance = 30
    }
}
