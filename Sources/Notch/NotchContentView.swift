import SwiftUI

/// Content shown inside the expanded notch: status messages, the RSVP word, and
/// the manual-start playback controls.
struct NotchContentView: View {
    @EnvironmentObject var engine: RSVPEngine
    @EnvironmentObject var notch: NotchViewModel
    @FocusState private var keyboardFocused: Bool

    private let inset = NotchMetrics.contentInset

    var body: some View {
        content
            .padding(.horizontal, inset)
            .padding(.top, inset * 0.5)
            .padding(.bottom, inset)
            .frame(width: NotchMetrics.openSize.width, height: NotchMetrics.openSize.height, alignment: .top)
            .clipped()
            .focusable()
            .focused($keyboardFocused)
            .focusEffectDisabled()
            .onKeyPress { press in handleKey(press) }
            .onAppear { keyboardFocused = true }
    }

    @ViewBuilder
    private var content: some View {
        switch notch.status {
        case .capturing:
            statusView(systemImage: "viewfinder", text: "Select a region\u{2026}")
        case .recognizing:
            progressView(text: "Reading text\u{2026}")
        case .message(let message):
            messageView(message)
        case .idle, .reading:
            reader
        }
    }

    /// Word fills the upper area; progress and controls are pinned to the bottom.
    private var reader: some View {
        VStack(spacing: 0) {
            RSVPWordView(word: engine.currentWord)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
    }

    private var bottomBar: some View {
        VStack(spacing: inset * 0.5) {
            progressBar
            controlStrip
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            compactProgressTrack
                .frame(width: 160)
                .frame(maxWidth: .infinity)

            HStack {
                Text("\(min(engine.index + 1, engine.words.count)) of \(engine.words.count)")
                Spacer()
                Text(engine.timeRemaining)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }

    /// Short centered pill — not edge-to-edge.
    private var compactProgressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.14))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, geo.size.width * engine.progress))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        engine.seek(to: value.location.x / geo.size.width)
                    }
            )
        }
        .frame(height: 3)
    }

    /// Transport left, close right, WPM truly centered via overlay.
    private var controlStrip: some View {
        ZStack {
            HStack(spacing: 6) {
                NotchControlButton("minus", label: "Slower", size: 11) {
                    engine.adjustWPM(by: -RSVPEngine.wpmStep)
                }

                Text("\(Int(engine.wpm)) wpm")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.85))
                    .monospacedDigit()
                    .frame(minWidth: 64)

                NotchControlButton("plus", label: "Faster", size: 11) {
                    engine.adjustWPM(by: RSVPEngine.wpmStep)
                }
            }

            HStack {
                HStack(spacing: 18) {
                    NotchControlButton("backward.fill", label: "Previous word") {
                        engine.step(by: -1)
                    }

                    Button(action: { engine.togglePlay() }) {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help(engine.isPlaying ? "Pause" : "Play")
                    .accessibilityLabel(engine.isPlaying ? "Pause" : "Play")

                    NotchControlButton("forward.fill", label: "Next word") {
                        engine.step(by: 1)
                    }
                }

                Spacer(minLength: 0)

                NotchControlButton("xmark", label: "Close", size: 11, emphasis: .subtle) {
                    AppController.shared?.closeNotch()
                }
            }
        }
        .frame(height: 22)
    }

    private func statusView(systemImage: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressView(text: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func messageView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Open Settings") {
                    AppController.shared?.openScreenRecordingSettings()
                }
                .buttonStyle(.bordered)
                Button("Close") {
                    AppController.shared?.closeNotch()
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .space:
            engine.togglePlay()
            return .handled
        case .escape:
            AppController.shared?.closeNotch()
            return .handled
        case .leftArrow:
            engine.step(by: -1)
            return .handled
        case .rightArrow:
            engine.step(by: 1)
            return .handled
        case .upArrow:
            engine.adjustWPM(by: RSVPEngine.wpmStep)
            return .handled
        case .downArrow:
            engine.adjustWPM(by: -RSVPEngine.wpmStep)
            return .handled
        default:
            if press.characters == "+" || press.characters == "=" {
                engine.adjustWPM(by: RSVPEngine.wpmStep)
                return .handled
            }
            if press.characters == "-" {
                engine.adjustWPM(by: -RSVPEngine.wpmStep)
                return .handled
            }
            return .ignored
        }
    }
}

/// Minimal icon button — no background chrome, subtle hover only.
private struct NotchControlButton: View {
    enum Emphasis {
        case normal
        case subtle
    }

    let systemName: String
    let label: String
    var size: CGFloat = 13
    var emphasis: Emphasis = .normal
    let action: () -> Void

    @State private var isHovered = false

    init(
        _ systemName: String,
        label: String,
        size: CGFloat = 13,
        emphasis: Emphasis = .normal,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.label = label
        self.size = size
        self.emphasis = emphasis
        self.action = action
    }

    private var baseOpacity: Double {
        switch emphasis {
        case .normal: 0.88
        case .subtle: 0.72
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.primary.opacity(isHovered ? 1 : baseOpacity))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovered = $0 }
    }
}
