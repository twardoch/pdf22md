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
    private let promptTemplateV2: PromptTemplateV2
    private let maxRetries: Int
    private let retryDelaySeconds: UInt64
    private let verbose: Bool
    private var systemPromptLogged: Bool = false
    private let tokenBudget: TokenBudget

    init(providers: [Provider], promptTemplate: PromptTemplate = .default, maxRetries: Int = 1, retryDelaySeconds: UInt64 = 10, verbose: Bool = false, tokenBudget: TokenBudget? = nil) {
        self.providers = providers
        self.promptTemplate = promptTemplate
        self.promptTemplateV2 = .default
        self.maxRetries = maxRetries
        self.retryDelaySeconds = retryDelaySeconds
        self.verbose = verbose
        
        if let budget = tokenBudget {
            self.tokenBudget = budget
        } else {
            let hasAppleIntelligence = providers.contains { 
                if case .appleIntelligence = $0 { return true }
                return false
            }
            self.tokenBudget = hasAppleIntelligence ? .appleIntelligence : .openAIDefault
        }
    }

    convenience init(provider: Provider, promptTemplate: PromptTemplate = .default, verbose: Bool = false) {
        self.init(providers: [provider], promptTemplate: promptTemplate, verbose: verbose)
    }

    convenience init(apiConfig: APIConfiguration, promptTemplate: PromptTemplate? = nil, verbose: Bool = false) {
        let client = OpenAIClient(config: apiConfig)
        self.init(provider: .openAICompatible(client), promptTemplate: promptTemplate ?? .default, verbose: verbose)
    }

    convenience init(apiConfigs: [APIConfiguration?], promptTemplate: PromptTemplate? = nil, verbose: Bool = false) {
        let providers: [Provider] = apiConfigs.map { config in
            if let config = config {
                return .openAICompatible(OpenAIClient(config: config))
            } else {
                return .appleIntelligence
            }
        }
        self.init(providers: providers, promptTemplate: promptTemplate ?? .default, verbose: verbose)
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
                    if verbose {
                        let sysPrompt = systemPromptLogged ? nil : promptTemplate.systemPrompt
                        AILogger.log(AILogger.formatAIInput(prompt, systemPrompt: sysPrompt, chunkInfo: nil), verbose: true)
                        systemPromptLogged = true
                    }
                    
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
                        guard AppleIntelligenceProcessor.isAvailable else {
                            throw AIProcessingError.appleIntelligenceUnavailable
                        }
                        let processor = AppleIntelligenceProcessor(systemPrompt: promptTemplate.systemPrompt, verbose: verbose)
                        response = try await processor.processPage(prompt, pageNumber: pageNumber)
                    }
                    
                    if verbose {
                        AILogger.log(AILogger.formatAIOutput(response), verbose: true)
                    }
                    
                    return parseResponse(response, hasPreviousContext: previousContext != nil)
                } catch {
                    lastError = error
                    
                    // Don't retry context window errors - they're deterministic failures
                    // (chunking is already attempted in AppleIntelligenceProcessor)
                    if case AIProcessingError.contextWindowExceeded = error {
                        break
                    }
                    
                    // Don't retry guardrail violations - they're deterministic
                    if case AIProcessingError.guardrailViolation = error {
                        break
                    }
                    
                    if attemptWithinProvider == 0 {
                        // Show detailed error reason in retry message
                        let errorDetail = getDetailedErrorMessage(error)
                        retryCallback?("\(providerName) (\(errorDetail))", providerIndex + 1)
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
    
    // MARK: - V2 Page-Group Processing (Chain-based)
    
    func processPagesV2(
        _ pages: [PageTextContent],
        progressCallback: ((Int, Int) -> Void)? = nil,
        providerCallback: ((String) -> Void)? = nil,
        retryCallback: ((String, Int) -> Void)? = nil
    ) async -> (results: [String], partial: PartialResult?) {
        let pagesData: [(pageNumber: Int, text: String)] = pages.enumerated().map { (index, page) in
            let text = page.bestText
            return (pageNumber: index + 1, text: text)
        }
        
        let grouper = PageGrouper(budget: tokenBudget)
        let groups = grouper.groupPages(pagesData)
        
        var results: [String] = Array(repeating: "", count: pages.count)
        var lastCorrectedPage: String? = nil
        var processedCount = 0
        
        for group in groups {
            do {
                let correctedPages = try await processGroupWithRetry(
                    group: group,
                    previousContext: lastCorrectedPage,
                    providerCallback: providerCallback,
                    retryCallback: retryCallback
                )
                
                for (pageNum, text) in correctedPages {
                    let idx = pageNum - 1
                    if idx >= 0 && idx < results.count {
                        results[idx] = text
                        processedCount = max(processedCount, pageNum)
                    }
                }
                
                if let lastPage = correctedPages.last {
                    lastCorrectedPage = PageFormatter.truncateForContext(
                        lastPage.text,
                        maxChars: tokenBudget.previousContextCharLimit()
                    )
                }
                
                progressCallback?(processedCount, pages.count)
                
            } catch {
                let unprocessedIndices = group.pageNumbers.map { $0 - 1 }.filter { $0 < pages.count }
                let unprocessed = unprocessedIndices.map { pages[$0] }
                let partial = PartialResult(
                    processedPages: results.prefix(processedCount).map { $0 },
                    unprocessedPages: unprocessed,
                    error: error
                )
                return (results, partial)
            }
        }
        
        return (results, nil)
    }
    
    public func processPagesV3(
        pages: [PageTextContent],
        progressCallback: ((Int, Int) -> Void)? = nil,
        providerCallback: ((String) -> Void)? = nil,
        retryCallback: ((String, String) -> Void)? = nil
    ) async throws -> ([String], PartialResult?) {
        guard !pages.isEmpty else { return ([], nil) }
        
        var results = Array(repeating: "", count: pages.count)
        let multiPass = MultiPassProcessor(maxChunkSize: tokenBudget.inputChunkCharLimit(), verbose: verbose)
        
        let aiProvider: MultiPassProcessor.AIProvider = { [self] prompt in
            for provider in self.providers {
                providerCallback?(provider.displayName)
                do {
                    switch provider {
                    case .appleIntelligence:
                        guard AppleIntelligenceProcessor.isAvailable else {
                            throw AIProcessingError.appleIntelligenceUnavailable
                        }
                        let processor = AppleIntelligenceProcessor(systemPrompt: "", verbose: self.verbose)
                        return try await processor.processText(prompt)
                    case .openAICompatible(let client):
                        return try await client.complete(systemPrompt: "", userMessage: prompt)
                    }
                } catch {
                    if self.verbose {
                        print("[V3] Provider \(provider.displayName) failed: \(error)")
                    }
                    continue
                }
            }
            throw AIProcessingError.processingFailed("All providers failed")
        }
        
        for (index, page) in pages.enumerated() {
            let pageNum = page.pageIndex + 1
            let pageText = page.bestText
            progressCallback?(index + 1, pages.count)
            
            if verbose {
                print("[V3] Processing page \(pageNum) (\(pageText.count) chars)")
            }
            
            do {
                let result = try await multiPass.process(text: pageText, aiProvider: aiProvider)
                results[index] = result.finalText
                
                if verbose && result.hadFallbacks {
                    let failedPasses = result.passResults.filter { !$0.wasValidated }.map { $0.passName }
                    print("[V3] Page \(pageNum): fallback used for passes: \(failedPasses.joined(separator: ", "))")
                }
            } catch {
                if verbose {
                    print("[V3] Page \(pageNum) failed: \(error). Using original text.")
                }
                results[index] = pageText
            }
        }
        
        return (results, nil)
    }
    
    private func processGroupWithRetry(
        group: PageGroup,
        previousContext: String?,
        providerCallback: ((String) -> Void)?,
        retryCallback: ((String, Int) -> Void)?
    ) async throws -> [(pageNumber: Int, text: String)] {
        var currentGroups = [group]
        var allResults: [(pageNumber: Int, text: String)] = []
        
        while !currentGroups.isEmpty {
            let groupToProcess = currentGroups.removeFirst()
            
            do {
                let results = try await processGroup(
                    group: groupToProcess,
                    previousContext: previousContext,
                    providerCallback: providerCallback,
                    retryCallback: retryCallback
                )
                allResults.append(contentsOf: results)
            } catch AIProcessingError.contextWindowExceeded {
                if groupToProcess.pages.count > 1 {
                    let grouper = PageGrouper(budget: tokenBudget)
                    let split = grouper.splitGroup(groupToProcess)
                    currentGroups.insert(contentsOf: split, at: 0)
                } else {
                    let page = groupToProcess.pages[0]
                    let truncatedText = truncatePage(page.text, budget: tokenBudget)
                    let truncatedGroup = PageGroup(pages: [(pageNumber: page.pageNumber, text: truncatedText)])
                    let results = try await processGroup(
                        group: truncatedGroup,
                        previousContext: previousContext,
                        providerCallback: providerCallback,
                        retryCallback: retryCallback
                    )
                    allResults.append(contentsOf: results)
                }
            }
        }
        
        return allResults.sorted { $0.pageNumber < $1.pageNumber }
    }
    
    private func processGroup(
        group: PageGroup,
        previousContext: String?,
        providerCallback: ((String) -> Void)?,
        retryCallback: ((String, Int) -> Void)?
    ) async throws -> [(pageNumber: Int, text: String)] {
        let prompt = promptTemplateV2.buildPrompt(pages: group.pages, previousContext: previousContext)
        
        var lastError: Error = AIProcessingError.processingFailed("No providers available")
        
        for (providerIndex, provider) in providers.enumerated() {
            let providerName = provider.displayName
            
            for attemptWithinProvider in 0..<2 {
                do {
                    if verbose {
                        let sysPrompt = systemPromptLogged ? nil : promptTemplateV2.systemPrompt
                        let groupInfo = "Pages \(group.pageNumbers.map(String.init).joined(separator: ","))"
                        AILogger.log(AILogger.formatAIInput(prompt, systemPrompt: sysPrompt, chunkInfo: groupInfo), verbose: true)
                        systemPromptLogged = true
                    }
                    
                    let response: String
                    switch provider {
                    case .openAICompatible(let client):
                        providerCallback?(client.model)
                        response = try await client.complete(
                            systemPrompt: promptTemplateV2.systemPrompt,
                            userMessage: prompt
                        )
                    case .appleIntelligence:
                        providerCallback?("Apple Intelligence")
                        guard AppleIntelligenceProcessor.isAvailable else {
                            throw AIProcessingError.appleIntelligenceUnavailable
                        }
                        let processor = AppleIntelligenceProcessor(
                            systemPrompt: promptTemplateV2.systemPrompt,
                            verbose: verbose,
                            tokenBudget: tokenBudget
                        )
                        response = try await processor.processText(prompt)
                    }
                    
                    if verbose {
                        AILogger.log(AILogger.formatAIOutput(response), verbose: true)
                    }
                    
                    return PromptTemplateV2.parseResponse(response, expectedPages: group.pageNumbers)
                    
                } catch {
                    lastError = error
                    
                    if case AIProcessingError.contextWindowExceeded = error {
                        throw error
                    }
                    
                    if case AIProcessingError.guardrailViolation = error {
                        break
                    }
                    
                    if attemptWithinProvider == 0 {
                        let errorDetail = getDetailedErrorMessage(error)
                        retryCallback?("\(providerName) (\(errorDetail))", providerIndex + 1)
                        try await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
                    }
                }
            }
        }
        
        throw lastError
    }
    
    private func truncatePage(_ text: String, budget: TokenBudget) -> String {
        let maxChars = budget.inputChunkCharLimit()
        guard text.count > maxChars else { return text }
        
        let truncated = String(text.prefix(maxChars))
        if let lastNewline = truncated.lastIndex(of: "\n") {
            return String(truncated[..<lastNewline])
        }
        return truncated
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
    
    private func getDetailedErrorMessage(_ error: Error) -> String {
        if let aiError = error as? AIProcessingError {
            switch aiError {
            case .invalidAPIConfiguration(let message):
                return "invalid config: \(message)"
            case .networkError(let underlying):
                return "network: \(underlying.localizedDescription)"
            case .responseParsingError:
                return "parsing failed"
            case .appleIntelligenceUnavailable:
                return "not available"
            case .contextWindowExceeded:
                return "context limit exceeded"
            case .guardrailViolation:
                return "content blocked"
            case .processingFailed(let message):
                return message
            case .partialFailure(_, _, let underlying):
                return getDetailedErrorMessage(underlying)
            }
        }
        
        if let openAIError = error as? OpenAIClientError {
            switch openAIError {
            case .invalidURL:
                return "invalid URL"
            case .noResponse:
                return "no response"
            case .emptyContent:
                return "empty response"
            case .httpError(let statusCode, let message):
                if statusCode == 401 {
                    return "auth failed"
                } else if statusCode == 429 {
                    return "rate limited"
                } else if statusCode == 500 || statusCode == 502 || statusCode == 503 {
                    return "server error \(statusCode)"
                } else if let msg = message {
                    return "HTTP \(statusCode): \(msg)"
                } else {
                    return "HTTP error \(statusCode)"
                }
            case .rateLimited(let retryAfter):
                if let seconds = retryAfter {
                    return "rate limited (\(seconds)s)"
                } else {
                    return "rate limited"
                }
            case .timeout:
                return "timeout"
            case .networkError(let underlying):
                if (underlying as NSError).code == -1009 {
                    return "no internet"
                } else if (underlying as NSError).code == -1001 {
                    return "timeout"
                } else {
                    return "network error"
                }
            case .decodingError:
                return "response decode failed"
            }
        }
        
        return error.localizedDescription
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
            return "Apple Intelligence is not available (requires macOS 15+ with Apple Silicon and FoundationModels framework)"
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
