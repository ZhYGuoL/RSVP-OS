import AppKit
import SwiftUI

private extension HorizontalAlignment {
    enum ORPCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    static let orpCenter = HorizontalAlignment(ORPCenter.self)
}

/// Renders a single RSVP word with the Optimal Recognition Point letter held at
/// the horizontal center and tinted with the system accent color.
struct RSVPWordView: View {
    let word: String
    var maxFontSize: CGFloat = 44
    private let minFontSize: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let parts = RSVPText.splitForDisplay(word)
            let fontSize = fittedFontSize(
                for: word,
                maxSize: maxFontSize,
                minSize: minFontSize,
                maxWidth: geo.size.width
            )
            let font = Font.system(size: fontSize, weight: .medium, design: .monospaced)

            ZStack {
                FocusMarker()

                ZStack(alignment: Alignment(horizontal: .orpCenter, vertical: .center)) {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)

                    HStack(spacing: 0) {
                        Text(parts.before)
                            .foregroundStyle(.primary)
                        Text(parts.orp)
                            .foregroundStyle(.tint)
                            .fontWeight(.semibold)
                            .alignmentGuide(.orpCenter) { $0[HorizontalAlignment.center] }
                        Text(parts.after)
                            .foregroundStyle(.primary)
                    }
                    .font(font)
                    .lineLimit(1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }

    /// Shrink the font until the full word fits within the available width.
    private func fittedFontSize(
        for word: String,
        maxSize: CGFloat,
        minSize: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        guard !word.isEmpty, maxWidth > 0 else { return maxSize }
        if wordWidth(word, size: maxSize) <= maxWidth { return maxSize }

        var lo = minSize
        var hi = maxSize
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if wordWidth(word, size: mid) <= maxWidth {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    private func wordWidth(_ word: String, size: CGFloat) -> CGFloat {
        let font = NSFont.monospacedSystemFont(ofSize: size, weight: .medium)
        return ceil((word as NSString).size(withAttributes: [.font: font]).width)
    }
}

/// Thin vertical accent ticks above and below the focus letter.
private struct FocusMarker: View {
    var body: some View {
        GeometryReader { geo in
            let tick: CGFloat = 14
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor, .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: 1.5, height: tick)
                .position(x: geo.size.width / 2, y: tick / 2)

                LinearGradient(
                    colors: [.clear, Color.accentColor],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: 1.5, height: tick)
                .position(x: geo.size.width / 2, y: geo.size.height - tick / 2)
            }
        }
        .allowsHitTesting(false)
    }
}
