import Foundation
import ServiceManagement

enum LoginItem {
    static func enableOnLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Cookie: launch-at-login register failed: \(error.localizedDescription)")
        }
    }
}
