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

              pdf22md -i french.pdf -o french.md --languages fr,en
                  OCR with French and English language support

              pdf22md -i doc.pdf -o doc.md --password secret123
                  Convert password-protected PDF

              pdf22md -i ./pdfs --batch -o ./output -v
                  Batch convert all PDFs in directory

              pdf22md -i ./pdfs --batch -o ./output -j 4 -v
                  Batch convert with 4 parallel jobs

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

    @Option(name: .shortAndLong, help: "Parallel jobs for batch mode (default: 1)")
    var jobs: Int = 1

    @Flag(name: .shortAndLong, help: "Show progress during conversion")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Suppress all non-error output")
    var quiet: Bool = false

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

    /// Log message to stderr (respects quiet flag)
    private func log(_ message: String) {
        guard !quiet else { return }
        if verbose {
            FileHandle.standardError.write(Data("[pdf22md] \(message)\n".utf8))
        }
    }

    /// Log error to stderr (always shown unless quiet)
    private func logError(_ message: String) {
        if !quiet {
            FileHandle.standardError.write(Data("[pdf22md] Error: \(message)\n".utf8))
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
        let pdfFiles = contents.filter { $0.pathExtension.lowercased() == "pdf" }.sorted { $0.path < $1.path }

        guard !pdfFiles.isEmpty else {
            throw ValidationError("No PDF files found in directory: \(inputPath)")
        }

        let effectiveJobs = max(1, min(jobs, ProcessInfo.processInfo.activeProcessorCount))
        log("Batch mode: \(pdfFiles.count) PDF file(s), \(effectiveJobs) parallel job(s)")

        // Process files with concurrency limit
        let totalFiles = pdfFiles.count
        let results = await withTaskGroup(of: (String, Bool).self) { group in
            var pending = pdfFiles.makeIterator()
            var inFlight = 0
            var results: [(String, Bool)] = []
            var completedCount = 0

            // Start initial batch of jobs
            while inFlight < effectiveJobs, let pdfURL = pending.next() {
                let baseName = pdfURL.deletingPathExtension().lastPathComponent
                let outputFile = outputDir.appendingPathComponent("\(baseName).md")

                group.addTask {
                    do {
                        try await self.processSinglePDF(inputURL: pdfURL, outputPath: outputFile.path)
                        return (pdfURL.lastPathComponent, true)
                    } catch {
                        return (pdfURL.lastPathComponent, false)
                    }
                }
                inFlight += 1
            }

            // Process remaining files as jobs complete
            for await (filename, success) in group {
                results.append((filename, success))
                completedCount += 1
                let progress = "[\(completedCount)/\(totalFiles)]"
                if success {
                    log("\(progress) Completed: \(filename)")
                } else {
                    logError("\(progress) Failed: \(filename)")
                }

                // Start next job if available
                if let pdfURL = pending.next() {
                    let baseName = pdfURL.deletingPathExtension().lastPathComponent
                    let outputFile = outputDir.appendingPathComponent("\(baseName).md")

                    group.addTask {
                        do {
                            try await self.processSinglePDF(inputURL: pdfURL, outputPath: outputFile.path)
                            return (pdfURL.lastPathComponent, true)
                        } catch {
                            return (pdfURL.lastPathComponent, false)
                        }
                    }
                }
            }

            return results
        }

        let successCount = results.filter { $0.1 }.count
        let failCount = results.count - successCount
        log("Batch complete: \(successCount) succeeded, \(failCount) failed")
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