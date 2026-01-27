import Foundation

public struct PageGroup {
    public let pages: [(pageNumber: Int, text: String)]
    public let totalChars: Int
    
    public init(pages: [(pageNumber: Int, text: String)]) {
        self.pages = pages
        self.totalChars = pages.reduce(0) { $0 + $1.text.count }
    }
    
    public var pageNumbers: [Int] {
        pages.map { $0.pageNumber }
    }
    
    public var firstPage: Int? {
        pages.first?.pageNumber
    }
    
    public var lastPage: Int? {
        pages.last?.pageNumber
    }
}

public struct PageGrouper {
    private let budget: TokenBudget
    
    public init(budget: TokenBudget) {
        self.budget = budget
    }
    
    public func groupPages(_ pages: [(pageNumber: Int, text: String)]) -> [PageGroup] {
        guard !pages.isEmpty else { return [] }
        
        let charLimit = budget.inputChunkCharLimit()
        var groups: [PageGroup] = []
        var currentPages: [(pageNumber: Int, text: String)] = []
        var currentChars = 0
        
        for page in pages {
            let pageChars = page.text.count + 30
            
            if pageChars > charLimit {
                if !currentPages.isEmpty {
                    groups.append(PageGroup(pages: currentPages))
                    currentPages = []
                    currentChars = 0
                }
                groups.append(PageGroup(pages: [page]))
                continue
            }
            
            if currentChars + pageChars > charLimit {
                if !currentPages.isEmpty {
                    groups.append(PageGroup(pages: currentPages))
                }
                currentPages = [page]
                currentChars = pageChars
            } else {
                currentPages.append(page)
                currentChars += pageChars
            }
        }
        
        if !currentPages.isEmpty {
            groups.append(PageGroup(pages: currentPages))
        }
        
        return groups
    }
    
    public func splitGroup(_ group: PageGroup) -> [PageGroup] {
        guard group.pages.count > 1 else {
            return [group]
        }
        
        let mid = group.pages.count / 2
        let first = Array(group.pages[0..<mid])
        let second = Array(group.pages[mid...])
        
        return [PageGroup(pages: first), PageGroup(pages: second)]
    }
}
