import AppKit
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case permissionDenied
    case noMatchingDisplay
    case emptyRegion

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen Recording permission is required. Enable it in System Settings, then try again."
        case .noMatchingDisplay:
            return "Could not find the display for the selected region."
        case .emptyRegion:
            return "The selected region was too small."
        }
    }
}

/// Captures a screenshot of a global-coordinate rectangle using ScreenCaptureKit.
enum ScreenCapture {
    static func capture(globalRect: CGRect, on screen: NSScreen) async throws -> CGImage {
        guard globalRect.width >= 1, globalRect.height >= 1 else {
            throw CaptureError.emptyRegion
        }

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
        } catch {
            throw CaptureError.permissionDenied
        }

        guard
            let displayID = screen.displayID,
            let scDisplay = content.displays.first(where: { $0.displayID == displayID })
        else {
            throw CaptureError.noMatchingDisplay
        }

        // Global Cocoa rect (bottom-left origin) -> display-local, top-left origin (points).
        let local = CGRect(
            x: globalRect.minX - screen.frame.minX,
            y: screen.frame.maxY - globalRect.maxY,
            width: globalRect.width,
            height: globalRect.height
        )

        let scale = screen.backingScaleFactor
        let config = SCStreamConfiguration()
        config.sourceRect = local
        config.width = max(1, Int(local.width * scale))
        config.height = max(1, Int(local.height * scale))
        config.scalesToFit = false
        config.showsCursor = false
        config.captureResolution = .best

        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }
}
