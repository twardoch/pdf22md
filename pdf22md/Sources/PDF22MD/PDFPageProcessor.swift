import Foundation
import PDFKit
import CoreGraphics
import Vision

/// Processes individual PDF pages to extract content elements
final class PDFPageProcessor {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat
    private let assetsPath: String?
    private let options: ProcessingOptions

    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0, assetsPath: String? = nil, options: ProcessingOptions = .default) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
        self.assetsPath = assetsPath
        self.options = options
    }

    // MARK: - Legacy API (backward compatible)

    /// Process the page and extract all content elements (legacy method)
    func processPage() -> [PDFElement] {
        var elements: [PDFElement] = []
        
        // Extract text elements
        elements.append(contentsOf: extractTextElements())
        
        // Only extract images if assets path is provided
        if assetsPath != nil {
            // Extract image elements
            elements.append(contentsOf: CGPDFImageExtractor.extractImages(from: pdfPage,
                                                                          pageIndex: pageIndex,
                                                                          dpi: dpi))
            
            // Extract vector graphics as images
            elements.append(contentsOf: extractVectorGraphics())
        }
        
        return elements
    }
    
    private func extractTextElements() -> [TextElement] {
        var textElements: [TextElement] = []
        
        guard let pageContent = pdfPage.attributedString else { return textElements }
        
        let fullRange = NSRange(location: 0, length: pageContent.length)
        var currentPosition = 0
        
        while currentPosition < pageContent.length {
            var effectiveRange = NSRange()
            let attributes = pageContent.attributes(at: currentPosition, 
                                                   longestEffectiveRange: &effectiveRange, 
                                                   in: fullRange)
            
            let text = (pageContent.string as NSString).substring(with: effectiveRange)
            
            // Skip whitespace-only text
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Extract font information
                let font = attributes[.font] as? NSFont
                let fontSize = font?.pointSize ?? 12.0
                
                // Determine style
                let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
                let isItalic = font?.fontDescriptor.symbolicTraits.contains(.italic) ?? false
                
                // Get bounds for the text
                let bounds = getBounds(for: effectiveRange)
                
                let element = TextElement(
                    text: trimmed,
                    bounds: bounds,
                    pageIndex: pageIndex,
                    fontSize: fontSize,
                    isBold: isBold,
                    isItalic: isItalic
                )
                textElements.append(element)
            }
            
            // Prevent infinite loop: ensure we always advance
            let nextPosition = NSMaxRange(effectiveRange)
            if nextPosition <= currentPosition {
                // Safety: advance by at least 1 if range didn't advance
                currentPosition += 1
            } else {
                currentPosition = nextPosition
            }
        }
        
        return textElements
    }
    
    private func getBounds(for range: NSRange) -> CGRect {
        guard range.location != NSNotFound, range.length > 0 else {
            return .zero
        }
        
        // Use characterBounds which is much more efficient than creating selections.
        // We union the bounds of the first and last character for a good approximation.
        let startBounds = pdfPage.characterBounds(at: range.location)
        let endBounds = pdfPage.characterBounds(at: NSMaxRange(range) - 1)
        
        return startBounds.union(endBounds)
    }
    
    private func extractImageElements() -> [ImageElement] {
        // For now, we'll focus on vector graphics extraction
        // Direct image extraction from PDF streams requires more complex parsing
        return []
    }
    
    
    private func extractVectorGraphics() -> [ImageElement] {
        var elements: [ImageElement] = []
        
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let sectionSize: CGFloat = 100.0 // 100 point sections
        
        let gridX = Int(ceil(pageRect.size.width / sectionSize))
        let gridY = Int(ceil(pageRect.size.height / sectionSize))
        
        for x in 0..<gridX {
            for y in 0..<gridY {
                var sectionRect = CGRect(
                    x: CGFloat(x) * sectionSize,
                    y: CGFloat(y) * sectionSize,
                    width: sectionSize,
                    height: sectionSize
                )
                
                // Intersect with page bounds
                sectionRect = sectionRect.intersection(pageRect)
                if sectionRect.isEmpty || sectionRect.size.width < 20 || sectionRect.size.height < 20 {
                    continue
                }
                
                // Check if this section contains primarily image content
                if sectionContainsImageContent(sectionRect) {
                    if let sectionImage = renderPageSection(sectionRect) {
                        let element = ImageElement(
                            image: sectionImage,
                            bounds: sectionRect,
                            pageIndex: pageIndex,
                            isVectorSource: true
                        )
                        elements.append(element)
                    }
                }
            }
        }
        
        return elements
    }
    
    private func sectionContainsImageContent(_ rect: CGRect) -> Bool {
        // Check if the section has minimal text
        guard let selection = pdfPage.selection(for: rect) else { return true }
        let text = selection.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // If section has very little text, consider it as potential image area
        return text.count < 10
    }
    
    private func renderPageSection(_ rect: CGRect) -> CGImage? {
        let scale = dpi / 72.0
        let scaledSize = CGSize(width: rect.size.width * scale, 
                               height: rect.size.height * scale)
        
        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        // Fill with white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: scaledSize))
        
        // Set up coordinate system
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -rect.origin.x, y: -rect.origin.y)
        
        // Draw the PDF page section
        pdfPage.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    // MARK: - Enhanced API (with Vision OCR support)

    /// Result from enhanced page processing
    struct EnhancedPageResult {
        let pageIndex: Int
        let pdfElements: [PDFElement]
        let pdfText: String
        let visionText: String?
        let imageElements: [ImageElement]
    }

    /// Process the page with both PDF and Vision extraction
    /// - Returns: Enhanced result containing both extraction methods
    func processPageEnhanced() async -> EnhancedPageResult {
        // Extract PDF elements (always)
        let textElements = extractTextElements()
        let pdfText = textElements.map { $0.text }.joined(separator: "\n")

        // Extract images if assets path provided
        var imageElements: [ImageElement] = []
        if assetsPath != nil {
            imageElements.append(contentsOf: CGPDFImageExtractor.extractImages(
                from: pdfPage,
                pageIndex: pageIndex,
                dpi: dpi
            ))
            imageElements.append(contentsOf: extractVectorGraphics())
        }

        // Extract Vision text if not in fast mode
        var visionText: String? = nil
        if !options.fastMode {
            visionText = await extractVisionText()
        }

        return EnhancedPageResult(
            pageIndex: pageIndex,
            pdfElements: textElements,
            pdfText: pdfText,
            visionText: visionText,
            imageElements: imageElements
        )
    }

    /// Extract text using Vision OCR
    /// - Returns: Concatenated OCR text or nil if extraction fails
    private func extractVisionText() async -> String? {
        let config = VisionTextExtractor.Configuration(
            languages: options.languages,
            useFastRecognition: options.useFastRecognition
        )
        let extractor = VisionTextExtractor(configuration: config)

        do {
            return try await extractor.extractTextAsString(from: pdfPage, dpi: dpi)
        } catch {
            // Vision extraction failed, return nil (graceful degradation)
            return nil
        }
    }

    /// Render entire page to CGImage for Vision OCR
    func renderPageToImage() -> CGImage? {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scale = dpi / 72.0

        let width = Int(pageRect.size.width * scale)
        let height = Int(pageRect.size.height * scale)

        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        // Fill with white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Scale and draw
        context.scaleBy(x: scale, y: scale)
        pdfPage.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    /// Create PageTextContent from enhanced result with automatic text selection
    static func createPageContent(
        from result: EnhancedPageResult,
        options: ProcessingOptions
    ) -> PageTextContent {
        let (_, source) = AITextProcessor.selectBestText(
            pdfText: result.pdfText,
            visionText: result.visionText,
            threshold: options.visionPreferenceThreshold
        )

        return PageTextContent(
            pageIndex: result.pageIndex,
            pdfText: result.pdfText,
            visionText: result.visionText,
            correctedText: nil,  // Set later by AI processing
            selectedSource: source,
            pdfElements: result.pdfElements
        )
    }
}