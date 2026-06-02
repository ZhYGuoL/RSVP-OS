import AppKit
import SwiftUI

/// Hosting view that accepts first responder so the notch panel receives key events
/// immediately, without requiring a click on a control first.
final class NotchHostingView: NSHostingView<AnyView> {
    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if handle(event) { return }
        super.keyDown(with: event)
    }

    private func handle(_ event: NSEvent) -> Bool {
        guard let controller = AppController.shared else { return false }
        return NotchKeyboard.handle(event, engine: controller.engine, notch: controller.notchVM)
    }
}
