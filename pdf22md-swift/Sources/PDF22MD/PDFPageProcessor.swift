import Foundation
import PDFKit
import CoreGraphics

/// Processes individual PDF pages to extract content elements
final class PDFPageProcessor {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat
    
    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
    }
    
    /// Process the page and extract all content elements
    func processPage() -> [PDFElement] {
        var elements: [PDFElement] = []
        
        // Extract text elements
        elements.append(contentsOf: extractTextElements())
        
        // Extract image elements
        elements.append(contentsOf: extractImageElements())
        
        // Extract vector graphics as images
        elements.append(contentsOf: extractVectorGraphics())
        
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
            
            currentPosition = NSMaxRange(effectiveRange)
        }
        
        return textElements
    }
    
    private func getBounds(for range: NSRange) -> CGRect {
        // Get selection bounds for the text range
        if let selection = pdfPage.selection(for: CGRect(x: 0, y: 0, width: 1000, height: 1000)) {
            let bounds = selection.bounds(for: pdfPage)
            return bounds
        }
        return .zero
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
}