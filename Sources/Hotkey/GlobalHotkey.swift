import AppKit
import Carbon.HIToolbox

/// Minimal Carbon-based global hotkey. No third-party dependencies.
final class GlobalHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private let identifier: UInt32
    private let callback: () -> Void

    private static var registry: [UInt32: GlobalHotkey] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false
    private static let signature: OSType = 0x5253_5650 // 'RSVP'

    /// - Parameters:
    ///   - keyCode: a `kVK_*` virtual key code.
    ///   - modifiers: Carbon modifier mask (e.g. `cmdKey | shiftKey`).
    @discardableResult
    init?(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        self.callback = callback
        self.identifier = GlobalHotkey.nextID
        GlobalHotkey.nextID += 1

        GlobalHotkey.installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: GlobalHotkey.signature, id: identifier)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else { return nil }
        GlobalHotkey.registry[identifier] = self
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        GlobalHotkey.registry[identifier] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if status == noErr, let target = GlobalHotkey.registry[hotKeyID.id] {
                    DispatchQueue.main.async { target.callback() }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
}
