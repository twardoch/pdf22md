import Foundation
import PDFKit

/// Optimized converter using GCD instead of async/await for better performance
public final class PDFMarkdownConverterOptimized {
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
    
    /// Convert PDF to Markdown using GCD for better performance
    public func convert() throws {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw PDFConversionError.invalidPDF
        }
        
        let pageCount = pdfDocument.pageCount
        let queue = DispatchQueue(label: "pdf.processing", attributes: .concurrent)
        let group = DispatchGroup()
        
        // Thread-safe storage for results
        let lock = NSLock()
        var pageResults: [(Int, [PDFElement])] = []
        
        // Process pages concurrently using GCD
        for pageIndex in 0..<pageCount {
            group.enter()
            queue.async {
                autoreleasepool {
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        group.leave()
                        return
                    }
                    
                    let processor = PDFPageProcessorOptimized(page: page, pageIndex: pageIndex, dpi: self.dpi, assetsPath: self.assetsPath)
                    let elements = processor.processPage()
                    
                    // Thread-safe append
                    lock.lock()
                    pageResults.append((pageIndex, elements))
                    lock.unlock()
                    
                    group.leave()
                }
            }
        }
        
        // Wait for all pages to complete
        group.wait()
        
        // Sort by page index
        pageResults.sort { $0.0 < $1.0 }
        let allElements = pageResults.flatMap { $0.1 }
        
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
            do {
                try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
            } catch {
                throw PDFConversionError.invalidPDF
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
        let markdown = NSMutableString()
        
        // Extract PDF basename for asset naming
        let pdfBasename = pdfURL.deletingPathExtension().lastPathComponent
        let assetExtractor = AssetExtractor(assetsPath: assetsPath, pdfBasename: pdfBasename)
        var previousElement: PDFElement?
        
        for element in elements {
            switch element {
            case let textElement as TextElement:
                let headingLevel = fontStats.headingLevel(for: textElement.fontSize)
                
                if headingLevel > 0 {
                    // Add heading
                    let prefix = String(repeating: "#", count: headingLevel)
                    markdown.append("\(prefix) \(textElement.text)\n\n")
                } else {
                    // Regular text
                    if textElement.isBold && textElement.isItalic {
                        markdown.append("***\(textElement.text)***")
                    } else if textElement.isBold {
                        markdown.append("**\(textElement.text)**")
                    } else if textElement.isItalic {
                        markdown.append("*\(textElement.text)*")
                    } else {
                        markdown.append(textElement.text)
                    }
                    
                    // Check if we need a line break
                    if shouldAddLineBreak(current: element, previous: previousElement) {
                        markdown.append("\n\n")
                    } else {
                        markdown.append(" ")
                    }
                }
                
            case let imageElement as ImageElement:
                if let image = imageElement.image,
                   let imagePath = assetExtractor.saveImage(image, 
                                                           pageIndex: imageElement.pageIndex,
                                                           isVector: imageElement.isVectorSource) {
                    let altText = imageElement.isVectorSource ? "Vector graphic" : "Image"
                    markdown.append("![\(altText)](\(imagePath))\n\n")
                }
                
            default:
                break
            }
            
            previousElement = element
        }
        
        return (markdown as String).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func shouldAddLineBreak(current: PDFElement, previous: PDFElement?) -> Bool {
        guard let prev = previous else { return true }
        
        // Check vertical distance
        let verticalGap = abs(current.bounds.minY - prev.bounds.minY)
        return verticalGap > 20
    }
}