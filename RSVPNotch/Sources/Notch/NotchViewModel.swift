import SwiftUI

/// Open/closed state for the drop-down notch, plus any transient status text
/// (e.g. permission prompts or OCR progress).
@MainActor
final class NotchViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case capturing
        case recognizing
        case reading
        case message(String)
    }

    @Published var isOpen: Bool = false
    @Published var status: Status = .idle
}
