import Foundation
import PDFKit

/// Main converter class that orchestrates PDF to Markdown conversion
public final class PDFMarkdownConverter {
    private let pdfURL: URL
    private let outputPath: String?
    private let assetsPath: String?
    private let dpi: CGFloat
    private let options: ProcessingOptions

    public init(pdfURL: URL, outputPath: String?, assetsPath: String?, dpi: CGFloat = 144.0) {
        self.pdfURL = pdfURL
        self.outputPath = outputPath
        self.assetsPath = assetsPath
        self.dpi = dpi
        self.options = ProcessingOptions(fastMode: true, dpi: dpi)  // Legacy: fast mode
    }

    public init(pdfURL: URL, outputPath: String?, assetsPath: String?, options: ProcessingOptions) {
        self.pdfURL = pdfURL
        self.outputPath = outputPath
        self.assetsPath = assetsPath
        self.dpi = options.dpi
        self.options = options
    }

    // MARK: - Legacy Conversion (fast mode, PDF-only)

    /// Convert PDF to Markdown (legacy method, fast mode)
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

    // MARK: - Enhanced Conversion (with Vision and AI)

    /// Convert PDF to Markdown with enhanced processing (Vision OCR + optional AI)
    public func convertEnhanced() async throws {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw PDFConversionError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount
        var pageContents: [PageTextContent] = []
        var allImageElements: [ImageElement] = []
        var allPdfElements: [PDFElement] = []

        // Phase 1: Extract text from all pages (parallel)
        let extractionResults = await withTaskGroup(of: PDFPageProcessor.EnhancedPageResult?.self) { group in
            for pageIndex in 0..<pageCount {
                group.addTask {
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        return nil
                    }

                    let processor = PDFPageProcessor(
                        page: page,
                        pageIndex: pageIndex,
                        dpi: self.dpi,
                        assetsPath: self.assetsPath,
                        options: self.options
                    )
                    return await processor.processPageEnhanced()
                }
            }

            var results: [PDFPageProcessor.EnhancedPageResult] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            return results.sorted { $0.pageIndex < $1.pageIndex }
        }

        // Convert extraction results to PageTextContent
        for result in extractionResults {
            let content = PDFPageProcessor.createPageContent(from: result, options: options)
            pageContents.append(content)
            allImageElements.append(contentsOf: result.imageElements)
            allPdfElements.append(contentsOf: result.pdfElements)
        }

        // Phase 2: AI processing (sequential, sliding window)
        var finalTexts: [String] = []

        if options.enableAI, let apiConfig = options.apiConfig {
            // Use external AI API
            let aiProcessor = AITextProcessor(apiConfig: apiConfig)
            finalTexts = try await aiProcessor.processPages(pageContents)
        } else if options.enableAI {
            // Try Apple Intelligence (will fail if unavailable, then fall back)
            do {
                let aiProcessor = AITextProcessor(provider: .appleIntelligence)
                finalTexts = try await aiProcessor.processPages(pageContents)
            } catch AIProcessingError.appleIntelligenceUnavailable {
                // Fall back to best available text
                finalTexts = pageContents.map { $0.bestText }
            }
        } else {
            // No AI: use best available text (PDF or Vision)
            finalTexts = pageContents.map { $0.bestText }
        }

        // Phase 3: Generate Markdown
        let markdown = generateEnhancedMarkdown(
            texts: finalTexts,
            imageElements: allImageElements,
            pdfElements: allPdfElements
        )

        // Write output
        try writeOutput(markdown)
    }

    /// Generate Markdown from enhanced extraction results
    private func generateEnhancedMarkdown(
        texts: [String],
        imageElements: [ImageElement],
        pdfElements: [PDFElement]
    ) -> String {
        var markdown = ""

        // Extract PDF basename for asset naming
        let pdfBasename = pdfURL.deletingPathExtension().lastPathComponent
        let assetExtractor = AssetExtractor(assetsPath: assetsPath, pdfBasename: pdfBasename)

        // Group images by page
        var imagesByPage: [Int: [ImageElement]] = [:]
        for image in imageElements {
            imagesByPage[image.pageIndex, default: []].append(image)
        }

        // Generate markdown for each page
        for (index, text) in texts.enumerated() {
            if index > 0 {
                markdown += "\n\n---\n\n"
            }

            // Add text content
            markdown += text

            // Add images for this page
            if let pageImages = imagesByPage[index] {
                for imageElement in pageImages {
                    if let image = imageElement.image,
                       let imagePath = assetExtractor.saveImage(
                           image,
                           pageIndex: imageElement.pageIndex,
                           isVector: imageElement.isVectorSource
                       ) {
                        let altText = imageElement.isVectorSource ? "Vector graphic" : "Image"
                        markdown += "\n\n![\(altText)](\(imagePath))"
                    }
                }
            }
        }

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Write markdown to output file or stdout
    private func writeOutput(_ markdown: String) throws {
        if let outputPath = outputPath {
            let outputURL = URL(fileURLWithPath: outputPath)
            let directoryURL = outputURL.deletingLastPathComponent()
            let fileManager = FileManager.default

            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
        } else {
            print(markdown)
        }
    }
}