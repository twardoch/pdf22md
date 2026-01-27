import Foundation
import CoreGraphics

/// Protocol defining common properties for PDF content elements
protocol PDFElement {
    var bounds: CGRect { get }
    var pageIndex: Int { get }
}

/// Errors that can occur during PDF conversion
enum PDFConversionError: Error, LocalizedError {
    case invalidPDF
    case fileNotFound
    case conversionFailed(String)
    case passwordRequired
    case incorrectPassword

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Invalid or corrupted PDF file"
        case .fileNotFound:
            return "PDF file not found"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        case .passwordRequired:
            return "PDF is encrypted. Use --password to provide the password"
        case .incorrectPassword:
            return "Incorrect password for encrypted PDF"
        }
    }
}

/// Represents a text element extracted from a PDF
struct TextElement: PDFElement {
    let text: String
    let bounds: CGRect
    let pageIndex: Int
    let fontSize: CGFloat
    let isBold: Bool
    let isItalic: Bool
    
    init(text: String, bounds: CGRect, pageIndex: Int, fontSize: CGFloat, isBold: Bool = false, isItalic: Bool = false) {
        self.text = text
        self.bounds = bounds
        self.pageIndex = pageIndex
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
    }
}

/// Represents an image element extracted from a PDF
struct ImageElement: PDFElement {
    let image: CGImage?
    let bounds: CGRect
    let pageIndex: Int
    let isVectorSource: Bool
    let path: String

    init(image: CGImage? = nil, bounds: CGRect, pageIndex: Int, isVectorSource: Bool = false, path: String = "") {
        self.image = image
        self.bounds = bounds
        self.pageIndex = pageIndex
        self.isVectorSource = isVectorSource
        self.path = path
    }
}

// MARK: - Text Extraction Source

/// Indicates the source of extracted text
enum TextExtractionSource {
    case pdfKit       // Fn - Text extracted via PDFKit attributedString
    case vision       // Vn - Text extracted via Vision Framework OCR
    case aiCorrected  // Cn - Text corrected by AI processing
    case combined     // Text from multiple sources combined
}

// MARK: - Page Text Content

/// Contains text content extracted from a single page using multiple methods
struct PageTextContent {
    let pageIndex: Int
    let pdfText: String           // Fn - Always populated from PDFKit
    let visionText: String?       // Vn - From Vision OCR (nil if not extracted or failed)
    let correctedText: String?    // Cn - From AI processing (nil if not processed)
    let selectedSource: TextExtractionSource
    let pdfElements: [PDFElement] // Original PDF elements for font analysis

    /// The best available text based on the selected source
    var bestText: String {
        switch selectedSource {
        case .aiCorrected:
            return correctedText ?? visionText ?? pdfText
        case .vision:
            return visionText ?? pdfText
        case .pdfKit, .combined:
            return pdfText
        }
    }

    init(
        pageIndex: Int,
        pdfText: String,
        visionText: String? = nil,
        correctedText: String? = nil,
        selectedSource: TextExtractionSource = .pdfKit,
        pdfElements: [PDFElement] = []
    ) {
        self.pageIndex = pageIndex
        self.pdfText = pdfText
        self.visionText = visionText
        self.correctedText = correctedText
        self.selectedSource = selectedSource
        self.pdfElements = pdfElements
    }
}

// MARK: - Processing Options

/// Configuration options for PDF processing
public struct ProcessingOptions {
    /// Use fast mode (PDF text only, skip Vision OCR)
    public var fastMode: Bool = false

    /// Enable AI text correction
    public var enableAI: Bool = false

    /// DPI for rendering pages to images
    public var dpi: CGFloat = 144.0

    /// Languages for Vision OCR
    public var languages: [String] = ["en"]

    /// Use fast recognition (lower accuracy, faster)
    public var useFastRecognition: Bool = false

    /// Threshold for preferring Vision text over PDF text (ratio)
    /// If Vision text length > PDF text length * threshold, use Vision
    public var visionPreferenceThreshold: Double = 1.5

    public var apiConfig: APIConfiguration?

    public var apiConfigs: [APIConfiguration?] = []

    public var maxPages: Int?

    /// Show progress output to stderr
    public var showProgress: Bool = false

    /// Enable verbose warning output to stderr
    public var verbose: Bool = false

    /// Password for encrypted PDFs
    public var password: String?

    /// Disable OCR result caching
    public var disableCache: Bool = false

    public var promptTemplate: PromptTemplate?

    public var dryRun: Bool = false

    public static let `default` = ProcessingOptions()
    public static let fast = ProcessingOptions(fastMode: true)

    public init(
        fastMode: Bool = false,
        enableAI: Bool = false,
        dpi: CGFloat = 144.0,
        languages: [String] = ["en"],
        useFastRecognition: Bool = false,
        visionPreferenceThreshold: Double = 1.5,
        maxPages: Int? = nil,
        apiConfig: APIConfiguration? = nil,
        apiConfigs: [APIConfiguration?] = [],
        showProgress: Bool = false,
        verbose: Bool = false,
        password: String? = nil,
        disableCache: Bool = false,
        promptTemplate: PromptTemplate? = nil,
        dryRun: Bool = false
    ) {
        self.fastMode = fastMode
        self.enableAI = enableAI
        self.dpi = dpi
        self.languages = languages
        self.useFastRecognition = useFastRecognition
        self.visionPreferenceThreshold = visionPreferenceThreshold
        self.maxPages = maxPages
        self.apiConfig = apiConfig
        self.apiConfigs = apiConfigs
        self.showProgress = showProgress
        self.verbose = verbose
        self.password = password
        self.disableCache = disableCache
        self.promptTemplate = promptTemplate
        self.dryRun = dryRun
    }
}

/// Configuration for external AI API
public struct APIConfiguration {
    public let model: String
    public let apiKey: String
    public let baseURL: URL

    public init(model: String, apiKey: String, baseURL: URL) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    public static func parseMultiple(_ string: String) throws -> [APIConfiguration?] {
        let apiStrings = string.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
        return try apiStrings.map { apiString in
            if apiString.lowercased() == "system" {
                return nil
            }
            return try parse(apiString)
        }
    }

    public static func parse(_ string: String) throws -> APIConfiguration {
        guard let atIndex = string.lastIndex(of: "@") else {
            throw APIConfigurationError.invalidFormat("Missing '@' separator for base URL")
        }

        let modelAndKey = String(string[..<atIndex])
        let baseURLString = String(string[string.index(after: atIndex)...])

        guard let colonIndex = modelAndKey.firstIndex(of: ":") else {
            throw APIConfigurationError.invalidFormat("Missing ':' separator for API key")
        }

        let model = String(modelAndKey[..<colonIndex])
        let apiKey = String(modelAndKey[modelAndKey.index(after: colonIndex)...])

        guard !model.isEmpty else {
            throw APIConfigurationError.invalidFormat("Model name cannot be empty")
        }

        guard let baseURL = URL(string: baseURLString) else {
            throw APIConfigurationError.invalidFormat("Invalid base URL: \(baseURLString)")
        }

        return APIConfiguration(model: model, apiKey: apiKey, baseURL: baseURL)
    }
}

enum APIConfigurationError: Error, LocalizedError {
    case invalidFormat(String)
    case missingConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid API configuration format: \(message)"
        case .missingConfiguration:
            return "No API configuration provided"
        }
    }
}
