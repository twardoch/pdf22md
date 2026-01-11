import Foundation
import ArgumentParser
import PDF22MD

@main
struct PDF22MDCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22md",
        abstract: "Converts PDF documents to Markdown format (Swift implementation)",
        discussion: """
            EXAMPLES:
              pdf22md -i doc.pdf -o doc.md
                  Convert PDF to Markdown (standard mode with Vision OCR)

              pdf22md -i doc.pdf -o doc.md --fast
                  Fast mode: PDF text only, skip Vision OCR

              pdf22md -i doc.pdf -o doc.md --ai --api gpt-4o:sk-xxx@https://api.openai.com/v1
                  AI-corrected output using OpenAI API

              pdf22md -i doc.pdf -o doc.md -a ./images
                  Extract images to ./images folder

              cat doc.pdf | pdf22md > doc.md
                  Read from stdin, write to stdout

            ENVIRONMENT:
              PDF22MD_API    API config (same format as --api)
            """,
        version: Version.fullVersion
    )

    @Option(name: .shortAndLong, help: "Input PDF file (default: stdin)")
    var input: String?

    @Option(name: .shortAndLong, help: "Output Markdown file (default: stdout)")
    var output: String?

    @Option(name: .shortAndLong, help: "Assets folder for extracted images")
    var assets: String?

    @Option(name: .shortAndLong, help: "DPI for rasterizing vector graphics (default: 144)")
    var dpi: Double = 144.0

    @Flag(name: .long, help: "Use optimized GCD implementation instead of async/await")
    var optimized: Bool = false

    @Flag(name: .long, help: "Use ultra-optimized implementation with NSString")
    var ultraOptimized: Bool = false

    // MARK: - New options for Vision OCR and AI processing

    @Flag(name: .long, help: "Fast mode: use PDF text extraction only, skip Vision OCR")
    var fast: Bool = false

    @Flag(name: .long, help: "Enable AI text correction (uses Apple Intelligence if --api not specified)")
    var ai: Bool = false

    @Option(name: .long, help: "AI API in format model:api_key@base_url (or use PDF22MD_API env)")
    var api: String?

    @Option(name: .long, help: "Languages for Vision OCR (comma-separated ISO 639 codes, default: en)")
    var languages: String = "en"

    @Option(name: .long, help: "Maximum pages to process (default: all)")
    var maxPages: Int?

    @Option(name: .long, help: "Vision text preference threshold (default: 1.5, use Vision if >N times longer)")
    var threshold: Double = 1.5

    @Flag(name: .shortAndLong, help: "Show progress during conversion")
    var verbose: Bool = false

    func run() async throws {
        let inputURL: URL

        if let inputPath = input {
            // Validate input file exists
            guard FileManager.default.fileExists(atPath: inputPath) else {
                throw ValidationError("Input file not found: \(inputPath)")
            }
            inputURL = URL(fileURLWithPath: inputPath)
        } else {
            // Read from stdin into a temporary file
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("pdf")
            let inputData = FileHandle.standardInput.readDataToEndOfFile()
            guard !inputData.isEmpty else {
                throw ValidationError("No input provided. Use -i <file> or pipe PDF to stdin.")
            }
            try inputData.write(to: tempFile)
            inputURL = tempFile
        }

        // Determine if we should use enhanced mode
        let useEnhancedMode = !fast || ai || api != nil

        if useEnhancedMode && !optimized && !ultraOptimized {
            // Use enhanced converter with Vision OCR and optional AI
            let options = try buildProcessingOptions()
            let converter = PDFMarkdownConverter(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                options: options
            )
            try await converter.convertEnhanced()
        } else if ultraOptimized {
            // Legacy ultra-optimized mode
            let converter = PDFMarkdownConverterUltraOptimized(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else if optimized {
            // Legacy optimized mode
            let converter = PDFMarkdownConverterOptimized(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else {
            // Legacy standard mode (fast by default for backward compatibility)
            let converter = PDFMarkdownConverter(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try await converter.convert()
        }

        // Clean temp file if created
        if input == nil {
            try? FileManager.default.removeItem(at: inputURL)
        }
    }

    /// Build ProcessingOptions from CLI arguments
    private func buildProcessingOptions() throws -> ProcessingOptions {
        // Parse API configuration from argument or environment
        var apiConfig: APIConfiguration? = nil

        if let apiString = api {
            apiConfig = try APIConfiguration.parse(apiString)
        } else if let envApi = ProcessInfo.processInfo.environment["PDF22MD_API"] {
            apiConfig = try APIConfiguration.parse(envApi)
        }

        // Parse languages
        let languageList = languages.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        return ProcessingOptions(
            fastMode: fast,
            enableAI: ai,
            dpi: CGFloat(dpi),
            languages: languageList,
            useFastRecognition: false,
            visionPreferenceThreshold: threshold,
            maxPages: maxPages,
            apiConfig: apiConfig,
            verbose: verbose
        )
    }
} 