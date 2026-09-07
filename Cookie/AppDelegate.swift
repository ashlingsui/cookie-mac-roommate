import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var roommate: RoommateController?
    private var status: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LoginItem.enableOnLogin()

        let roommate = RoommateController()
        self.roommate = roommate
        status = StatusItemController(roommate: roommate)
        roommate.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
