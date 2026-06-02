import SwiftUI

/// Drives RSVP playback: holds the word stream, current position, speed, and a
/// self-scheduling timer that advances through the words using per-word delays.
@MainActor
final class RSVPEngine: ObservableObject {
    @Published private(set) var words: [String] = []
    @Published private(set) var index: Int = 0
    @Published private(set) var isPlaying: Bool = false

    @Published var wpm: Double {
        didSet { UserDefaults.standard.set(wpm, forKey: Keys.wpm) }
    }
    @Published var pauseOnPunctuation: Bool {
        didSet { UserDefaults.standard.set(pauseOnPunctuation, forKey: Keys.pauseOnPunctuation) }
    }

    private var playTask: Task<Void, Never>?

    private enum Keys {
        static let wpm = "rsvp.wpm"
        static let pauseOnPunctuation = "rsvp.pauseOnPunctuation"
    }

    static let minWPM: Double = 100
    static let maxWPM: Double = 800
    static let wpmStep: Double = 25

    /// Words shown on each side of the focused word; extra words clip at notch edges.
    static let contextRadius = 4

    var contextWordsBefore: [String] {
        guard index > 0 else { return [] }
        let start = max(0, index - Self.contextRadius)
        return Array(words[start..<index])
    }

    var contextWordsAfter: [String] {
        guard index < words.count - 1 else { return [] }
        let end = min(words.count, index + Self.contextRadius + 1)
        return Array(words[(index + 1)..<end])
    }

    var hasContextWords: Bool {
        !contextWordsBefore.isEmpty || !contextWordsAfter.isEmpty
    }

    init() {
        let storedWPM = UserDefaults.standard.double(forKey: Keys.wpm)
        wpm = storedWPM == 0 ? 350 : storedWPM
        if UserDefaults.standard.object(forKey: Keys.pauseOnPunctuation) == nil {
            pauseOnPunctuation = true
        } else {
            pauseOnPunctuation = UserDefaults.standard.bool(forKey: Keys.pauseOnPunctuation)
        }
    }

    var currentWord: String {
        guard index >= 0, index < words.count else { return "" }
        return words[index]
    }

    var hasContent: Bool { !words.isEmpty }

    var progress: Double {
        guard words.count > 1 else { return words.isEmpty ? 0 : 1 }
        return Double(index) / Double(words.count - 1)
    }

    var remainingWords: Int { max(0, words.count - index - 1) }

    var timeRemaining: String {
        RSVPText.formatTimeRemaining(remainingWords: remainingWords, wpm: wpm)
    }

    /// Load a fresh text stream and reset to the first word, paused.
    func load(text: String) {
        stop()
        words = RSVPText.tokenize(text)
        index = 0
        isPlaying = false
    }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard hasContent else { return }
        if index >= words.count - 1 { index = 0 }
        isPlaying = true
        schedule()
    }

    func pause() {
        isPlaying = false
        playTask?.cancel()
        playTask = nil
    }

    func stop() {
        pause()
        index = 0
    }

    func restart() {
        pause()
        index = 0
    }

    func step(by delta: Int) {
        pause()
        index = min(max(0, index + delta), max(0, words.count - 1))
    }

    func seek(to fraction: Double) {
        guard words.count > 1 else { return }
        let clamped = min(max(0, fraction), 1)
        index = Int(round(clamped * Double(words.count - 1)))
    }

    func adjustWPM(by delta: Double) {
        wpm = min(max(Self.minWPM, wpm + delta), Self.maxWPM)
    }

    private func schedule() {
        playTask?.cancel()
        playTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.isPlaying {
                let word = self.currentWord
                let delayMs = RSVPText.wordDelay(
                    word,
                    wpm: self.wpm,
                    pauseOnPunctuation: self.pauseOnPunctuation
                )
                try? await Task.sleep(nanoseconds: UInt64(delayMs * 1_000_000))
                if Task.isCancelled || !self.isPlaying { return }
                if self.index >= self.words.count - 1 {
                    self.isPlaying = false
                    return
                }
                self.index += 1
            }
        }
    }
}
