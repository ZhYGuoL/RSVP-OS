import AppKit
import Carbon.HIToolbox

/// AppKit keyboard routing for the notch panel. SwiftUI `@FocusState` is unreliable
/// on borderless nonactivating panels, so we handle keys here instead.
@MainActor
enum NotchKeyboard {
    static func handle(_ event: NSEvent, engine: RSVPEngine, notch: NotchViewModel) -> Bool {
        guard notch.isOpen else { return false }

        switch notch.status {
        case .reading:
            return handleReading(event, engine: engine)
        case .message, .recognizing:
            if event.keyCode == UInt16(kVK_Escape) {
                AppController.shared?.closeNotch()
                return true
            }
            return false
        case .idle, .capturing:
            return false
        }
    }

    private static func handleReading(_ event: NSEvent, engine: RSVPEngine) -> Bool {
        switch event.keyCode {
        case UInt16(kVK_Space):
            engine.togglePlay()
            return true
        case UInt16(kVK_Escape):
            AppController.shared?.closeNotch()
            return true
        case UInt16(kVK_LeftArrow):
            engine.step(by: -1)
            return true
        case UInt16(kVK_RightArrow):
            engine.step(by: 1)
            return true
        case UInt16(kVK_UpArrow):
            engine.adjustWPM(by: RSVPEngine.wpmStep)
            return true
        case UInt16(kVK_DownArrow):
            engine.adjustWPM(by: -RSVPEngine.wpmStep)
            return true
        default:
            guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return false }
            switch chars {
            case "+", "=":
                engine.adjustWPM(by: RSVPEngine.wpmStep)
                return true
            case "-":
                engine.adjustWPM(by: -RSVPEngine.wpmStep)
                return true
            default:
                return false
            }
        }
    }
}
