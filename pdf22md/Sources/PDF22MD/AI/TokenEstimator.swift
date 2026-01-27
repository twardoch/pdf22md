import Foundation

public struct TokenEstimator {
    private static let charactersPerToken: Double = 4.0
    private static let safetyMargin: Double = 1.2
    
    public static func estimate(_ text: String) -> Int {
        let charCount = text.count
        let baseEstimate = Double(charCount) / charactersPerToken
        return Int(ceil(baseEstimate * safetyMargin))
    }
    
    public static func estimateWithPrompt(text: String, systemPrompt: String, xmlTags: Int = 20) -> Int {
        let textTokens = estimate(text)
        let promptTokens = estimate(systemPrompt)
        let tagTokens = xmlTags
        return textTokens + promptTokens + tagTokens
    }
    
    public static func fitsInContext(_ text: String, systemPrompt: String, limits: ContextLimits) -> Bool {
        let estimatedTokens = estimateWithPrompt(text: text, systemPrompt: systemPrompt)
        return limits.allowsInputSize(estimatedTokens, withOutputBuffer: limits.maxOutputTokens)
    }
    
    public static func suggestedChunkCount(text: String, systemPrompt: String, limits: ContextLimits) -> Int {
        let totalTokens = estimateWithPrompt(text: text, systemPrompt: systemPrompt)
        if totalTokens <= limits.maxInputTokens {
            return 1
        }
        
        let availableForText = limits.maxInputTokens - estimate(systemPrompt) - 20
        let textTokens = estimate(text)
        let chunksNeeded = Int(ceil(Double(textTokens) / Double(availableForText)))
        
        return max(2, chunksNeeded)
    }
}
