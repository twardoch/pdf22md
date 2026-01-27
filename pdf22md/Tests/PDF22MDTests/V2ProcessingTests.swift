import XCTest
@testable import PDF22MD

final class TokenBudgetTests: XCTestCase {
    
    func test_appleIntelligence_hasCorrectBudget() {
        let budget = TokenBudget.appleIntelligence
        XCTAssertEqual(budget.instructionTokens, 500)
        XCTAssertEqual(budget.previousContextTokens, 1000)
        XCTAssertEqual(budget.inputChunkTokens, 1000)
        XCTAssertEqual(budget.outputTokens, 1000)
        XCTAssertEqual(budget.totalContextWindow, 3500)
    }
    
    func test_inputChunkCharLimit_returns4xTokens() {
        let budget = TokenBudget.appleIntelligence
        XCTAssertEqual(budget.inputChunkCharLimit(), 4000)
    }
    
    func test_halved_dividesTokensByTwo() {
        let budget = TokenBudget.appleIntelligence
        let halved = budget.halved()
        XCTAssertEqual(halved.inputChunkTokens, 500)
        XCTAssertEqual(halved.previousContextTokens, 500)
        XCTAssertEqual(halved.outputTokens, 500)
        XCTAssertEqual(halved.instructionTokens, 500)
    }
}

final class PageGrouperTests: XCTestCase {
    
    func test_groupPages_singleSmallPage_returnsOneGroup() {
        let budget = TokenBudget.appleIntelligence
        let grouper = PageGrouper(budget: budget)
        let pages = [(pageNumber: 1, text: "Short text")]
        
        let groups = grouper.groupPages(pages)
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].pages.count, 1)
    }
    
    func test_groupPages_multipleSmallPages_groupsTogether() {
        let budget = TokenBudget.appleIntelligence
        let grouper = PageGrouper(budget: budget)
        let pages = [
            (pageNumber: 1, text: String(repeating: "a", count: 500)),
            (pageNumber: 2, text: String(repeating: "b", count: 500)),
            (pageNumber: 3, text: String(repeating: "c", count: 500))
        ]
        
        let groups = grouper.groupPages(pages)
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].pages.count, 3)
    }
    
    func test_groupPages_largePages_splitsIntoMultipleGroups() {
        let budget = TokenBudget.appleIntelligence
        let grouper = PageGrouper(budget: budget)
        let pages = [
            (pageNumber: 1, text: String(repeating: "a", count: 3000)),
            (pageNumber: 2, text: String(repeating: "b", count: 3000))
        ]
        
        let groups = grouper.groupPages(pages)
        
        XCTAssertEqual(groups.count, 2)
    }
    
    func test_splitGroup_dividesGroupInHalf() {
        let budget = TokenBudget.appleIntelligence
        let grouper = PageGrouper(budget: budget)
        let pages = [
            (pageNumber: 1, text: "a"),
            (pageNumber: 2, text: "b"),
            (pageNumber: 3, text: "c"),
            (pageNumber: 4, text: "d")
        ]
        let group = PageGroup(pages: pages)
        
        let split = grouper.splitGroup(group)
        
        XCTAssertEqual(split.count, 2)
        XCTAssertEqual(split[0].pages.count, 2)
        XCTAssertEqual(split[1].pages.count, 2)
    }
}

final class PromptTemplateV2Tests: XCTestCase {
    
    func test_buildPrompt_withoutPrevious_excludesPreviousContext() {
        let template = PromptTemplateV2.default
        let pages = [(pageNumber: 1, text: "Hello world")]
        
        let result = template.buildPrompt(pages: pages, previousContext: nil)
        
        XCTAssertFalse(result.contains("<previous_context>"))
        XCTAssertTrue(result.contains("<page num=\"1\">"))
        XCTAssertTrue(result.contains("Hello world"))
    }
    
    func test_buildPrompt_withPrevious_includesPreviousContext() {
        let template = PromptTemplateV2.default
        let pages = [(pageNumber: 2, text: "Page two")]
        
        let result = template.buildPrompt(pages: pages, previousContext: "Previous page text")
        
        XCTAssertTrue(result.contains("<previous_context>"))
        XCTAssertTrue(result.contains("Previous page text"))
    }
    
    func test_parseResponse_extractsPageNumbers() {
        let response = """
        <page num="1">First page</page>
        <page num="2">Second page</page>
        """
        
        let parsed = PromptTemplateV2.parseResponse(response)
        
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].pageNumber, 1)
        XCTAssertEqual(parsed[0].text, "First page")
        XCTAssertEqual(parsed[1].pageNumber, 2)
        XCTAssertEqual(parsed[1].text, "Second page")
    }
    
    func test_parseResponse_noTags_returnsFallback() {
        let response = "Just plain text without tags"
        
        let parsed = PromptTemplateV2.parseResponse(response)
        
        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed[0].pageNumber, 1)
        XCTAssertEqual(parsed[0].text, response)
    }
}
