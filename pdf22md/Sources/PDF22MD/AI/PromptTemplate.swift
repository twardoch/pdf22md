// this_file: pdf22md/Sources/PDF22MD/AI/PromptTemplate.swift

import Foundation

public struct PromptTemplate: Codable {
    public let systemPrompt: String
    public let pagePromptTemplate: String
    public let previousContextTemplate: String?
    public let visionTextTemplate: String?
    public let outputInstructions: String?
    
    public static let `default` = PromptTemplate(
        systemPrompt: """
            You are a text correction assistant specializing in cleaning up text extracted from PDF documents.
            Your task is to produce simple, well-formatted HTML output.

            Guidelines:
            - Fix obvious spelling and typographic errors
            - Combine broken lines into logical paragraphs and wrap them in <p> tags
            - Identify headings and wrap them into <h2> and <h3> tags
            - Identify important formatting and wrap bolds in <b>, italics in <i>.
            - Wrap sentences in <s> tags.
            - Move image captions, footnotes, and margin notes to the end of the page and wrap them in <figcaption>, <footer>, and <aside> tags respectively.
            - Remove running headers, page numbers, and other artifacts
            - Remove garbled text, noise, and garbage characters
            - Maintain the original meaning and content
            - Do not add information that wasn't in the original text

            Output format:
            - If previous page context was provided, first output any improvements to the previous page text between <IMPROVED_PREVIOUS> and </IMPROVED_PREVIOUS> tags
            - Then output the corrected text for the current page between <CORRECTED> and </CORRECTED> tags
            """,
        pagePromptTemplate: """
            Page {{PAGE_NUMBER}} of PDF document.

            PDF-extracted text:
            ---
            {{PDF_TEXT}}
            ---

            Please correct and format the text as simple HTML. Output the corrected HTML in <CORRECTED></CORRECTED> tags.
            """,
        previousContextTemplate: """
            Previous page (for context and flow):
            ---
            {{PREVIOUS_TEXT}}
            ---

            If the previous page text could be improved to better connect with the current page, include improvements in <IMPROVED_PREVIOUS> tags.
            """,
        visionTextTemplate: """
            OCR-extracted text (from Vision):
            ---
            {{VISION_TEXT}}
            ---

            Use the OCR text to fill in any gaps or fix errors in the PDF text.
            """,
        outputInstructions: nil
    )
    
    public init(
        systemPrompt: String,
        pagePromptTemplate: String,
        previousContextTemplate: String? = nil,
        visionTextTemplate: String? = nil,
        outputInstructions: String? = nil
    ) {
        self.systemPrompt = systemPrompt
        self.pagePromptTemplate = pagePromptTemplate
        self.previousContextTemplate = previousContextTemplate
        self.visionTextTemplate = visionTextTemplate
        self.outputInstructions = outputInstructions
    }
    
    public static func load(from url: URL) throws -> PromptTemplate {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PromptTemplate.self, from: data)
    }
    
    public func buildPrompt(
        pdfText: String,
        visionText: String?,
        previousContext: String?,
        pageNumber: Int
    ) -> String {
        var prompt = pagePromptTemplate
            .replacingOccurrences(of: "{{PAGE_NUMBER}}", with: String(pageNumber))
            .replacingOccurrences(of: "{{PDF_TEXT}}", with: pdfText)
        
        if let previous = previousContext, let template = previousContextTemplate {
            let contextSection = template.replacingOccurrences(of: "{{PREVIOUS_TEXT}}", with: previous)
            prompt = contextSection + "\n\n" + prompt
        }
        
        if let vision = visionText, !vision.isEmpty, let template = visionTextTemplate {
            if vision.count > pdfText.count / 2 || pdfText.count < 100 {
                let visionSection = template.replacingOccurrences(of: "{{VISION_TEXT}}", with: vision)
                prompt += "\n\n" + visionSection
            }
        }
        
        if let instructions = outputInstructions {
            prompt += "\n\n" + instructions
        }
        
        return prompt
    }
}
