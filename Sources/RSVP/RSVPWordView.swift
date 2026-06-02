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

/// Renders the focused RSVP word with ORP centered, plus faded context words
/// before and after (mirrors the reference web app's multi-word display).
struct RSVPWordView: View {
    let word: String
    var wordsBefore: [String] = []
    var wordsAfter: [String] = []
    var maxFontSize: CGFloat = 44
    private let minFontSize: CGFloat = 14

    private var hasContext: Bool { !wordsBefore.isEmpty || !wordsAfter.isEmpty }

    var body: some View {
        GeometryReader { geo in
            let parts = RSVPText.splitForDisplay(word)
            let cap = hasContext ? maxFontSize * 0.52 : maxFontSize
            let line = lineText(before: wordsBefore, word: word, after: wordsAfter)
            let fontSize = fittedFontSize(
                for: line,
                maxSize: cap,
                minSize: minFontSize,
                maxWidth: geo.size.width
            )
            let font = Font.system(size: fontSize, weight: .medium, design: .monospaced)
            let orpWidth = textWidth(parts.orp, size: fontSize)

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
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }

    @ViewBuilder
    private func beforeORP(parts: (before: String, orp: String, after: String), font: Font, orpWidth: CGFloat) -> some View {
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
    private func afterORP(parts: (before: String, orp: String, after: String), font: Font, orpWidth: CGFloat) -> some View {
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

    private func lineText(before: [String], word: String, after: [String]) -> String {
        var segments: [String] = []
        if !before.isEmpty { segments.append(before.joined(separator: " ")) }
        segments.append(word)
        if !after.isEmpty { segments.append(after.joined(separator: " ")) }
        return segments.joined(separator: " ")
    }

    private func fittedFontSize(
        for text: String,
        maxSize: CGFloat,
        minSize: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        guard !text.isEmpty, maxWidth > 0 else { return maxSize }
        if textWidth(text, size: maxSize) <= maxWidth { return maxSize }

        var lo = minSize
        var hi = maxSize
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if textWidth(text, size: mid) <= maxWidth {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    private func textWidth(_ text: String, size: CGFloat) -> CGFloat {
        let font = NSFont.monospacedSystemFont(ofSize: size, weight: .medium)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
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
