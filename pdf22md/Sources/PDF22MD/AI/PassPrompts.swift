import Foundation

public enum PassPrompts {
    
    public static let dehyphenation = """
    Join words split by hyphens at line endings. If a word ends with hyphen then newline, join it with next word. Keep all other text unchanged. Output corrected text only.
    """
    
    public static let ocrCorrection = """
    Fix OCR errors: 0CR to OCR, rn to m, common character swaps. Fix obvious typos. Keep meaning intact. Output corrected text only.
    """
    
    public static let cleanup = """
    Clean formatting: remove extra spaces, remove stray | / \\ characters. Normalize to single spaces. Output cleaned text only.
    """
    
    public static let allPasses: [(name: String, prompt: String)] = [
        ("dehyphenation", dehyphenation),
        ("ocrCorrection", ocrCorrection),
        ("cleanup", cleanup)
    ]
    
    public static func pass(at index: Int) -> (name: String, prompt: String)? {
        guard index >= 0 && index < allPasses.count else { return nil }
        return allPasses[index]
    }
    
    public static var passCount: Int { allPasses.count }
    
    public static func buildPrompt(passIndex: Int, text: String) -> String? {
        guard let (_, instruction) = pass(at: passIndex) else { return nil }
        return """
        \(instruction)
        
        TEXT:
        \(text)
        """
    }
    
    public static let singlePassFull = """
    Correct OCR text: join hyphenated words, fix character errors, remove extra spaces. Output only corrected text.
    """
}
