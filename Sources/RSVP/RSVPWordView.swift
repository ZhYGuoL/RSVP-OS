import SwiftUI

private extension HorizontalAlignment {
    enum ORPCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    /// Alignment that pins the focus letter to a fixed horizontal position.
    static let orpCenter = HorizontalAlignment(ORPCenter.self)
}

private let focusColor = Color(red: 1.0, green: 0.27, blue: 0.27)

/// Renders a single RSVP word with the Optimal Recognition Point letter held at
/// the horizontal center and tinted red, flanked by red focus markers.
/// Mirrors the reference `RSVPDisplay.svelte`.
struct RSVPWordView: View {
    let word: String
    var fontSize: CGFloat = 54

    var body: some View {
        let parts = RSVPText.splitForDisplay(word)
        let font = Font.system(size: fontSize, weight: .medium, design: .monospaced)

        ZStack {
            FocusMarker()

            ZStack(alignment: Alignment(horizontal: .orpCenter, vertical: .center)) {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)

                HStack(spacing: 0) {
                    Text(parts.before)
                        .foregroundStyle(.white)
                    Text(parts.orp)
                        .foregroundStyle(focusColor)
                        .fontWeight(.bold)
                        .shadow(color: focusColor.opacity(0.6), radius: 14)
                        .alignmentGuide(.orpCenter) { $0[HorizontalAlignment.center] }
                    Text(parts.after)
                        .foregroundStyle(.white)
                }
                .font(font)
                .lineLimit(1)
                .fixedSize()
            }
        }
    }
}

/// Thin vertical red ticks above and below the focus letter.
private struct FocusMarker: View {
    var body: some View {
        GeometryReader { geo in
            let tick: CGFloat = 22
            ZStack {
                LinearGradient(
                    colors: [focusColor, .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: 2, height: tick)
                .position(x: geo.size.width / 2, y: tick / 2)

                LinearGradient(
                    colors: [.clear, focusColor],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: 2, height: tick)
                .position(x: geo.size.width / 2, y: geo.size.height - tick / 2)
            }
        }
        .allowsHitTesting(false)
    }
}
