import Foundation

public struct TokenBudget {
    public let instructionTokens: Int
    public let previousContextTokens: Int
    public let inputChunkTokens: Int
    public let outputTokens: Int
    
    public var totalInputBudget: Int {
        instructionTokens + previousContextTokens + inputChunkTokens
    }
    
    public var totalContextWindow: Int {
        totalInputBudget + outputTokens
    }
    
    public static let appleIntelligence = TokenBudget(
        instructionTokens: 500,
        previousContextTokens: 1000,
        inputChunkTokens: 1000,
        outputTokens: 1000
    )
    
    public static let openAIDefault = TokenBudget(
        instructionTokens: 1000,
        previousContextTokens: 4000,
        inputChunkTokens: 4000,
        outputTokens: 4000
    )
    
    public static let openAILarge = TokenBudget(
        instructionTokens: 2000,
        previousContextTokens: 8000,
        inputChunkTokens: 8000,
        outputTokens: 8000
    )
    
    public func inputChunkCharLimit() -> Int {
        inputChunkTokens * 4
    }
    
    public func previousContextCharLimit() -> Int {
        previousContextTokens * 4
    }
    
    public func fitsInInputBudget(pageChars: Int, previousChars: Int) -> Bool {
        let pageTokens = (pageChars + 3) / 4
        let prevTokens = (previousChars + 3) / 4
        return pageTokens <= inputChunkTokens && prevTokens <= previousContextTokens
    }
    
    public func halved() -> TokenBudget {
        TokenBudget(
            instructionTokens: instructionTokens,
            previousContextTokens: previousContextTokens / 2,
            inputChunkTokens: inputChunkTokens / 2,
            outputTokens: outputTokens / 2
        )
    }
}
