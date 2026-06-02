import SwiftUI

/// Content shown inside the expanded notch: status messages, the RSVP word, and
/// the manual-start playback controls.
struct NotchContentView: View {
    @EnvironmentObject var engine: RSVPEngine
    @EnvironmentObject var notch: NotchViewModel
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, NotchMetrics.openBottomInset)
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

    private var reader: some View {
        VStack(spacing: 8) {
            RSVPWordView(word: engine.currentWord)
                .frame(maxWidth: .infinity)
                .frame(height: 68)

            progressBar

            controlStrip
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
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

            HStack {
                Text("\(min(engine.index + 1, engine.words.count)) / \(engine.words.count)")
                Spacer()
                Text("\(engine.timeRemaining) left")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    /// Compact macOS-style transport bar: one surface, grouped with dividers.
    private var controlStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                NotchIconButton("gobackward", label: "Restart") { engine.restart() }
                NotchIconButton("backward.end.fill", label: "Previous word") { engine.step(by: -1) }

                Button(action: { engine.togglePlay() }) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .help(engine.isPlaying ? "Pause" : "Play")
                .accessibilityLabel(engine.isPlaying ? "Pause" : "Play")

                NotchIconButton("forward.end.fill", label: "Next word") { engine.step(by: 1) }
            }

            Divider()
                .frame(height: 18)
                .opacity(0.35)

            HStack(spacing: 2) {
                NotchIconButton("minus", label: "Decrease speed") {
                    engine.adjustWPM(by: -RSVPEngine.wpmStep)
                }

                Text("\(Int(engine.wpm)) wpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 52)
                    .multilineTextAlignment(.center)

                NotchIconButton("plus", label: "Increase speed") {
                    engine.adjustWPM(by: RSVPEngine.wpmStep)
                }
            }

            Spacer(minLength: 0)

            NotchIconButton("xmark", label: "Close reader") {
                AppController.shared?.closeNotch()
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 10)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        .padding(.horizontal, 16)
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

/// Compact icon control with hover feedback, sized for the notch bar.
private struct NotchIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    init(_ systemName: String, label: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(isHovered ? 1 : 0.85))
                .frame(width: 26, height: 26)
                .background(isHovered ? Color.primary.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovered = $0 }
    }
}
