import Foundation
import PDFKit

/// Ultra-optimized converter using NSString, pre-allocation, and minimal overhead
public final class PDFMarkdownConverterUltraOptimized {
    private let pdfURL: URL
    private let outputPath: String?
    private let assetsPath: String?
    private let dpi: CGFloat
    
    // Pre-allocated buffers
    private let markdownBuffer: NSMutableString
    private var fontCache: [NSString: CGFloat] = [:]
    
    public init(pdfURL: URL, outputPath: String?, assetsPath: String?, dpi: CGFloat = 144.0) {
        self.pdfURL = pdfURL
        self.outputPath = outputPath
        self.assetsPath = assetsPath
        self.dpi = dpi
        // Pre-allocate with large capacity
        self.markdownBuffer = NSMutableString(capacity: 1024 * 1024) // 1MB initial capacity
    }
    
    /// Convert PDF to Markdown with maximum performance
    public func convert() throws {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw PDFConversionError.invalidPDF
        }
        
        let pageCount = pdfDocument.pageCount
        
        // Use simple concurrent queue with limited concurrency
        let queue = DispatchQueue(label: "pdf.ultra", attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: ProcessInfo.processInfo.activeProcessorCount)
        let group = DispatchGroup()
        
        // Pre-allocate result storage
        var pageResults = ContiguousArray<(Int, ContiguousArray<PDFElement>)>()
        pageResults.reserveCapacity(pageCount)
        let lock = NSLock()
        
        // Process pages with controlled concurrency
        for pageIndex in 0..<pageCount {
            group.enter()
            semaphore.wait()
            
            queue.async {
                autoreleasepool {
                    defer {
                        semaphore.signal()
                        group.leave()
                    }
                    
                    guard let page = pdfDocument.page(at: pageIndex) else { return }
                    
                    let processor = PDFPageProcessorUltraOptimized(
                        page: page,
                        pageIndex: pageIndex,
                        dpi: self.dpi,
                        assetsPath: self.assetsPath
                    )
                    
                    let elements = processor.processPage()
                    
                    lock.lock()
                    pageResults.append((pageIndex, elements))
                    lock.unlock()
                }
            }
        }
        
        group.wait()
        
        // Sort by page index using in-place sort
        pageResults.sort { $0.0 < $1.0 }
        
        // Analyze fonts with caching
        analyzeFontsOptimized(pageResults: pageResults)
        
        // Generate markdown directly into buffer
        generateMarkdownOptimized(pageResults: pageResults)
        
        // Write output
        if let outputPath = outputPath {
            try markdownBuffer.write(
                toFile: outputPath,
                atomically: true,
                encoding: String.Encoding.utf8.rawValue
            )
        } else {
            print(markdownBuffer as String)
        }
    }
    
    @inline(__always)
    private func analyzeFontsOptimized(pageResults: ContiguousArray<(Int, ContiguousArray<PDFElement>)>) {
        var fontSizes: [CGFloat: Int] = [:]
        fontSizes.reserveCapacity(20)
        
        var totalTextElements = 0
        
        // Single pass through all elements
        for (_, elements) in pageResults {
            for element in elements {
                if let textElement = element as? TextElement {
                    fontSizes[textElement.fontSize, default: 0] += 1
                    totalTextElements += 1
                    
                    // Cache font info by size
                }
            }
        }
        
        // Quick analysis without sorting
        let threshold = totalTextElements / 20
        for (size, count) in fontSizes where count > threshold {
            // Mark as heading size
            fontCache[NSString(string: "heading_\(size)")] = size
        }
    }
    
    @inline(__always)
    private func generateMarkdownOptimized(pageResults: ContiguousArray<(Int, ContiguousArray<PDFElement>)>) {
        markdownBuffer.setString("")
        
        for (_, elements) in pageResults {
            for element in elements {
                if let textElement = element as? TextElement {
                    // Check if heading using cached info
                    let isHeading = fontCache[NSString(string: "heading_\(textElement.fontSize)")] != nil
                    
                    if isHeading {
                        markdownBuffer.append("## ")
                    }
                    
                    // Direct string append
                    markdownBuffer.append(textElement.text)
                    markdownBuffer.append("\n\n")
                } else if let imageElement = element as? ImageElement {
                    markdownBuffer.append("![Image](")
                    markdownBuffer.append(imageElement.path)
                    markdownBuffer.append(")\n\n")
                }
            }
        }
    }
}

/// Ultra-optimized page processor
final class PDFPageProcessorUltraOptimized {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat
    private let assetsPath: String?
    private var elementBuffer: ContiguousArray<PDFElement>
    
    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0, assetsPath: String? = nil) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
        self.assetsPath = assetsPath
        self.elementBuffer = ContiguousArray<PDFElement>()
        self.elementBuffer.reserveCapacity(500)
    }
    
    @inline(__always)
    func processPage() -> ContiguousArray<PDFElement> {
        elementBuffer.removeAll(keepingCapacity: true)
        
        guard let pageContent = pdfPage.attributedString else { 
            return elementBuffer 
        }
        
        // Process using NSString directly
        let nsString = pageContent.string as NSString
        let length = nsString.length
        var position = 0
        
        while position < length {
            var range = NSRange()
            let attrs = pageContent.attributes(at: position, longestEffectiveRange: &range, in: NSRange(location: 0, length: length))
            
            let text = nsString.substring(with: range)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Extract font info inline
                let font = attrs[.font] as? NSFont
                let element = TextElement(
                    text: text,
                    bounds: CGRect.zero, // Skip bounds calculation for speed
                    pageIndex: pageIndex,
                    fontSize: font?.pointSize ?? 12.0,
                    isBold: false,
                    isItalic: false
                )
                elementBuffer.append(element)
            }
            
            position = NSMaxRange(range)
        }
        
        return elementBuffer
    }
}