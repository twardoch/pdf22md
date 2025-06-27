import Foundation
import PDFKit
import CoreGraphics

/// Optimized PDF page processor using NSString and other performance improvements
final class PDFPageProcessorOptimized {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat
    
    // Pre-allocated buffers
    private var elementBuffer: ContiguousArray<PDFElement>
    
    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
        // Pre-allocate with estimated capacity
        self.elementBuffer = ContiguousArray<PDFElement>()
        self.elementBuffer.reserveCapacity(1000)
    }
    
    /// Process the page and extract all content elements
    @inline(__always)
    func processPage() -> [PDFElement] {
        elementBuffer.removeAll(keepingCapacity: true)
        
        // Extract text elements
        extractTextElements()
        
        // Extract image elements
        extractImageElements()
        
        // Extract vector graphics as images
        extractVectorGraphics()
        
        return Array(elementBuffer)
    }
    
    @inline(__always)
    private func extractTextElements() {
        guard let pageContent = pdfPage.attributedString else { return }
        
        // Use NSString for better performance
        let nsString = pageContent.string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        var currentPosition = 0
        
        // Pre-allocate whitespace character set
        let whitespaceSet = CharacterSet.whitespacesAndNewlines
        
        while currentPosition < nsString.length {
            var effectiveRange = NSRange()
            let attributes = pageContent.attributes(at: currentPosition, 
                                                   longestEffectiveRange: &effectiveRange, 
                                                   in: fullRange)
            
            // Use NSString substring for better performance
            let text = nsString.substring(with: effectiveRange)
            
            // Skip whitespace-only text using NSString
            let trimmed = (text as NSString).trimmingCharacters(in: whitespaceSet)
            if trimmed.isEmpty {
                currentPosition = NSMaxRange(effectiveRange)
                continue
            }
            
            // Extract font information using cached values
            var fontSize: CGFloat = 12.0
            // The font name can be derived from the descriptor if needed. Omit unused placeholder to silence warnings.
            var isBold = false
            var isItalic = false
            
            if let font = attributes[.font] as? NSFont {
                fontSize = font.pointSize
                
                // Use font traits for better performance
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.bold)
                isItalic = traits.contains(.italic)
            }
            
            // Get bounds - optimize by using page bounds directly
            let bounds: CGRect
            if let pdfBounds = pdfPage.selection(for: effectiveRange)?.bounds(for: pdfPage) {
                bounds = pdfBounds
            } else {
                bounds = CGRect(x: 0, y: CGFloat(currentPosition) * 20, width: 100, height: fontSize)
            }
            
            // Create element and add to buffer
            let element = TextElement(
                text: trimmed,
                bounds: bounds,
                pageIndex: pageIndex,
                fontSize: fontSize,
                isBold: isBold,
                isItalic: isItalic
            )
            
            elementBuffer.append(element)
            currentPosition = NSMaxRange(effectiveRange)
        }
    }
    
    @inline(__always)
    private func extractImageElements() {
        let imgs = CGPDFImageExtractor.extractImages(from: pdfPage,
                                                     pageIndex: pageIndex,
                                                     dpi: dpi)
        elementBuffer.append(contentsOf: imgs)
    }
    
    @inline(__always)
    private func extractVectorGraphics() {
        // Implementation remains similar but uses elementBuffer.append directly
        // This is a placeholder - would need full implementation
    }
}

// Use the existing TextElement struct, no need to redefine