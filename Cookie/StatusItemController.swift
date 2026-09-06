import AppKit

final class StatusItemController {
    private let item: NSStatusItem
    private let roommate: RoommateController
    private let muteItem: NSMenuItem

    init(roommate: RoommateController) {
        self.roommate = roommate
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "cat", accessibilityDescription: "Cookie")
            }
            if button.image == nil {
                button.title = "Cookie"
            }
            button.toolTip = "Cookie"
        }

        muteItem = NSMenuItem(title: "Mute", action: #selector(toggleMute), keyEquivalent: "")
        muteItem.state = SoundPlayer.shared.isMuted ? .on : .off

        let menu = NSMenu()
        let hide = NSMenuItem(title: "Panic hide", action: #selector(panicHide), keyEquivalent: "")
        hide.target = self
        muteItem.target = self
        let quit = NSMenuItem(title: "Quit for today", action: #selector(quitForToday), keyEquivalent: "q")
        quit.target = self

        menu.addItem(hide)
        menu.addItem(muteItem)
        menu.addItem(.separator())
        menu.addItem(quit)
        item.menu = menu
    }

    @objc private func toggleMute() {
        SoundPlayer.shared.isMuted.toggle()
        muteItem.state = SoundPlayer.shared.isMuted ? .on : .off
        muteItem.title = SoundPlayer.shared.isMuted ? "Muted" : "Mute"
    }

    @objc private func panicHide() {
        roommate.panicHide()
    }

    @objc private func quitForToday() {
        NSApp.terminate(nil)
    }
}
