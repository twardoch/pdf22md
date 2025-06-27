import Foundation
import ArgumentParser
import PDF22MD

@main
struct PDF22MDCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22md",
        abstract: "Converts PDF documents to Markdown format (Swift implementation)",
        version: "1.0.0"
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
    
    func run() async throws {
        let inputURL: URL
        
        if let inputPath = input {
            inputURL = URL(fileURLWithPath: inputPath)
        } else {
            // Read from stdin into a temporary file
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("pdf")
            let inputData = FileHandle.standardInput.readDataToEndOfFile()
            try inputData.write(to: tempFile)
            inputURL = tempFile
        }
        
        // Choose implementation
        if ultraOptimized {
            let converter = PDFMarkdownConverterUltraOptimized(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else if optimized {
            let converter = PDFMarkdownConverterOptimized(
                pdfURL: inputURL,
                outputPath: output,
                assetsPath: assets,
                dpi: CGFloat(dpi)
            )
            try converter.convert()
        } else {
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
} 