// this_file: pdf22md/Sources/PDF22MD/FontStatistics.swift
import Foundation

/// Statistics about font usage in a PDF document
struct FontStatistics {
    let bodySizeThreshold: CGFloat
    let headingSizes: Set<CGFloat>
    let fontSizeFrequencies: [CGFloat: Int]

    /// Analyze font usage from PDF elements to determine heading sizes.
    ///
    /// Heading detection is frequency- and rank-based, not absolute-size based:
    /// distinct font sizes are ranked by how many text runs use them. The single
    /// most common size is assumed to be body text and is skipped. The next three
    /// most common sizes each become a heading size *only if* they cover at least
    /// 5% of text runs (rare one-off sizes are ignored as noise). `headingLevel(for:)`
    /// then maps those retained sizes to `#`…`######` by descending point size.
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

    /// Map a font size to a Markdown heading level (1 = `#`, 6 = `######`).
    ///
    /// Returns 0 (body text, no heading) unless `fontSize` was retained as a
    /// heading size by `analyze`. Levels are assigned by descending point size:
    /// the largest retained size is `#`, the next-largest `##`, and so on, capped
    /// at H6. So the delta that separates `#` from `##` is purely ordinal — the
    /// relative rank of the sizes, not any fixed point difference between them.
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