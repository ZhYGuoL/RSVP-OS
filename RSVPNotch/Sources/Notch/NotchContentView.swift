import SwiftUI

/// Content shown inside the expanded notch: status messages, the RSVP word, and
/// the manual-start playback controls.
struct NotchContentView: View {
    @EnvironmentObject var engine: RSVPEngine
    @EnvironmentObject var notch: NotchViewModel
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(width: NotchMetrics.openSize.width, height: NotchMetrics.openSize.height)
        .padding(.top, 22)
        .padding(.horizontal, 30)
        .padding(.bottom, 26)
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
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RSVPWordView(word: engine.currentWord)
                .frame(maxWidth: .infinity)
                .frame(height: 90)
            Spacer(minLength: 0)
            progressBar
            controls
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.27, blue: 0.27))
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
            .frame(height: 6)

            HStack {
                Text("\(min(engine.index + 1, engine.words.count)) / \(engine.words.count)")
                Spacer()
                Text(engine.timeRemaining + " left")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 12)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            iconButton("gobackward", help: "Restart") { engine.restart() }
            iconButton("backward.end.fill", help: "Previous word") { engine.step(by: -1) }

            Button(action: { engine.togglePlay() }) {
                Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .help(engine.isPlaying ? "Pause" : "Play")

            iconButton("forward.end.fill", help: "Next word") { engine.step(by: 1) }

            Spacer()

            HStack(spacing: 8) {
                iconButton("minus", help: "Slower") { engine.adjustWPM(by: -RSVPEngine.wpmStep) }
                Text("\(Int(engine.wpm))")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 44)
                Text("wpm")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                iconButton("plus", help: "Faster") { engine.adjustWPM(by: RSVPEngine.wpmStep) }
            }

            Spacer()

            iconButton("xmark", help: "Close") { AppController.shared?.closeNotch() }
        }
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func statusView(systemImage: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.8))
            Text(text)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressView(text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text(text)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func messageView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26))
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 12) {
                Button("Open Settings") {
                    AppController.shared?.openScreenRecordingSettings()
                }
                Button("Close") {
                    AppController.shared?.closeNotch()
                }
            }
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
