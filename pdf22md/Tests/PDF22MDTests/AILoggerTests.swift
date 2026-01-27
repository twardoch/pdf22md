import XCTest
@testable import PDF22MD

final class AILoggerTests: XCTestCase {
    
    func test_truncate_shortString_returnsUnchanged() {
        let input = "hello"
        let result = AILogger.truncate(input)
        XCTAssertEqual(result, "hello")
    }
    
    func test_truncate_exactlyMaxLength_returnsUnchanged() {
        let input = String(repeating: "a", count: 600)
        let result = AILogger.truncate(input)
        XCTAssertEqual(result, input)
    }
    
    func test_truncate_longString_returns300Start_300End() {
        let start = String(repeating: "A", count: 500)
        let end = String(repeating: "Z", count: 500)
        let input = start + end
        
        let result = AILogger.truncate(input)
        
        XCTAssertTrue(result.hasPrefix(String(repeating: "A", count: 300)))
        XCTAssertTrue(result.hasSuffix(String(repeating: "Z", count: 300)))
        XCTAssertTrue(result.contains("..."))
        XCTAssertEqual(result.count, 603)
    }
    
    func test_truncate_emptyString_returnsEmpty() {
        let result = AILogger.truncate("")
        XCTAssertEqual(result, "")
    }
    
    func test_formatAIInput_withSystemPrompt_includesSystemSection() {
        let result = AILogger.formatAIInput("user message", systemPrompt: "system msg")
        
        XCTAssertTrue(result.contains("[System]"))
        XCTAssertTrue(result.contains("(10)"))
        XCTAssertTrue(result.contains("[AI→]"))
        XCTAssertTrue(result.contains("(12)"))
    }
    
    func test_formatAIInput_withChunkInfo_includesChunkPrefix() {
        let result = AILogger.formatAIInput("test", chunkInfo: "Chunk 1/3")
        
        XCTAssertTrue(result.hasPrefix("[Chunk 1/3] [AI→]"))
    }
    
    func test_formatAIInput_withoutSystemPrompt_onlyUserMessage() {
        let result = AILogger.formatAIInput("test content")
        
        XCTAssertTrue(result.hasPrefix("[AI→]"))
        XCTAssertFalse(result.contains("[System]"))
    }
    
    func test_formatAIOutput_includesLengthMarker() {
        let result = AILogger.formatAIOutput("response text")
        
        XCTAssertEqual(result, "[←AI] response text (13)")
    }
}
