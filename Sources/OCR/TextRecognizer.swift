import Vision
import CoreGraphics

/// Local on-device OCR via the Vision framework. No network, no third-party deps.
enum TextRecognizer {
    static func recognize(_ image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                    let text = assemble(observations)
                    continuation.resume(returning: text)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Sort observations into reading order (top-to-bottom, then left-to-right)
    /// and join them into a single string.
    private static func assemble(_ observations: [VNRecognizedTextObservation]) -> String {
        let lineTolerance = 0.012
        let sorted = observations.sorted { a, b in
            // Vision uses a bottom-left normalized coordinate space.
            if abs(a.boundingBox.midY - b.boundingBox.midY) > lineTolerance {
                return a.boundingBox.midY > b.boundingBox.midY
            }
            return a.boundingBox.minX < b.boundingBox.minX
        }
        return sorted
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
    }
}
