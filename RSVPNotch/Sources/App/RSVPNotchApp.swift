import SwiftUI

@main
struct RSVPNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("RSVPNotch", systemImage: "text.viewfinder") {
            MenuBarContent()
                .environmentObject(appDelegate.engine)
        }
    }
}

private struct MenuBarContent: View {
    @EnvironmentObject private var engine: RSVPEngine

    var body: some View {
        Button("Read Selected Region\u{2026}") {
            AppController.shared?.startCapture()
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])

        Divider()

        Text("Hotkey: \u{2318}\u{21E7}R")

        Divider()

        Button("Quit RSVPNotch") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
