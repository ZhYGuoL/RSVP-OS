import CoreGraphics

/// Fixed sizing for the notch panel and its open/closed states.
enum NotchMetrics {
    /// Slim resting bar shown when idle (mimics a hardware notch).
    static let closedSize = CGSize(width: 210, height: 32)

    /// Expanded panel that hosts the RSVP reader.
    static let openSize = CGSize(width: 720, height: 280)

    /// The hosting window. Slightly larger than `openSize` to leave room for the shadow.
    static let windowSize = CGSize(width: 760, height: 330)

    /// Extra inset so controls clear the rounded bottom corners of the notch.
    static let openBottomInset: CGFloat = 20

    static let closedTopCornerRadius: CGFloat = 8
    static let closedBottomCornerRadius: CGFloat = 12
    static let openTopCornerRadius: CGFloat = 14
    static let openBottomCornerRadius: CGFloat = 28
}
