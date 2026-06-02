import AppKit

/// Presents a dimmed full-screen overlay on every display and lets the user
/// drag-select a rectangle. Reports the selection in global (Cocoa) coordinates
/// along with the screen it belongs to. Esc cancels.
@MainActor
final class RegionSelector {
    private var windows: [NSWindow] = []
    private var completion: ((CGRect, NSScreen)?) -> Void = { _ in }

    /// Begin selection. The completion is called once with a result, or `nil`
    /// if the user cancelled.
    func begin(_ completion: @escaping ((rect: CGRect, screen: NSScreen)?) -> Void) {
        teardown()

        let finish: (CGRect?, NSScreen?) -> Void = { [weak self] rect, screen in
            guard let self else { return }
            self.teardown()
            if let rect, let screen, rect.width > 4, rect.height > 4 {
                completion((rect, screen))
            } else {
                completion(nil)
            }
        }

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = false
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let view = SelectionView(screen: screen)
            view.onFinish = finish
            window.contentView = view
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeFirstResponder(windows.first?.contentView)
    }

    private func teardown() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

/// Draws the dim overlay and the live selection rectangle, and translates mouse
/// events into a global-coordinate rectangle.
private final class SelectionView: NSView {
    var onFinish: ((CGRect?, NSScreen?) -> Void)?

    private let screenRef: NSScreen
    private var startPoint: NSPoint?
    private var currentRect: NSRect = .zero

    init(screen: NSScreen) {
        self.screenRef = screen
        super.init(frame: screen.frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let p = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(start.x, p.x),
            y: min(start.y, p.y),
            width: abs(p.x - start.x),
            height: abs(p.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { startPoint = nil }
        guard currentRect.width > 0, currentRect.height > 0 else {
            onFinish?(nil, nil)
            return
        }
        // View coords (bottom-left origin) -> global Cocoa coords.
        let global = CGRect(
            x: screenRef.frame.minX + currentRect.minX,
            y: screenRef.frame.minY + currentRect.minY,
            width: currentRect.width,
            height: currentRect.height
        )
        onFinish?(global, screenRef)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            onFinish?(nil, nil)
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
        ctx.fill(bounds)

        guard currentRect.width > 0, currentRect.height > 0 else { return }

        // Punch a clear hole so the screen shows through the selection.
        ctx.setBlendMode(.clear)
        ctx.fill(currentRect)
        ctx.setBlendMode(.normal)

        ctx.setStrokeColor(NSColor.controlAccentColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(currentRect.insetBy(dx: 0.75, dy: 0.75))
    }
}
