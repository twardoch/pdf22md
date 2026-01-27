import Foundation

public struct PageFormatter {
    
    public static func formatPages(_ pages: [(pageNumber: Int, text: String)]) -> String {
        pages.map { page in
            "<page num=\"\(page.pageNumber)\">\n\(page.text)\n</page>"
        }.joined(separator: "\n\n")
    }
    
    public static func formatPage(number: Int, text: String) -> String {
        "<page num=\"\(number)\">\n\(text)\n</page>"
    }
    
    public static func parsePages(_ response: String, expectedPages: [Int] = [1]) -> [(pageNumber: Int, text: String)] {
        PromptTemplateV2.parseResponse(response, expectedPages: expectedPages)
    }
    
    public static func truncateForContext(_ text: String, maxChars: Int) -> String {
        guard text.count > maxChars else { return text }
        
        let endIndex = text.index(text.startIndex, offsetBy: maxChars)
        var truncated = String(text[..<endIndex])
        
        if let lastNewline = truncated.lastIndex(of: "\n") {
            truncated = String(truncated[..<lastNewline])
        }
        
        return truncated
    }
}
