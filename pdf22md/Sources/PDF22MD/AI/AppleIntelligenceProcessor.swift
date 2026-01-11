// this_file: pdf22md/Sources/PDF22MD/AI/AppleIntelligenceProcessor.swift

import Foundation

// MARK: - Apple Intelligence Processor

/// Processor for on-device AI text correction using Apple's Foundation Models framework
/// Available on macOS 26+ (Tahoe) with Apple Intelligence support
///
/// Note: This is a stub implementation that will be fully enabled when:
/// 1. macOS 26 (Tahoe) is released
/// 2. The FoundationModels framework is available in the SDK
/// 3. The device supports Apple Intelligence (Apple Silicon required)
///
/// When FoundationModels becomes available, uncomment the #if canImport(FoundationModels)
/// section and update the implementation.

public final class AppleIntelligenceProcessor {
    public init() {}

    /// Check if Apple Intelligence is available on this device
    /// Currently always returns false until macOS 26 is released
    public static var isAvailable: Bool {
        // Will be enabled when FoundationModels is available
        // #if canImport(FoundationModels)
        // if #available(macOS 26.0, *) {
        //     return true
        // }
        // #endif
        return false
    }

    /// Process a single page of text with AI correction
    /// - Parameters:
    ///   - pdfText: Text extracted from PDF
    ///   - visionText: Text extracted via Vision OCR (optional)
    ///   - previousContext: Context from previous page for continuity
    ///   - pageNumber: Current page number (1-based)
    /// - Returns: Corrected text
    /// - Throws: AIProcessingError.appleIntelligenceUnavailable until macOS 26
    public func processPage(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int
    ) async throws -> String {
        // When FoundationModels is available, this will use:
        // - SystemLanguageModel.shared[.default] to get the on-device model
        // - LanguageModelSession for stateful conversations
        // - Prompt with Instructions for system prompts
        // - session.generate() for text generation
        throw AIProcessingError.appleIntelligenceUnavailable
    }

    /// Process multiple pages sequentially with sliding window context
    /// - Parameter pages: Array of page content to process
    /// - Returns: Array of corrected text strings
    /// - Throws: AIProcessingError.appleIntelligenceUnavailable until macOS 26
    func processPages(_ pages: [PageTextContent]) async throws -> [String] {
        throw AIProcessingError.appleIntelligenceUnavailable
    }

    /// Reset the session (clears conversation history)
    public func resetSession() {
        // No-op until FoundationModels is available
    }
}

// MARK: - Future Implementation (macOS 26+)

/*
 When FoundationModels becomes available in the SDK, replace the class above with:

 #if canImport(FoundationModels)
 import FoundationModels

 @available(macOS 26.0, *)
 public final class AppleIntelligenceProcessor {
     private var session: LanguageModelSession?

     public init() {}

     public static var isAvailable: Bool { true }

     private func ensureSession() async throws -> LanguageModelSession {
         if let session = session {
             return session
         }
         let model = try await SystemLanguageModel.shared[.default]
         let newSession = LanguageModelSession(model: model)
         self.session = newSession
         return newSession
     }

     public func processPage(
         pdfText: String,
         visionText: String?,
         previousContext: String?,
         pageNumber: Int
     ) async throws -> String {
         let session = try await ensureSession()

         let instructions = Instructions("""
             You are an expert OCR text corrector. Fix OCR errors while preserving
             the original meaning and structure. Do NOT add commentary.
             """)

         var userMessage = "Page \(pageNumber) text to correct:\n\n"
         if let visionText = visionText, !visionText.isEmpty {
             userMessage += "PDF: \(pdfText)\n\nOCR: \(visionText)"
         } else {
             userMessage += pdfText
         }
         if let context = previousContext {
             userMessage += "\n\nPrevious page ended with: \(String(context.suffix(500)))"
         }

         let prompt = Prompt(instructions: instructions, messages: [.user(userMessage)])
         let result = try await session.generate(prompt: prompt, options: GenerationOptions(temperature: 0.3))

         return result.output.text ?? (visionText ?? pdfText)
     }

     public func processPages(_ pages: [PageTextContent]) async throws -> [String] {
         var results: [String] = []
         var previousContext: String? = nil
         for page in pages {
             let corrected = try await processPage(
                 pdfText: page.pdfText,
                 visionText: page.visionText,
                 previousContext: previousContext,
                 pageNumber: page.pageIndex + 1
             )
             results.append(corrected)
             previousContext = corrected
         }
         return results
     }

     public func resetSession() { session = nil }
 }
 #endif
 */
