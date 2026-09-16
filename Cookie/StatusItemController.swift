import AppKit

final class StatusItemController: NSObject, NSMenuDelegate {
    private let item: NSStatusItem
    private let roommate: RoommateController
    private let muteItem: NSMenuItem
    private let hideInBoxItem: NSMenuItem
    private let comeOutItem: NSMenuItem
    private var sizeItems: [NSMenuItem] = []

    init(roommate: RoommateController) {
        self.roommate = roommate
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        hideInBoxItem = NSMenuItem(title: "Hide in box", action: #selector(hideInBox), keyEquivalent: "")
        comeOutItem = NSMenuItem(title: "Come out", action: #selector(comeOut), keyEquivalent: "")
        muteItem = NSMenuItem(title: "Mute", action: #selector(toggleMute), keyEquivalent: "")
        super.init()

        item.isVisible = true
        if let button = item.button {
            // Always a readable title. Do not rely on SF Symbol "cat" (missing on some OS builds,
            // and a non-nil empty image would skip the old title fallback).
            button.title = "Cookie"
            button.toolTip = "Cookie"
            if #available(macOS 11.0, *) {
                if let paw = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Cookie") {
                    paw.isTemplate = true
                    button.image = paw
                    button.imagePosition = .imageLeading
                }
            }
        }

        muteItem.state = SoundPlayer.shared.isMuted ? .on : .off
        comeOutItem.isEnabled = false

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        hideInBoxItem.target = self
        comeOutItem.target = self
        muteItem.target = self
        let panic = NSMenuItem(title: "Panic hide", action: #selector(panicHide), keyEquivalent: "")
        panic.target = self
        let quit = NSMenuItem(title: "Quit for today", action: #selector(quitForToday), keyEquivalent: "q")
        quit.target = self

        menu.addItem(hideInBoxItem)
        menu.addItem(comeOutItem)
        menu.addItem(panic)
        menu.addItem(muteItem)
        menu.addItem(makeSizeMenuItem())
        menu.addItem(.separator())
        menu.addItem(quit)
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        hideInBoxItem.isEnabled = !roommate.isInBox
        comeOutItem.isEnabled = roommate.isInBox
    }

    private func makeSizeMenuItem() -> NSMenuItem {
        let root = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for option in SpriteScale.options {
            let item = NSMenuItem(title: option.title, action: #selector(setScale(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = Double(option.value)
            item.state = SpriteScale.matches(option.value) ? .on : .off
            submenu.addItem(item)
            sizeItems.append(item)
        }
        root.submenu = submenu
        return root
    }

    private func refreshSizeMenu() {
        for item in sizeItems {
            let value = (item.representedObject as? Double).map { CGFloat($0) }
            item.state = (value.map { SpriteScale.matches($0) } ?? false) ? .on : .off
        }
    }

    @objc private func setScale(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        roommate.setSpriteScale(CGFloat(value))
        refreshSizeMenu()
    }

    @objc private func hideInBox() {
        roommate.hideInBox()
    }

    @objc private func comeOut() {
        roommate.comeOut()
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
