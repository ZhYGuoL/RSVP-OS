import SwiftUI

private extension HorizontalAlignment {
    enum ORPCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    static let orpCenter = HorizontalAlignment(ORPCenter.self)
}

/// Renders the focused RSVP word with ORP centered, plus faded context words
/// before and after. Uses a fixed font size; overflow is clipped at the notch.
struct RSVPWordView: View {
    let word: String
    var wordsBefore: [String] = []
    var wordsAfter: [String] = []

    /// Single fixed size — no per-word scaling.
    private let fontSize: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let parts = RSVPText.splitForDisplay(word)
            let font = Font.system(size: fontSize, weight: .medium, design: .monospaced)
            let orpWidth = fontSize * 0.55

            ZStack {
                FocusMarker()

                ZStack(alignment: Alignment(horizontal: .orpCenter, vertical: .center)) {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)

                    Text(parts.orp)
                        .font(font)
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                        .alignmentGuide(.orpCenter) { $0[HorizontalAlignment.center] }

                    beforeORP(parts: parts, font: font, orpWidth: orpWidth)
                    afterORP(parts: parts, font: font, orpWidth: orpWidth)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipped()
    }

    @ViewBuilder
    private func beforeORP(
        parts: (before: String, orp: String, after: String),
        font: Font,
        orpWidth: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            if !wordsBefore.isEmpty {
                Text(wordsBefore.joined(separator: " "))
                    .foregroundStyle(contextColor)
                Text(" ")
                    .foregroundStyle(contextColor)
            }
            Text(parts.before)
                .foregroundStyle(.primary)
        }
        .font(font)
        .lineLimit(1)
        .alignmentGuide(.orpCenter) { dimensions in
            dimensions[HorizontalAlignment.trailing] + orpWidth * 0.5
        }
    }

    @ViewBuilder
    private func afterORP(
        parts: (before: String, orp: String, after: String),
        font: Font,
        orpWidth: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            Text(parts.after)
                .foregroundStyle(.primary)
            if !wordsAfter.isEmpty {
                Text(" ")
                    .foregroundStyle(contextColor)
                Text(wordsAfter.joined(separator: " "))
                    .foregroundStyle(contextColor)
            }
        }
        .font(font)
        .lineLimit(1)
        .alignmentGuide(.orpCenter) { dimensions in
            dimensions[HorizontalAlignment.leading] - orpWidth * 0.5
        }
    }

    private var contextColor: Color {
        .secondary.opacity(0.45)
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
