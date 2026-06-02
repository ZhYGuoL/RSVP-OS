import Foundation

/// Swift port of the RSVP text utilities from the reference web app
/// (`rsvp-reading/src/lib/rsvp-utils.js`): tokenization, Optimal Recognition
/// Point (ORP) calculation, per-word display timing, and word splitting.
enum RSVPText {

    /// Split raw text into displayable words on any whitespace run.
    static func tokenize(_ text: String) -> [String] {
        text
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// Index (counting only letters) of the letter the eye should focus on.
    static func orpIndex(_ word: String) -> Int {
        let letterCount = word.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        if letterCount <= 1 { return 0 }
        if letterCount <= 3 { return 0 }
        if letterCount <= 5 { return 1 }
        if letterCount <= 9 { return 2 }
        if letterCount <= 12 { return 3 }
        return Int(floor(log2(Double(letterCount - 1)))) + 1
    }

    /// Actual character index of the ORP letter, skipping leading punctuation.
    static func actualORPIndex(_ word: String) -> Int {
        guard !word.isEmpty else { return 0 }
        let target = orpIndex(word)
        var letterCount = 0
        let chars = Array(word)
        for (i, ch) in chars.enumerated() {
            if ch.isLetter {
                if letterCount == target { return i }
                letterCount += 1
            }
        }
        return min(target, chars.count - 1)
    }

    /// The three render segments: text before the focus letter, the focus
    /// letter itself, and text after it.
    static func splitForDisplay(_ word: String) -> (before: String, orp: String, after: String) {
        guard !word.isEmpty else { return ("", "", "") }
        let chars = Array(word)
        let idx = actualORPIndex(word)
        let before = String(chars[0..<idx])
        let orp = String(chars[idx])
        let after = idx + 1 < chars.count ? String(chars[(idx + 1)...]) : ""
        return (before, orp, after)
    }

    /// Milliseconds to display a word, factoring in WPM, word length, and
    /// punctuation pauses. Mirrors `getWordDelay` from the reference app.
    static func wordDelay(
        _ word: String,
        wpm: Double,
        pauseOnPunctuation: Bool = true,
        punctuationMultiplier: Double = 2.0,
        wordLengthMultiplier: Double = 0.0
    ) -> Double {
        guard wpm > 0 else { return 200 }
        var base = 60_000.0 / wpm

        if wordLengthMultiplier > 0, word.count >= 12 {
            base *= 1 + (wordLengthMultiplier / 100.0) * Double(word.count - 12)
        }

        if pauseOnPunctuation, let last = word.last {
            if ".!?;:".contains(last) {
                return base * punctuationMultiplier
            }
            if last == "," {
                return base * 1.5
            }
        }
        return base
    }

    /// Format remaining reading time as M:SS.
    static func formatTimeRemaining(remainingWords: Int, wpm: Double) -> String {
        guard remainingWords > 0, wpm > 0 else { return "0:00" }
        let seconds = Int(ceil(Double(remainingWords) / wpm * 60.0))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
