import Foundation

/// Statistics about font usage in a PDF document
struct FontStatistics {
    let bodySizeThreshold: CGFloat
    let headingSizes: Set<CGFloat>
    let fontSizeFrequencies: [CGFloat: Int]
    
    func headingLevel(for fontSize: CGFloat) -> Int {
        guard headingSizes.contains(fontSize) else { return 0 }
        
        // Sort heading sizes from largest to smallest
        let sortedHeadingSizes = headingSizes.sorted(by: >)
        
        // Return heading level based on size order
        if let index = sortedHeadingSizes.firstIndex(of: fontSize) {
            return min(index + 1, 6) // H1-H6
        }
        
        return 0
    }
}