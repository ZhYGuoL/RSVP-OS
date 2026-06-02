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
    var fontSize: CGFloat = 44

    var body: some View {
        let parts = RSVPText.splitForDisplay(word)
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
                .fixedSize()
            }
        }
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
