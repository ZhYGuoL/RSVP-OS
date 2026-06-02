import AppKit
import SwiftUI
import Carbon.HIToolbox

/// Orchestrates the full pipeline: global hotkey -> region selection -> capture
/// -> OCR -> RSVP playback in the drop-down notch. Owns the notch panel and the
/// shared engine / notch view-model.
@MainActor
final class AppController {
    static var shared: AppController?

    let engine = RSVPEngine()
    let notchVM = NotchViewModel()

    private let selector = RegionSelector()
    private var hotkey: GlobalHotkey?
    private var panel: NotchPanel?
    private var pipelineTask: Task<Void, Never>?
    private var closeTask: Task<Void, Never>?
    private var keyMonitor: Any?

    init() {
        AppController.shared = self
    }

    /// Called once the app has finished launching.
    func setup() {
        NSApp.setActivationPolicy(.accessory)
        hotkey = GlobalHotkey(
            keyCode: UInt32(kVK_ANSI_R),
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [weak self] in
            self?.startCapture()
        }
    }

    // MARK: - Pipeline

    func startCapture() {
        pipelineTask?.cancel()
        closeTask?.cancel()
        closeNotchImmediately()

        selector.begin { [weak self] result in
            guard let self else { return }
            guard let result else { return } // cancelled
            self.runPipeline(rect: result.rect, screen: result.screen)
        }
    }

    private func runPipeline(rect: CGRect, screen: NSScreen) {
        openNotch(on: screen)
        notchVM.status = .recognizing

        pipelineTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ScreenCapture.capture(globalRect: rect, on: screen)
                if Task.isCancelled { return }
                let text = try await TextRecognizer.recognize(image)
                if Task.isCancelled { return }

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.notchVM.status = .message("No readable text found in that region.")
                    return
                }
                self.engine.load(text: trimmed)
                self.notchVM.status = .reading
                self.focusNotchPanel()
            } catch {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? "Something went wrong while reading the screen."
                self.notchVM.status = .message(message)
            }
        }
    }

    // MARK: - Notch window

    func closeNotch() {
        pipelineTask?.cancel()
        engine.stop()
        notchVM.isOpen = false
        notchVM.status = .idle
        removeKeyMonitor()

        closeTask?.cancel()
        closeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.panel?.orderOut(nil)
        }
    }

    /// Brings the notch panel to the front and makes it the key window so keyboard
    /// shortcuts work without clicking a control first.
    func focusNotchPanel() {
        guard let panel else { return }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        if let view = panel.contentView, view.acceptsFirstResponder {
            panel.makeFirstResponder(view)
        }
    }

    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openNotch(on screen: NSScreen) {
        closeTask?.cancel()
        let panel = ensurePanel()
        position(panel, on: screen)
        installKeyMonitor()
        notchVM.isOpen = false
        focusNotchPanel()
        // Defer opening one runloop tick so the spring animates the drop-down.
        DispatchQueue.main.async { [weak self] in
            self?.notchVM.isOpen = true
            self?.focusNotchPanel()
        }
    }

    private func closeNotchImmediately() {
        notchVM.isOpen = false
        notchVM.status = .idle
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.notchVM.isOpen, self.panel?.isVisible == true else { return event }
            guard self.panel?.isKeyWindow == true || NSApp.isActive else { return event }
            if NotchKeyboard.handle(event, engine: self.engine, notch: self.notchVM) {
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func ensurePanel() -> NotchPanel {
        if let panel { return panel }
        let rect = NSRect(
            x: 0, y: 0,
            width: NotchMetrics.windowSize.width,
            height: NotchMetrics.windowSize.height
        )
        let panel = NotchPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let root = AnyView(
            NotchView()
                .environmentObject(engine)
                .environmentObject(notchVM)
        )
        panel.contentView = NotchHostingView(rootView: root)
        self.panel = panel
        return panel
    }

    private func position(_ panel: NotchPanel, on screen: NSScreen) {
        let frame = screen.frame
        let origin = NSPoint(
            x: frame.midX - NotchMetrics.windowSize.width / 2,
            y: frame.maxY - NotchMetrics.windowSize.height
        )
        panel.setFrameOrigin(origin)
    }
}
