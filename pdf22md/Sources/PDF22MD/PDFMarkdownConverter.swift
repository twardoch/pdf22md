// this_file: pdf22md/Sources/PDF22MD/PDFMarkdownConverter.swift
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
        self.options = ProcessingOptions(fastMode: true, dpi: dpi)
    }

    public init(pdfURL: URL, outputPath: String?, assetsPath: String?, options: ProcessingOptions) {
        self.pdfURL = pdfURL
        self.outputPath = outputPath
        self.assetsPath = assetsPath
        self.dpi = options.dpi
        self.options = options
    }

    // MARK: - PDF Loading

    private func loadPDFDocument() throws -> PDFDocument {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw PDFConversionError.invalidPDF
        }
        if pdfDocument.isLocked {
            guard let password = options.password else {
                throw PDFConversionError.passwordRequired
            }
            guard pdfDocument.unlock(withPassword: password) else {
                throw PDFConversionError.incorrectPassword
            }
        }
        return pdfDocument
    }

    // MARK: - Legacy Conversion (fast mode)

    public func convert() async throws {
        let pdfDocument = try loadPDFDocument()
        let pageCount = pdfDocument.pageCount
        var allElements: [PDFElement] = []

        await withTaskGroup(of: (Int, [PDFElement]).self) { group in
            for pageIndex in 0..<pageCount {
                group.addTask {
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        return (pageIndex, [])
                    }
                    let processor = PDFPageProcessor(
                        page: page, pageIndex: pageIndex,
                        dpi: self.dpi, assetsPath: self.assetsPath
                    )
                    return (pageIndex, processor.processPage())
                }
            }

            var pageElements: [(Int, [PDFElement])] = []
            for await result in group {
                pageElements.append(result)
            }
            pageElements.sort { $0.0 < $1.0 }
            allElements = pageElements.flatMap { $0.1 }
        }

        let fontStats = FontStatistics.analyze(from: allElements)
        let generator = MarkdownGenerator(pdfURL: pdfURL, assetsPath: assetsPath)
        let markdown = generator.generate(from: allElements, fontStats: fontStats)
        try writeOutput(markdown)
    }

    // MARK: - Enhanced Conversion (Vision OCR + AI)

    private func logProgress(_ message: String) {
        guard options.showProgress else { return }
        FileHandle.standardError.write(Data("[pdf22md] \(message)\n".utf8))
    }

    private func logWarning(_ message: String) {
        guard options.verbose else { return }
        FileHandle.standardError.write(Data("[pdf22md] Warning: \(message)\n".utf8))
    }

    public func convertEnhanced() async throws {
        let pdfDocument = try loadPDFDocument()
        let totalPages = pdfDocument.pageCount
        let pageCount = options.maxPages.map { min($0, totalPages) } ?? totalPages
        var pageContents: [PageTextContent] = []
        var allImageElements: [ImageElement] = []
        
        let pdfData = try? Data(contentsOf: pdfURL)

        if let maxPages = options.maxPages, maxPages < totalPages {
            logProgress("Processing \(pageCount) of \(totalPages) page(s) from \(pdfURL.lastPathComponent)")
        } else {
            logProgress("Processing \(pageCount) page(s) from \(pdfURL.lastPathComponent)")
        }
        let modeDesc = options.fastMode ? "fast (PDF only)" : "standard (PDF + Vision OCR)"
        logProgress("Mode: \(modeDesc)")

        logProgress("Phase 1: Extracting text...")
        var completedPages = 0
        var visionPagesCount = 0
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
                        options: self.options,
                        pdfData: pdfData
                    )
                    return await processor.processPageEnhanced()
                }
            }

            var results: [PDFPageProcessor.EnhancedPageResult] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                    completedPages += 1
                    
                    let usedVision = result.visionText != nil && !result.visionText!.isEmpty
                    if usedVision {
                        visionPagesCount += 1
                    }
                    
                    if self.options.showProgress {
                        let visionIndicator = usedVision ? " (Vision OCR)" : ""
                        FileHandle.standardError.write(Data("[pdf22md] Extracted page \(completedPages)/\(pageCount)\(visionIndicator)\n".utf8))
                    }
                }
            }
            return results.sorted { $0.pageIndex < $1.pageIndex }
        }

        for result in extractionResults {
            let content = PDFPageProcessor.createPageContent(from: result, options: options)
            pageContents.append(content)
            allImageElements.append(contentsOf: result.imageElements)
        }
        
        if visionPagesCount > 0 {
            logProgress("Extraction complete: \(pageContents.count) pages (\(visionPagesCount) with Vision OCR)")
        } else {
            logProgress("Extraction complete: \(pageContents.count) pages")
        }

        // Phase 2: AI processing (sequential, sliding window)
        var finalTexts: [String] = []

        if options.enableAI, let apiConfig = options.apiConfig {
            logProgress("Phase 2: AI correction using \(apiConfig.model)...")
            let aiProcessor = AITextProcessor(apiConfig: apiConfig, promptTemplate: options.promptTemplate)
            finalTexts = try await aiProcessor.processPages(pageContents) { completed, total in
                if self.options.showProgress {
                    FileHandle.standardError.write(Data("[pdf22md] AI processing page \(completed)/\(total)...\n".utf8))
                }
            }
            logProgress("AI correction complete")
        } else if options.enableAI {
            logProgress("Phase 2: AI correction using Apple Intelligence...")
            do {
                let template = options.promptTemplate ?? .default
                let aiProcessor = AITextProcessor(provider: .appleIntelligence, promptTemplate: template)
                finalTexts = try await aiProcessor.processPages(pageContents) { completed, total in
                    if self.options.showProgress {
                        FileHandle.standardError.write(Data("[pdf22md] AI processing page \(completed)/\(total)...\n".utf8))
                    }
                }
                logProgress("AI correction complete")
            } catch AIProcessingError.appleIntelligenceUnavailable {
                logWarning("Apple Intelligence unavailable, using extracted text")
                finalTexts = pageContents.map { $0.bestText }
            }
        } else {
            // No AI: use best available text (PDF or Vision)
            finalTexts = pageContents.map { $0.bestText }
        }

        // Phase 3: Generate Markdown
        logProgress("Phase 3: Generating Markdown...")
        let generator = MarkdownGenerator(pdfURL: pdfURL, assetsPath: assetsPath)
        let markdown = generator.generateEnhanced(texts: finalTexts, imageElements: allImageElements)

        try writeOutput(markdown)
        logProgress("Done!")
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
