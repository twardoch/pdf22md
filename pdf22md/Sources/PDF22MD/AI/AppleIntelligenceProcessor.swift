import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple Intelligence integration using Foundation Models framework
public struct AppleIntelligenceProcessor {
    private let systemPrompt: String
    private let verbose: Bool
    private let tokenBudget: TokenBudget
    
    public init(systemPrompt: String, verbose: Bool = false, tokenBudget: TokenBudget = .appleIntelligence) {
        self.systemPrompt = systemPrompt
        self.verbose = verbose
        self.tokenBudget = tokenBudget
    }
    
    /// Check if Apple Intelligence is available on this device
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
        #endif
        return false
    }
    
    /// Get detailed availability status for error messages
    public static var availabilityStatus: String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "available"
            case .unavailable(.appleIntelligenceNotEnabled):
                return "not enabled - enable in System Settings → Apple Intelligence & Siri"
            case .unavailable(.deviceNotEligible):
                return "device not eligible - Apple Silicon Mac required"
            case .unavailable(.modelNotReady):
                return "model assets downloading - try again in a few minutes"
            case .unavailable(let reason):
                return "unavailable: \(reason)"
            }
        } else {
            return "requires macOS 26.0 or later"
        }
        #else
        return "FoundationModels framework not available"
        #endif
    }
    
    /// Process text using Apple Intelligence (V2 - for page groups)
    public func processText(_ prompt: String) async throws -> String {
        guard Self.isAvailable else {
            throw AIProcessingError.appleIntelligenceUnavailable
        }
        
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AIProcessingError.appleIntelligenceUnavailable
        }
        
        return try await processSingleRequest(prompt)
        #else
        throw AIProcessingError.appleIntelligenceUnavailable
        #endif
    }
    
    /// Process a page of text using Apple Intelligence with automatic chunking
    public func processPage(_ text: String, pageNumber: Int) async throws -> String {
        guard Self.isAvailable else {
            throw AIProcessingError.appleIntelligenceUnavailable
        }
        
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AIProcessingError.appleIntelligenceUnavailable
        }
        
        let limits = ContextLimits.appleIntelligence
        let systemTokens = TokenEstimator.estimate(systemPrompt)
        
        let userPrompt = """
        <OCR_TEXT>
        \(text)
        </OCR_TEXT>
        """
        
        let totalTokens = TokenEstimator.estimate(userPrompt) + systemTokens
        
        if totalTokens + limits.maxOutputTokens > limits.totalContextWindow {
            let numChunks = TokenEstimator.suggestedChunkCount(
                text: text,
                systemPrompt: systemPrompt,
                limits: limits
            )
            return try await processInChunks(text, numChunks: numChunks)
        }
        
        return try await processSingleRequest(userPrompt)
        #else
        throw AIProcessingError.appleIntelligenceUnavailable
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func processSingleRequest(_ userPrompt: String, chunkInfo: String? = nil) async throws -> String {
        let instructions = Instructions(systemPrompt)
        let session = LanguageModelSession(instructions: instructions)
        
        do {
            let options = GenerationOptions(
                temperature: 0.3,
                maximumResponseTokens: 1000
            )
            
            let response = try await session.respond(to: userPrompt, options: options)
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if verbose && chunkInfo != nil {
                AILogger.log(AILogger.formatAIOutput(content), verbose: true)
            }
            
            return content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                throw AIProcessingError.contextWindowExceeded
            default:
                throw AIProcessingError.processingFailed("Apple Intelligence error: \(error)")
            }
        } catch {
            throw AIProcessingError.processingFailed("Apple Intelligence error: \(error.localizedDescription)")
        }
    }
    
    @available(macOS 26.0, *)
    private func processInChunks(_ text: String, numChunks: Int) async throws -> String {
        let chunker = TextChunker(overlapPercentage: 0.15)
        let chunks = chunker.chunk(text, into: numChunks)
        
        var processedChunks: [(chunk: TextChunk, response: String)] = []
        
        for chunk in chunks {
            let chunkPrompt = """
            <OCR_TEXT>
            [Part \(chunk.chunkIndex + 1) of \(chunk.totalChunks)]
            \(chunk.text)
            </OCR_TEXT>
            """
            
            let chunkInfo = "Chunk \(chunk.chunkIndex + 1)/\(chunk.totalChunks)"
            if verbose {
                AILogger.log(AILogger.formatAIInput(chunkPrompt, systemPrompt: nil, chunkInfo: chunkInfo), verbose: true)
            }
            
            let response = try await processSingleRequest(chunkPrompt, chunkInfo: chunkInfo)
            processedChunks.append((chunk, response))
        }
        
        return TextChunker.reassemble(processedChunks)
    }
    #endif
}
