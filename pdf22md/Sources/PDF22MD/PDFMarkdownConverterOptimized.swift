// this_file: pdf22md/Sources/PDF22MD/PDFMarkdownConverterOptimized.swift
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

                    let processor = PDFPageProcessorOptimized(
                        page: page, pageIndex: pageIndex,
                        dpi: self.dpi, assetsPath: self.assetsPath
                    )
                    let elements = processor.processPage()

                    lock.lock()
                    pageResults.append((pageIndex, elements))
                    lock.unlock()

                    group.leave()
                }
            }
        }

        group.wait()
        pageResults.sort { $0.0 < $1.0 }
        let allElements = pageResults.flatMap { $0.1 }

        // Use shared components
        let fontStats = FontStatistics.analyze(from: allElements)
        let generator = MarkdownGenerator(pdfURL: pdfURL, assetsPath: assetsPath)
        let markdown = generator.generate(from: allElements, fontStats: fontStats)

        try writeOutput(markdown)
    }

    private func writeOutput(_ markdown: String) throws {
        if let outputPath = outputPath {
            let outputURL = URL(fileURLWithPath: outputPath)
            let directoryURL = outputURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }
            try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
        } else {
            print(markdown)
        }
    }
}
