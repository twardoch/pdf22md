import Foundation

final class AITextProcessor {

    enum Provider {
        case openAICompatible(OpenAIClient)
        case appleIntelligence
        
        var displayName: String {
            switch self {
            case .openAICompatible(let client):
                return client.model
            case .appleIntelligence:
                return "Apple Intelligence"
            }
        }
    }

    struct PageResult {
        let correctedText: String
        let improvedPreviousText: String?
    }
    
    struct PartialResult {
        let processedPages: [String]
        let unprocessedPages: [PageTextContent]
        let error: Error
    }

    private let providers: [Provider]
    private let promptTemplate: PromptTemplate
    private let maxRetries: Int
    private let retryDelaySeconds: UInt64

    init(providers: [Provider], promptTemplate: PromptTemplate = .default, maxRetries: Int = 1, retryDelaySeconds: UInt64 = 10) {
        self.providers = providers
        self.promptTemplate = promptTemplate
        self.maxRetries = maxRetries
        self.retryDelaySeconds = retryDelaySeconds
    }

    convenience init(provider: Provider, promptTemplate: PromptTemplate = .default) {
        self.init(providers: [provider], promptTemplate: promptTemplate)
    }

    convenience init(apiConfig: APIConfiguration, promptTemplate: PromptTemplate? = nil) {
        let client = OpenAIClient(config: apiConfig)
        self.init(provider: .openAICompatible(client), promptTemplate: promptTemplate ?? .default)
    }

    convenience init(apiConfigs: [APIConfiguration?], promptTemplate: PromptTemplate? = nil) {
        let providers: [Provider] = apiConfigs.map { config in
            if let config = config {
                return .openAICompatible(OpenAIClient(config: config))
            } else {
                return .appleIntelligence
            }
        }
        self.init(providers: providers, promptTemplate: promptTemplate ?? .default)
    }

    func processPageWithFallback(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int,
        fullRetryCount: Int = 0,
        providerCallback: ((String) -> Void)? = nil,
        retryCallback: ((String, Int) -> Void)? = nil
    ) async throws -> PageResult {
        let prompt = promptTemplate.buildPrompt(
            pdfText: pdfText,
            visionText: visionText,
            previousContext: previousContext,
            pageNumber: pageNumber
        )

        var lastError: Error = AIProcessingError.processingFailed("No providers available")
        
        for (providerIndex, provider) in providers.enumerated() {
            let providerName: String
            switch provider {
            case .openAICompatible(let client):
                providerName = client.model
            case .appleIntelligence:
                providerName = "Apple Intelligence"
            }
            
            for attemptWithinProvider in 0..<2 {
                do {
                    let response: String
                    switch provider {
                    case .openAICompatible(let client):
                        providerCallback?(client.model)
                        response = try await client.complete(
                            systemPrompt: promptTemplate.systemPrompt,
                            userMessage: prompt
                        )
                    case .appleIntelligence:
                        providerCallback?("Apple Intelligence")
                        throw AIProcessingError.appleIntelligenceUnavailable
                    }
                    return parseResponse(response, hasPreviousContext: previousContext != nil)
                } catch {
                    lastError = error
                    if attemptWithinProvider == 0 {
                        retryCallback?(providerName, providerIndex + 1)
                        try await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
                    }
                }
            }
        }
        
        if fullRetryCount < maxRetries {
            retryCallback?("all providers", 0)
            try await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
            return try await processPageWithFallback(
                pdfText: pdfText,
                visionText: visionText,
                previousContext: previousContext,
                pageNumber: pageNumber,
                fullRetryCount: fullRetryCount + 1,
                providerCallback: providerCallback,
                retryCallback: retryCallback
            )
        }
        
        throw lastError
    }

    func processPage(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int
    ) async throws -> PageResult {
        return try await processPageWithFallback(
            pdfText: pdfText,
            visionText: visionText,
            previousContext: previousContext,
            pageNumber: pageNumber
        )
    }

    func processPages(
        _ pages: [PageTextContent],
        progressCallback: ((Int, Int) -> Void)? = nil,
        providerCallback: ((String) -> Void)? = nil,
        retryCallback: ((String, Int) -> Void)? = nil
    ) async -> (results: [String], partial: PartialResult?) {
        var results: [String] = []
        var previousCorrected: String? = nil

        for (index, page) in pages.enumerated() {
            let pdfText = page.pdfText
            let visionText = page.visionText

            do {
                let pageResult = try await processPageWithFallback(
                    pdfText: pdfText,
                    visionText: visionText,
                    previousContext: previousCorrected,
                    pageNumber: index + 1,
                    providerCallback: providerCallback,
                    retryCallback: retryCallback
                )

                if let improvedPrev = pageResult.improvedPreviousText, !results.isEmpty {
                    results[results.count - 1] = improvedPrev
                }

                results.append(pageResult.correctedText)
                previousCorrected = pageResult.correctedText
                
                progressCallback?(index + 1, pages.count)
            } catch {
                let unprocessed = Array(pages[index...])
                let partial = PartialResult(
                    processedPages: results,
                    unprocessedPages: unprocessed,
                    error: error
                )
                return (results, partial)
            }
        }

        return (results, nil)
    }

    private func parseResponse(_ response: String, hasPreviousContext: Bool) -> PageResult {
        var correctedText = ""
        var improvedPrevious: String? = nil

        if hasPreviousContext {
            if let improvedMatch = extractTagContent(from: response, tag: "IMPROVED_PREVIOUS") {
                improvedPrevious = improvedMatch.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if let correctedMatch = extractTagContent(from: response, tag: "CORRECTED") {
            correctedText = correctedMatch.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
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

enum AIProcessingError: Error, LocalizedError {
    case invalidAPIConfiguration(String)
    case networkError(Error)
    case responseParsingError
    case appleIntelligenceUnavailable
    case contextWindowExceeded
    case guardrailViolation
    case processingFailed(String)
    case partialFailure(processed: Int, total: Int, error: Error)

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
        case .partialFailure(let processed, let total, let error):
            return "AI processing failed after \(processed)/\(total) pages: \(error.localizedDescription)"
        }
    }
}

extension AITextProcessor {
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

        if Double(visionLength) > Double(pdfLength) * threshold {
            return (vision, .vision)
        }

        if pdfLength < 50 && visionLength > 100 {
            return (vision, .vision)
        }

        return (pdfText, .pdfKit)
    }
}
