import CoreGraphics

/// Fixed sizing for the notch panel and its open/closed states.
enum NotchMetrics {
    /// Slim resting bar shown when idle (mimics a hardware notch).
    static let closedSize = CGSize(width: 210, height: 32)

    /// Expanded panel that hosts the RSVP reader.
    static let openSize = CGSize(width: 720, height: 250)

    /// The hosting window. Slightly larger than `openSize` to leave room for the shadow.
    static let windowSize = CGSize(width: 760, height: 300)

    /// Inset from the bottom edge to the control row.
    static let bottomInset: CGFloat = 24

    /// Horizontal inset — tuned to visually match bottom clearance against the
    /// notch's rounded lower corners (bottomInset + ~75% of corner radius).
    static let sideInset: CGFloat = bottomInset + openBottomCornerRadius * 0.75

    static let closedTopCornerRadius: CGFloat = 8
    static let closedBottomCornerRadius: CGFloat = 12
    static let openTopCornerRadius: CGFloat = 14
    static let openBottomCornerRadius: CGFloat = 28

    /// Width available for reader content after horizontal insets.
    static var contentWidth: CGFloat {
        openSize.width - sideInset * 2
    }
}
