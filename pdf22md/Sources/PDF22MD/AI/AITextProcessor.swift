// this_file: pdf22md/Sources/PDF22MD/AI/AITextProcessor.swift

import Foundation

/// AI-powered text correction processor for PDF content
final class AITextProcessor {

    /// AI provider type
    enum Provider {
        case openAICompatible(OpenAIClient)
        case appleIntelligence
    }

    /// Result from processing a single page
    struct PageResult {
        let correctedText: String
        let improvedPreviousText: String?
    }

    private let provider: Provider

    init(provider: Provider) {
        self.provider = provider
    }

    /// Initialize with API configuration
    convenience init(apiConfig: APIConfiguration) {
        let client = OpenAIClient(config: apiConfig)
        self.init(provider: .openAICompatible(client))
    }

    /// Process a single page with context from the previous page
    /// - Parameters:
    ///   - pdfText: Text extracted from PDF (Fn)
    ///   - visionText: Text extracted from Vision OCR (Vn), optional
    ///   - previousContext: Corrected text from previous page (Cn-1), nil for first page
    ///   - pageNumber: 1-based page number for prompt
    /// - Returns: Corrected text and optionally improved previous page text
    func processPage(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int
    ) async throws -> PageResult {
        let prompt = buildPrompt(
            pdfText: pdfText,
            visionText: visionText,
            previousContext: previousContext,
            pageNumber: pageNumber
        )

        let response: String
        switch provider {
        case .openAICompatible(let client):
            response = try await client.complete(
                systemPrompt: systemPrompt,
                userMessage: prompt
            )
        case .appleIntelligence:
            // Apple Intelligence integration will be added in Phase 5
            throw AIProcessingError.appleIntelligenceUnavailable
        }

        return parseResponse(response, hasPreviousContext: previousContext != nil)
    }

    /// Process all pages with sliding window context
    /// - Parameter pages: Array of page text content
    /// - Returns: Array of corrected text strings
    func processPages(_ pages: [PageTextContent]) async throws -> [String] {
        var results: [String] = []
        var previousCorrected: String? = nil

        for (index, page) in pages.enumerated() {
            let pdfText = page.pdfText
            let visionText = page.visionText

            let pageResult = try await processPage(
                pdfText: pdfText,
                visionText: visionText,
                previousContext: previousCorrected,
                pageNumber: index + 1
            )

            // Update previous page if AI suggested improvements
            if let improvedPrev = pageResult.improvedPreviousText, !results.isEmpty {
                results[results.count - 1] = improvedPrev
            }

            results.append(pageResult.correctedText)
            previousCorrected = pageResult.correctedText
        }

        return results
    }

    // MARK: - Private

    private let systemPrompt = """
        You are a text correction assistant specializing in cleaning up text extracted from PDF documents.
        Your task is to produce clean, well-formatted Markdown output.

        Guidelines:
        - Fix obvious spelling and typographic errors
        - Combine broken lines into logical paragraphs
        - Identify and format headings using Markdown (# for main headings, ## for subheadings, etc.)
        - Preserve important formatting (bold, italic) using Markdown syntax
        - Move image captions, footnotes, and margin notes to the end of the page
        - Remove running headers, page numbers, and other artifacts
        - Remove garbled text, noise, and garbage characters
        - Maintain the original meaning and content
        - Do not add information that wasn't in the original text

        Output format:
        - If previous page context was provided, first output any improvements to the previous page text between <IMPROVED_PREVIOUS> and </IMPROVED_PREVIOUS> tags
        - Then output the corrected text for the current page between <CORRECTED> and </CORRECTED> tags
        """

    private func buildPrompt(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int
    ) -> String {
        var prompt = "Page \(pageNumber) of PDF document.\n\n"

        // Add previous page context if available
        if let previous = previousContext {
            prompt += """
                Previous page (for context and flow):
                ---
                \(previous)
                ---

                If the previous page text could be improved to better connect with the current page, include improvements in <IMPROVED_PREVIOUS> tags.


                """
        }

        // Add PDF text
        prompt += """
            PDF-extracted text:
            ---
            \(pdfText)
            ---

            """

        // Add Vision text if available and different
        if let vision = visionText, !vision.isEmpty {
            // Only include Vision text if it's meaningfully different
            if vision.count > pdfText.count / 2 || pdfText.count < 100 {
                prompt += """
                    OCR-extracted text (from Vision):
                    ---
                    \(vision)
                    ---

                    """
            }
        }

        prompt += """
            Please correct and format the text. Use the OCR text to fill in any gaps or fix errors in the PDF text.
            Output the corrected text in <CORRECTED></CORRECTED> tags.
            """

        return prompt
    }

    private func parseResponse(_ response: String, hasPreviousContext: Bool) -> PageResult {
        var correctedText = ""
        var improvedPrevious: String? = nil

        // Extract improved previous page if present
        if hasPreviousContext {
            if let improvedMatch = extractTagContent(from: response, tag: "IMPROVED_PREVIOUS") {
                improvedPrevious = improvedMatch.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Extract corrected text
        if let correctedMatch = extractTagContent(from: response, tag: "CORRECTED") {
            correctedText = correctedMatch.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Fallback: use the entire response if no tags found
            correctedText = response.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return PageResult(
            correctedText: correctedText,
            improvedPreviousText: improvedPrevious
        )
    }

    private func extractTagContent(from text: String, tag: String) -> String? {
        let pattern = "<\(tag)>([\\s\\S]*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let contentRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[contentRange])
    }
}

// MARK: - Errors

enum AIProcessingError: Error, LocalizedError {
    case invalidAPIConfiguration(String)
    case networkError(Error)
    case responseParsingError
    case appleIntelligenceUnavailable
    case contextWindowExceeded
    case guardrailViolation
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIConfiguration(let message):
            return "Invalid API configuration: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .responseParsingError:
            return "Failed to parse AI response"
        case .appleIntelligenceUnavailable:
            return "Apple Intelligence is not available on this system"
        case .contextWindowExceeded:
            return "Text exceeds AI context window limit"
        case .guardrailViolation:
            return "Content was blocked by AI safety guardrails"
        case .processingFailed(let message):
            return "AI processing failed: \(message)"
        }
    }
}

// MARK: - Text Selection

extension AITextProcessor {
    /// Select the best text between PDF and Vision extraction
    /// - Parameters:
    ///   - pdfText: Text from PDF parsing
    ///   - visionText: Text from Vision OCR
    ///   - threshold: Ratio threshold (default 1.5 = 50% more)
    /// - Returns: Selected text and source
    static func selectBestText(
        pdfText: String,
        visionText: String?,
        threshold: Double = 1.5
    ) -> (text: String, source: TextExtractionSource) {
        guard let vision = visionText, !vision.isEmpty else {
            return (pdfText, .pdfKit)
        }

        let pdfLength = pdfText.count
        let visionLength = vision.count

        // Use Vision if significantly more content
        if Double(visionLength) > Double(pdfLength) * threshold {
            return (vision, .vision)
        }

        // Use Vision if PDF has very little text but Vision has some
        if pdfLength < 50 && visionLength > 100 {
            return (vision, .vision)
        }

        return (pdfText, .pdfKit)
    }
}
