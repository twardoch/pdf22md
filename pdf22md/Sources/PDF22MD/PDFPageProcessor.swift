// this_file: pdf22md/Sources/PDF22MD/PDFPageProcessor.swift
import Foundation
import PDFKit

/// Processes individual PDF pages to extract content elements
final class PDFPageProcessor {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat
    private let assetsPath: String?
    private let options: ProcessingOptions
    private let pdfData: Data?

    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0, assetsPath: String? = nil, options: ProcessingOptions = .default, pdfData: Data? = nil) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
        self.assetsPath = assetsPath
        self.options = options
        self.pdfData = pdfData
    }

    // MARK: - Legacy API

    func processPage() -> [PDFElement] {
        var elements: [PDFElement] = []
        elements.append(contentsOf: TextExtractor(page: pdfPage, pageIndex: pageIndex).extractElements())

        if assetsPath != nil {
            elements.append(contentsOf: CGPDFImageExtractor.extractImages(from: pdfPage, pageIndex: pageIndex, dpi: dpi))
            elements.append(contentsOf: VectorGraphicsExtractor(page: pdfPage, pageIndex: pageIndex, dpi: dpi).extractElements())
        }

        return elements
    }

    // MARK: - Enhanced API (Vision OCR)

    struct EnhancedPageResult {
        let pageIndex: Int
        let pdfElements: [PDFElement]
        let pdfText: String
        let visionText: String?
        let imageElements: [ImageElement]
    }

    func processPageEnhanced() async -> EnhancedPageResult {
        let textElements = TextExtractor(page: pdfPage, pageIndex: pageIndex).extractElements()
        let pdfText = textElements.map { $0.text }.joined(separator: "\n")

        var imageElements: [ImageElement] = []
        if assetsPath != nil {
            imageElements.append(contentsOf: CGPDFImageExtractor.extractImages(from: pdfPage, pageIndex: pageIndex, dpi: dpi))
            imageElements.append(contentsOf: VectorGraphicsExtractor(page: pdfPage, pageIndex: pageIndex, dpi: dpi).extractElements())
        }

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

    private func extractVisionText() async -> String? {
        var config = VisionTextExtractor.Configuration(
            languages: options.languages,
            useFastRecognition: options.useFastRecognition
        )
        config.useCache = !options.disableCache
        config.dpi = dpi
        let extractor = VisionTextExtractor(configuration: config)
        
        guard let cacheKeyData = pdfData else {
            return try? await extractor.extractTextAsString(from: pdfPage, dpi: dpi)
        }
        let results = try? await extractor.extractText(from: pdfPage, dpi: dpi, pdfData: cacheKeyData, pageIndex: pageIndex)
        return results?.map { $0.text }.joined(separator: "\n")
    }

    static func createPageContent(from result: EnhancedPageResult, options: ProcessingOptions) -> PageTextContent {
        let (_, source) = AITextProcessor.selectBestText(
            pdfText: result.pdfText,
            visionText: result.visionText,
            threshold: options.visionPreferenceThreshold
        )

        return PageTextContent(
            pageIndex: result.pageIndex,
            pdfText: result.pdfText,
            visionText: result.visionText,
            correctedText: nil,
            selectedSource: source,
            pdfElements: result.pdfElements
        )
    }
}
