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

              pdf22md -i doc.pdf -o doc.md --max-pages 3
                  Process only first 3 pages (useful for previewing)

              pdf22md -i doc.pdf -o doc.md --ai --api gpt-4o:sk-xxx@https://api.openai.com/v1
                  AI-corrected output using OpenAI API

              pdf22md -i doc.pdf -o doc.md -a ./images
                  Extract images to ./images folder

              pdf22md -i doc.pdf -o doc.md --password secret123
                  Convert password-protected PDF

              pdf22md -i ./pdfs --batch -o ./output -v
                  Batch convert all PDFs in directory

              cat doc.pdf | pdf22md > doc.md
                  Read from stdin, write to stdout

            ENVIRONMENT:
              PDF22MD_API    API config (same format as --api)
            """,
        version: Version.fullVersion
    )

    @Option(name: .shortAndLong, help: "Input PDF file or directory (default: stdin)")
    var input: String?

    @Option(name: .shortAndLong, help: "Output Markdown file or directory (default: stdout)")
    var output: String?

    @Option(name: .shortAndLong, help: "Assets folder for extracted images")
    var assets: String?

    @Flag(name: .long, help: "Process all PDF files in input directory (batch mode)")
    var batch: Bool = false

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

    @Option(name: .long, help: "Password for encrypted PDF files")
    var password: String?

    @Flag(name: .shortAndLong, help: "Show progress during conversion")
    var verbose: Bool = false

    func run() async throws {
        // Check for batch mode
        if batch {
            try await runBatch()
            return
        }

        // Single file mode
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

        try await processSinglePDF(inputURL: inputURL, outputPath: output)

        // Clean temp file if created
        if input == nil {
            try? FileManager.default.removeItem(at: inputURL)
        }
    }

    /// Process a single PDF file
    private func processSinglePDF(inputURL: URL, outputPath: String?) async throws {
        // Determine if we should use enhanced mode
        let useEnhancedMode = !fast || ai || api != nil

        if useEnhancedMode && !optimized && !ultraOptimized {
            // Use enhanced converter with Vision OCR and optional AI
            let options = try buildProcessingOptions()
            let converter = PDFMarkdownConverter(
                pdfURL: inputURL,
                outputPath: outputPath,
                assetsPath: assets,
                options: options
            )
            try await converter.convertEnhanced()
        } else if ultraOptimized {
            // Legacy ultra-optimized mode
            let converter = PDFMarkdownConverterUltraOptimized(
                pdfURL: inputURL,
                outputPath: outputPath,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else if optimized {
            // Legacy optimized mode
            let converter = PDFMarkdownConverterOptimized(
                pdfURL: inputURL,
                outputPath: outputPath,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else {
            // Legacy standard mode (fast by default for backward compatibility)
            let converter = PDFMarkdownConverter(
                pdfURL: inputURL,
                outputPath: outputPath,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try await converter.convert()
        }
    }

    /// Process all PDFs in a directory (batch mode)
    private func runBatch() async throws {
        guard let inputPath = input else {
            throw ValidationError("Batch mode requires -i <directory>")
        }

        let inputURL = URL(fileURLWithPath: inputPath)
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: inputPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ValidationError("Batch mode requires input to be a directory: \(inputPath)")
        }

        // Determine output directory
        let outputDir: URL
        if let outputPath = output {
            outputDir = URL(fileURLWithPath: outputPath)
            // Create output directory if it doesn't exist
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        } else {
            outputDir = inputURL  // Same directory as input
        }

        // Find all PDF files
        let contents = try FileManager.default.contentsOfDirectory(
            at: inputURL,
            includingPropertiesForKeys: nil
        )
        let pdfFiles = contents.filter { $0.pathExtension.lowercased() == "pdf" }

        guard !pdfFiles.isEmpty else {
            throw ValidationError("No PDF files found in directory: \(inputPath)")
        }

        if verbose {
            FileHandle.standardError.write(Data("[pdf22md] Batch mode: \(pdfFiles.count) PDF file(s) found\n".utf8))
        }

        var successCount = 0
        var failCount = 0

        for pdfURL in pdfFiles {
            let baseName = pdfURL.deletingPathExtension().lastPathComponent
            let outputFile = outputDir.appendingPathComponent("\(baseName).md")

            if verbose {
                FileHandle.standardError.write(Data("[pdf22md] Processing: \(pdfURL.lastPathComponent)\n".utf8))
            }

            do {
                try await processSinglePDF(inputURL: pdfURL, outputPath: outputFile.path)
                successCount += 1
            } catch {
                failCount += 1
                FileHandle.standardError.write(Data("[pdf22md] Error processing \(pdfURL.lastPathComponent): \(error.localizedDescription)\n".utf8))
            }
        }

        if verbose {
            FileHandle.standardError.write(Data("[pdf22md] Batch complete: \(successCount) succeeded, \(failCount) failed\n".utf8))
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
            verbose: verbose,
            password: password
        )
    }
} 