import Foundation

/// Orchestrates multi-pass AI text correction with validation and fallback.
/// Each pass applies a simple, focused transformation (dehyphenation, OCR fix, cleanup).
/// If any pass produces suspicious output (validation fails), it falls back to input.
public struct MultiPassProcessor {
    
    public typealias AIProvider = (String) async throws -> String
    
    private let chunker: ParagraphChunker
    private let validator: TextValidator
    private let verbose: Bool
    
    public init(
        maxChunkSize: Int = 3500,
        similarityThreshold: Double = 0.85,
        verbose: Bool = false
    ) {
        self.chunker = ParagraphChunker(maxChunkSize: maxChunkSize)
        self.validator = TextValidator(
            similarityThreshold: similarityThreshold,
            maxContentLoss: 0.15,
            lengthRatioRange: 0.7...1.3
        )
        self.verbose = verbose
    }
    
    public struct PassResult {
        public let passIndex: Int
        public let passName: String
        public let input: String
        public let output: String
        public let wasValidated: Bool
        public let validationReason: String?
        
        public var usedFallback: Bool { !wasValidated }
    }
    
    public struct ProcessingResult {
        public let originalText: String
        public let finalText: String
        public let passResults: [PassResult]
        public let totalPasses: Int
        public let successfulPasses: Int
        
        public var hadFallbacks: Bool { successfulPasses < totalPasses }
    }
    
    public func process(
        text: String,
        aiProvider: @escaping AIProvider
    ) async throws -> ProcessingResult {
        var currentText = text
        var passResults: [PassResult] = []
        var successfulPasses = 0
        
        for passIndex in 0..<PassPrompts.passCount {
            guard let (passName, _) = PassPrompts.pass(at: passIndex) else { continue }
            
            if verbose {
                print("[MultiPass] Starting pass \(passIndex + 1)/\(PassPrompts.passCount): \(passName)")
            }
            
            let passInput = currentText
            let passOutput = try await processPass(
                passIndex: passIndex,
                text: currentText,
                aiProvider: aiProvider
            )
            
            let validation = validator.validate(input: passInput, output: passOutput)
            
            let result: PassResult
            if validation.isValid {
                currentText = passOutput
                successfulPasses += 1
                result = PassResult(
                    passIndex: passIndex,
                    passName: passName,
                    input: passInput,
                    output: passOutput,
                    wasValidated: true,
                    validationReason: nil
                )
                if verbose {
                    print("[MultiPass] Pass \(passName) validated (similarity: \(String(format: "%.2f", validation.similarity)))")
                }
            } else {
                result = PassResult(
                    passIndex: passIndex,
                    passName: passName,
                    input: passInput,
                    output: passOutput,
                    wasValidated: false,
                    validationReason: validation.reason
                )
                if verbose {
                    print("[MultiPass] WARNING: Pass \(passName) REJECTED - \(validation.reason ?? "unknown"). Using input text.")
                }
            }
            
            passResults.append(result)
        }
        
        return ProcessingResult(
            originalText: text,
            finalText: currentText,
            passResults: passResults,
            totalPasses: PassPrompts.passCount,
            successfulPasses: successfulPasses
        )
    }
    
    private func processPass(
        passIndex: Int,
        text: String,
        aiProvider: AIProvider
    ) async throws -> String {
        let chunks = chunker.chunk(text)
        
        if verbose {
            print("[MultiPass] Processing \(chunks.count) chunk(s)")
        }
        
        var processedChunks: [ParagraphChunker.Chunk] = []
        
        for chunk in chunks {
            guard let prompt = PassPrompts.buildPrompt(passIndex: passIndex, text: chunk.text) else {
                processedChunks.append(chunk)
                continue
            }
            
            do {
                let result = try await aiProvider(prompt)
                let cleanResult = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                if cleanResult.isEmpty {
                    if verbose {
                        print("[MultiPass] Empty response for chunk \(chunk.index), using original")
                    }
                    processedChunks.append(chunk)
                } else {
                    processedChunks.append(ParagraphChunker.Chunk(
                        text: cleanResult,
                        index: chunk.index,
                        isLast: chunk.isLast
                    ))
                }
            } catch {
                if verbose {
                    print("[MultiPass] Error processing chunk \(chunk.index): \(error). Using original.")
                }
                processedChunks.append(chunk)
            }
        }
        
        return chunker.reassemble(processedChunks)
    }
    
    public func processSinglePage(
        pageNumber: Int,
        text: String,
        aiProvider: @escaping AIProvider
    ) async throws -> (pageNumber: Int, text: String, result: ProcessingResult) {
        let result = try await process(text: text, aiProvider: aiProvider)
        return (pageNumber: pageNumber, text: result.finalText, result: result)
    }
}
