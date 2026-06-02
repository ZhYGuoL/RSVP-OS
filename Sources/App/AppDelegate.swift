import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    var engine: RSVPEngine { controller.engine }

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.setup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
