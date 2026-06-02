import AppKit

extension NSScreen {
    /// The Core Graphics display ID for this screen, if available.
    var displayID: CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID
    }

    /// The screen whose frame contains the given global (Cocoa) point.
    static func screen(containing point: CGPoint) -> NSScreen? {
        screens.first { $0.frame.contains(point) } ?? main
    }
}
