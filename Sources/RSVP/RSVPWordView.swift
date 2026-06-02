import SwiftUI

/// Renders the focused RSVP word with ORP centered, plus faded context words
/// before and after. Uses a fixed font size; overflow is clipped at the notch.
///
/// Layout mirrors the reference web app: the ORP letter is pinned to the
/// horizontal center; before/after text grow outward and clip at the notch edges.
struct RSVPWordView: View {
    let word: String
    var wordsBefore: [String] = []
    var wordsAfter: [String] = []

    /// Single fixed size — no per-word scaling.
    private let fontSize: CGFloat = 36

    /// Half a monospaced character width (~0.5ch in the reference CSS).
    private var halfChar: CGFloat { fontSize * 0.3 }

    var body: some View {
        GeometryReader { geo in
            let parts = RSVPText.splitForDisplay(word)
            let font = Font.system(size: fontSize, weight: .medium, design: .monospaced)
            let sideWidth = max(0, geo.size.width / 2 - halfChar)

            ZStack {
                FocusMarker()

                HStack(spacing: 0) {
                    // Left pane: before text grows left from center − 0.5ch.
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        beforeContent(parts: parts, font: font)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(width: sideWidth, alignment: .trailing)
                    .clipped()

                    // Gap reserved for the ORP letter at the exact center.
                    Color.clear.frame(width: halfChar * 2)

                    // Right pane: after text grows right from center + 0.5ch.
                    HStack(spacing: 0) {
                        afterContent(parts: parts, font: font)
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 0)
                    }
                    .frame(width: sideWidth, alignment: .leading)
                    .clipped()
                }

                // ORP always at the exact horizontal center.
                Text(parts.orp)
                    .font(font)
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipped()
    }

    @ViewBuilder
    private func beforeContent(
        parts: (before: String, orp: String, after: String),
        font: Font
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
    }

    @ViewBuilder
    private func afterContent(
        parts: (before: String, orp: String, after: String),
        font: Font
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
