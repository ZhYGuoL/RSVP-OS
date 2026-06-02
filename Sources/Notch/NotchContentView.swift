import SwiftUI

/// Content shown inside the expanded notch: status messages, the RSVP word, and
/// the manual-start playback controls.
struct NotchContentView: View {
    @EnvironmentObject var engine: RSVPEngine
    @EnvironmentObject var notch: NotchViewModel
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        content
            .frame(width: NotchMetrics.openSize.width, height: NotchMetrics.openSize.height)
            .padding(.top, 16)
            .padding(.horizontal, 22)
            .padding(.bottom, NotchMetrics.openBottomInset)
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
        VStack(spacing: 10) {
            RSVPWordView(word: engine.currentWord)
                .frame(maxWidth: .infinity)
                .frame(height: 78)

            progressBar

            controlStrip
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var progressBar: some View {
        VStack(spacing: 5) {
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
            .frame(height: 4)

            HStack {
                Text("\(min(engine.index + 1, engine.words.count)) / \(engine.words.count)")
                Spacer()
                Text("\(engine.timeRemaining) left")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    /// Unified transport + speed strip, styled as one cohesive bar.
    private var controlStrip: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                stripButton("backward.end.fill", help: "Previous word") { engine.step(by: -1) }

                Button(action: { engine.togglePlay() }) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .help(engine.isPlaying ? "Pause" : "Play")

                stripButton("forward.end.fill", help: "Next word") { engine.step(by: 1) }
                stripButton("gobackward", help: "Restart") { engine.restart() }
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                stripButton("minus", help: "Slower") { engine.adjustWPM(by: -RSVPEngine.wpmStep) }

                Text("\(Int(engine.wpm)) wpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 58)

                stripButton("plus", help: "Faster") { engine.adjustWPM(by: RSVPEngine.wpmStep) }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.08), in: Capsule())

            Spacer(minLength: 8)

            stripButton("xmark", help: "Close") { AppController.shared?.closeNotch() }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func stripButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.9))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func statusView(systemImage: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressView(text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
                .tint(.accentColor)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func messageView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
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
        .padding(.horizontal, 20)
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
