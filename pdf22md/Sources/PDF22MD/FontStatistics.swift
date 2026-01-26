// this_file: pdf22md/Sources/PDF22MD/FontStatistics.swift
import Foundation

/// Statistics about font usage in a PDF document
struct FontStatistics {
    let bodySizeThreshold: CGFloat
    let headingSizes: Set<CGFloat>
    let fontSizeFrequencies: [CGFloat: Int]

    /// Analyze font usage from PDF elements to determine heading sizes
    static func analyze(from elements: [PDFElement]) -> FontStatistics {
        var fontSizes: [CGFloat: Int] = [:]
        var totalTextElements = 0

        for element in elements {
            guard let textElement = element as? TextElement else { continue }
            fontSizes[textElement.fontSize, default: 0] += 1
            totalTextElements += 1
        }

        // Sort font sizes by frequency
        let sortedSizes = fontSizes.sorted { $0.value > $1.value }

        // Determine heading sizes (top 3-4 sizes that aren't the most common)
        var headingSizes: Set<CGFloat> = []
        if sortedSizes.count > 1 {
            // Skip the most common size (likely body text)
            for i in 1..<min(4, sortedSizes.count) {
                if sortedSizes[i].value > totalTextElements / 20 { // At least 5% of elements
                    headingSizes.insert(sortedSizes[i].key)
                }
            }
        }

        let bodySize = sortedSizes.first?.key ?? 12.0

        return FontStatistics(
            bodySizeThreshold: bodySize,
            headingSizes: headingSizes,
            fontSizeFrequencies: fontSizes
        )
    }

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