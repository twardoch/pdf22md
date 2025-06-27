import Foundation
import PDFKit

/// Main converter class that orchestrates PDF to Markdown conversion
public final class PDFMarkdownConverter {
    private let pdfURL: URL
    private let outputPath: String?
    private let assetsPath: String?
    private let dpi: CGFloat
    
    public init(pdfURL: URL, outputPath: String?, assetsPath: String?, dpi: CGFloat = 144.0) {
        self.pdfURL = pdfURL
        self.outputPath = outputPath
        self.assetsPath = assetsPath
        self.dpi = dpi
    }
    
    /// Convert PDF to Markdown
    public func convert() async throws {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw PDFConversionError.invalidPDF
        }
        
        let pageCount = pdfDocument.pageCount
        var allElements: [PDFElement] = []
        
        // Process pages concurrently
        await withTaskGroup(of: (Int, [PDFElement]).self) { group in
            for pageIndex in 0..<pageCount {
                group.addTask {
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        return (pageIndex, [])
                    }
                    
                    let processor = PDFPageProcessor(page: page, pageIndex: pageIndex, dpi: self.dpi, assetsPath: self.assetsPath)
                    let elements = processor.processPage()
                    return (pageIndex, elements)
                }
            }
            
            // Collect results in order
            var pageElements: [(Int, [PDFElement])] = []
            for await result in group {
                pageElements.append(result)
            }
            
            // Sort by page index and flatten
            pageElements.sort { $0.0 < $1.0 }
            allElements = pageElements.flatMap { $0.1 }
        }
        
        // Analyze fonts for heading detection
        let fontStats = analyzeFonts(from: allElements)
        
        // Generate markdown
        let markdown = generateMarkdown(from: allElements, fontStats: fontStats)
        
        // Write output
        if let outputPath = outputPath {
            // Ensure parent directory exists
            let outputURL = URL(fileURLWithPath: outputPath)
            let directoryURL = outputURL.deletingLastPathComponent()
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            // Attempt to write the file and throw a descriptive error on failure
            do {
                try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
            } catch {
                throw PDFConversionError.invalidPDF // reuse existing error, ideally define new but keep simple
            }
        } else {
            print(markdown)
        }
    }
    
    private func analyzeFonts(from elements: [PDFElement]) -> FontStatistics {
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
    
    private func generateMarkdown(from elements: [PDFElement], fontStats: FontStatistics) -> String {
        var markdown = ""
        
        // Extract PDF basename for asset naming
        let pdfBasename = pdfURL.deletingPathExtension().lastPathComponent
        let assetExtractor = AssetExtractor(assetsPath: assetsPath, pdfBasename: pdfBasename)
        
        // Sort elements by page and vertical position
        let sortedElements = elements.sorted { lhs, rhs in
            if lhs.pageIndex != rhs.pageIndex {
                return lhs.pageIndex < rhs.pageIndex
            }
            // Sort top to bottom (flip Y coordinate)
            return lhs.bounds.origin.y > rhs.bounds.origin.y
        }
        
        var previousElement: PDFElement?
        
        for element in sortedElements {
            // Add page breaks
            if let prev = previousElement, prev.pageIndex != element.pageIndex {
                markdown += "\n---\n\n"
            }
            
            switch element {
            case let textElement as TextElement:
                let headingLevel = fontStats.headingLevel(for: textElement.fontSize)
                
                if headingLevel > 0 {
                    markdown += String(repeating: "#", count: headingLevel) + " "
                }
                
                var text = textElement.text
                
                // Apply formatting
                if textElement.isBold && textElement.isItalic {
                    text = "***\(text)***"
                } else if textElement.isBold {
                    text = "**\(text)**"
                } else if textElement.isItalic {
                    text = "*\(text)*"
                }
                
                markdown += text
                
                // Add appropriate spacing
                if headingLevel > 0 {
                    markdown += "\n\n"
                } else {
                    // Check if next element is on a new line
                    if let prev = previousElement as? TextElement,
                       abs(prev.bounds.origin.y - textElement.bounds.origin.y) > 5 {
                        markdown += "\n\n"
                    } else {
                        markdown += " "
                    }
                }
                
            case let imageElement as ImageElement:
                if let image = imageElement.image,
                   let imagePath = assetExtractor.saveImage(image, 
                                                           pageIndex: imageElement.pageIndex,
                                                           isVector: imageElement.isVectorSource) {
                    let altText = imageElement.isVectorSource ? "Vector graphic" : "Image"
                    markdown += "![\(altText)](\(imagePath))\n\n"
                }
                
            default:
                break
            }
            
            previousElement = element
        }
        
        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}