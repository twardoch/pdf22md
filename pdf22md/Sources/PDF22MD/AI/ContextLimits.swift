import Foundation

public struct ContextLimits {
    public let maxInputTokens: Int
    public let maxOutputTokens: Int
    public let totalContextWindow: Int
    
    public init(maxInputTokens: Int, maxOutputTokens: Int, totalContextWindow: Int) {
        self.maxInputTokens = maxInputTokens
        self.maxOutputTokens = maxOutputTokens
        self.totalContextWindow = totalContextWindow
    }
    
    public static let appleIntelligence = ContextLimits(
        maxInputTokens: 3000,
        maxOutputTokens: 1000,
        totalContextWindow: 4096
    )
    
    public static let openAIGPT4 = ContextLimits(
        maxInputTokens: 120000,
        maxOutputTokens: 8000,
        totalContextWindow: 128000
    )
    
    public static let openAIGPT35 = ContextLimits(
        maxInputTokens: 14000,
        maxOutputTokens: 2000,
        totalContextWindow: 16384
    )
    
    public static let defaultLimit = ContextLimits(
        maxInputTokens: 14000,
        maxOutputTokens: 2000,
        totalContextWindow: 16384
    )
    
    public func allowsInputSize(_ estimatedTokens: Int, withOutputBuffer: Int) -> Bool {
        return estimatedTokens + withOutputBuffer <= totalContextWindow
    }
    
    public func suggestedChunkSize(forInputTokens tokens: Int) -> Int {
        if tokens <= maxInputTokens {
            return tokens
        }
        return max(maxInputTokens / 2, 500)
    }
}
