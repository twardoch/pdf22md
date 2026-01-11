// this_file: pdf22md/Sources/PDF22MD/Vision/VisionTextExtractor.swift

import Foundation
import Vision
import AppKit
import PDFKit

/// Result from Vision text recognition containing text, confidence, and position
struct VisionTextResult {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

/// Errors that can occur during Vision text extraction
enum VisionExtractionError: Error, LocalizedError {
    case imageRenderingFailed
    case textRecognitionFailed(Error)
    case noTextFound
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .imageRenderingFailed:
            return "Failed to render PDF page to image"
        case .textRecognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text found in image"
        case .invalidImage:
            return "Invalid image data"
        }
    }
}

/// Extracts text from images using Apple Vision Framework OCR
final class VisionTextExtractor {

    /// Configuration for text recognition
    struct Configuration {
        var languages: [String] = ["en"]
        var useFastRecognition: Bool = false
        var usesLanguageCorrection: Bool = true
        var minimumConfidence: Float = 0.0
        var customWords: [String] = []

        static let `default` = Configuration()
        static let fast = Configuration(useFastRecognition: true)
    }

    private let configuration: Configuration

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    /// Extract text from a CGImage using Vision Framework
    /// - Parameters:
    ///   - cgImage: The image to extract text from
    ///   - imageSize: Original image size for coordinate conversion
    /// - Returns: Array of recognized text results with positions and confidence
    func extractText(from cgImage: CGImage, imageSize: CGSize? = nil) async throws -> [VisionTextResult] {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let size = imageSize ?? CGSize(width: width, height: height)

        return try await withCheckedThrowingContinuation { continuation in
            var results: [VisionTextResult] = []

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionExtractionError.textRecognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }

                    // Filter by minimum confidence
                    if observation.confidence < self.configuration.minimumConfidence {
                        continue
                    }

                    let text = topCandidate.string
                    let rect = observation.boundingBox

                    // Convert normalized coordinates to image coordinates
                    // Vision uses bottom-left origin, convert to top-left
                    let x = rect.origin.x * size.width
                    let y = (1 - rect.origin.y - rect.size.height) * size.height
                    let boundingBox = CGRect(
                        x: x,
                        y: y,
                        width: rect.size.width * size.width,
                        height: rect.size.height * size.height
                    )

                    let result = VisionTextResult(
                        text: text,
                        confidence: observation.confidence,
                        boundingBox: boundingBox
                    )
                    results.append(result)
                }

                continuation.resume(returning: results)
            }

            // Configure recognition
            request.recognitionLevel = configuration.useFastRecognition ? .fast : .accurate
            request.recognitionLanguages = configuration.languages
            request.usesLanguageCorrection = configuration.usesLanguageCorrection

            if !configuration.customWords.isEmpty {
                request.customWords = configuration.customWords
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionExtractionError.textRecognitionFailed(error))
            }
        }
    }

    /// Extract text from a PDF page by rendering it to an image first
    /// - Parameters:
    ///   - pdfPage: The PDF page to extract text from
    ///   - dpi: Resolution for rendering (default 144 dpi)
    /// - Returns: Array of recognized text results
    func extractText(from pdfPage: PDFPage, dpi: CGFloat = 144) async throws -> [VisionTextResult] {
        guard let cgImage = renderPageToImage(pdfPage, dpi: dpi) else {
            throw VisionExtractionError.imageRenderingFailed
        }

        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let scaledSize = CGSize(
            width: pageRect.size.width * scale,
            height: pageRect.size.height * scale
        )

        return try await extractText(from: cgImage, imageSize: scaledSize)
    }

    /// Render a PDF page to a CGImage at the specified DPI
    /// - Parameters:
    ///   - pdfPage: The PDF page to render
    ///   - dpi: Resolution (default 144)
    /// - Returns: Rendered CGImage or nil if rendering fails
    func renderPageToImage(_ pdfPage: PDFPage, dpi: CGFloat = 144) -> CGImage? {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scale = dpi / 72.0

        let width = Int(pageRect.size.width * scale)
        let height = Int(pageRect.size.height * scale)

        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        // Fill with white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Scale and draw the PDF page
        context.scaleBy(x: scale, y: scale)
        pdfPage.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    /// Extract text as a single concatenated string, sorted by reading order (top-to-bottom, left-to-right)
    /// - Parameters:
    ///   - cgImage: The image to extract text from
    ///   - lineSeparator: Separator between lines (default newline)
    /// - Returns: Concatenated text string
    func extractTextAsString(from cgImage: CGImage, lineSeparator: String = "\n") async throws -> String {
        let results = try await extractText(from: cgImage)
        return combineResults(results, lineSeparator: lineSeparator)
    }

    /// Extract text from PDF page as a single concatenated string
    /// - Parameters:
    ///   - pdfPage: The PDF page to extract text from
    ///   - dpi: Resolution for rendering
    ///   - lineSeparator: Separator between lines
    /// - Returns: Concatenated text string
    func extractTextAsString(from pdfPage: PDFPage, dpi: CGFloat = 144, lineSeparator: String = "\n") async throws -> String {
        let results = try await extractText(from: pdfPage, dpi: dpi)
        return combineResults(results, lineSeparator: lineSeparator)
    }

    /// Combine text results into a single string, sorted by reading order
    private func combineResults(_ results: [VisionTextResult], lineSeparator: String) -> String {
        // Sort by Y position (top to bottom), then X position (left to right)
        let sorted = results.sorted { lhs, rhs in
            // Group lines within a tolerance (10 points)
            let yTolerance: CGFloat = 10
            if abs(lhs.boundingBox.origin.y - rhs.boundingBox.origin.y) < yTolerance {
                return lhs.boundingBox.origin.x < rhs.boundingBox.origin.x
            }
            return lhs.boundingBox.origin.y < rhs.boundingBox.origin.y
        }

        return sorted.map { $0.text }.joined(separator: lineSeparator)
    }
}

// MARK: - Static convenience methods

extension VisionTextExtractor {

    /// Static method for quick text extraction from CGImage
    static func extractText(
        from cgImage: CGImage,
        languages: [String] = ["en"],
        useFastRecognition: Bool = false
    ) async throws -> [VisionTextResult] {
        let config = Configuration(
            languages: languages,
            useFastRecognition: useFastRecognition
        )
        let extractor = VisionTextExtractor(configuration: config)
        return try await extractor.extractText(from: cgImage)
    }

    /// Static method for quick text extraction from PDF page
    static func extractText(
        from pdfPage: PDFPage,
        dpi: CGFloat = 144,
        languages: [String] = ["en"],
        useFastRecognition: Bool = false
    ) async throws -> [VisionTextResult] {
        let config = Configuration(
            languages: languages,
            useFastRecognition: useFastRecognition
        )
        let extractor = VisionTextExtractor(configuration: config)
        return try await extractor.extractText(from: pdfPage, dpi: dpi)
    }

    /// Static method for quick text extraction as string from PDF page
    static func extractTextAsString(
        from pdfPage: PDFPage,
        dpi: CGFloat = 144,
        languages: [String] = ["en"],
        useFastRecognition: Bool = false
    ) async throws -> String {
        let config = Configuration(
            languages: languages,
            useFastRecognition: useFastRecognition
        )
        let extractor = VisionTextExtractor(configuration: config)
        return try await extractor.extractTextAsString(from: pdfPage, dpi: dpi)
    }
}
