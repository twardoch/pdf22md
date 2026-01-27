import Foundation

public struct PromptTemplateV2: Codable {
    public let systemPrompt: String
    public let userPromptTemplate: String
    
    public static let `default` = PromptTemplateV2(
        systemPrompt: """
            You clean OCR text extracted from PDF documents.
            
            RULES:
            - Fix spelling and OCR errors
            - Format as Markdown: use # for headings, - for lists
            - Combine broken lines into paragraphs
            - Preserve original meaning exactly - do NOT add or remove content
            - Remove page numbers and running headers
            
            OUTPUT FORMAT:
            Wrap each corrected page in <page num="N">...</page> tags matching input.
            """,
        userPromptTemplate: """
            {{PREVIOUS_CONTEXT}}
            <pages_to_correct>
            {{PAGES}}
            </pages_to_correct>
            
            Output corrected pages with same <page num="N"> structure.
            """
    )
    
    public func buildPrompt(pages: [(pageNumber: Int, text: String)], previousContext: String?) -> String {
        let pagesXML = pages.map { page in
            "<page num=\"\(page.pageNumber)\">\n\(page.text)\n</page>"
        }.joined(separator: "\n\n")
        
        var contextSection = ""
        if let prev = previousContext, !prev.isEmpty {
            contextSection = """
                <previous_context>
                \(prev)
                </previous_context>
                
                """
        }
        
        return userPromptTemplate
            .replacingOccurrences(of: "{{PREVIOUS_CONTEXT}}", with: contextSection)
            .replacingOccurrences(of: "{{PAGES}}", with: pagesXML)
    }
    
    public static func parseResponse(_ response: String, expectedPages: [Int] = [1]) -> [(pageNumber: Int, text: String)] {
        var results: [(pageNumber: Int, text: String)] = []
        
        let closedTagPattern = #"<page\s+num="(\d+)">([\s\S]*?)</page>"#
        if let regex = try? NSRegularExpression(pattern: closedTagPattern, options: []) {
            let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
            let matches = regex.matches(in: response, options: [], range: nsRange)
            
            for match in matches {
                guard match.numberOfRanges == 3,
                      let numRange = Range(match.range(at: 1), in: response),
                      let textRange = Range(match.range(at: 2), in: response),
                      let pageNum = Int(response[numRange]) else {
                    continue
                }
                let text = String(response[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                results.append((pageNumber: pageNum, text: text))
            }
        }
        
        if results.isEmpty {
            let unclosedTagPattern = #"<page\s+num="(\d+)">([\s\S]*?)(?=<page\s+num="|$)"#
            if let regex = try? NSRegularExpression(pattern: unclosedTagPattern, options: []) {
                let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
                let matches = regex.matches(in: response, options: [], range: nsRange)
                
                for match in matches {
                    guard match.numberOfRanges == 3,
                          let numRange = Range(match.range(at: 1), in: response),
                          let textRange = Range(match.range(at: 2), in: response),
                          let pageNum = Int(response[numRange]) else {
                        continue
                    }
                    var text = String(response[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.hasSuffix("</page>") {
                        text = String(text.dropLast(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    results.append((pageNumber: pageNum, text: text))
                }
            }
        }
        
        if results.isEmpty {
            var cleanText = response
            let leadingTagPattern = #"^<page\s+num="\d+">\s*"#
            if let regex = try? NSRegularExpression(pattern: leadingTagPattern, options: []) {
                let nsRange = NSRange(cleanText.startIndex..<cleanText.endIndex, in: cleanText)
                cleanText = regex.stringByReplacingMatches(in: cleanText, options: [], range: nsRange, withTemplate: "")
            }
            cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let pageNum = expectedPages.first ?? 1
            return [(pageNumber: pageNum, text: cleanText)]
        }
        
        return results.sorted { $0.pageNumber < $1.pageNumber }
    }
}
