#!/usr/bin/env swift
// this_file: pdf22md-swift/Sources/CLI/main.swift

import ArgumentParser
import Foundation
import PDF22MD

@main
struct PDF22MDCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22md",
        abstract: "Convert PDF documents to Markdown format",
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Input PDF file (default: stdin)")
    var input: String?
    
    @Option(name: .shortAndLong, help: "Output Markdown file (default: stdout)")
    var output: String?
    
    @Option(name: .shortAndLong, help: "Assets folder for extracted images")
    var assets: String?
    
    @Option(name: .shortAndLong, help: "DPI for rasterizing vector graphics")
    var dpi: Double = 144.0
    
    @Flag(name: .long, help: "Enable verbose output")
    var verbose: Bool = false
    
    @Option(name: .long, help: "Maximum concurrent pages to process")
    var maxConcurrency: Int?
    
    func run() async throws {
        // Configure logging
        if verbose {
            print("pdf22md v\(Self.configuration.version ?? "unknown")")
        }
        
        // Determine input source
        let inputURL: URL
        if let inputPath = input {
            inputURL = URL(fileURLWithPath: inputPath)
            if !FileManager.default.fileExists(atPath: inputPath) {
                throw ValidationError("Input file does not exist: \(inputPath)")
            }
        } else {
            // Read from stdin
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("pdf22md-input-\(UUID().uuidString).pdf")
            try stdinData.write(to: tempURL)
            inputURL = tempURL
        }
        
        // Configure conversion options
        var options = ConversionOptions()
        options.assetsFolderPath = assets
        options.rasterizationDPI = dpi
        
        if let maxConcurrency = maxConcurrency {
            options.maxConcurrentPages = maxConcurrency
        }
        
        if verbose {
            options.progressHandler = { page, total in
                print("Processing page \(page)/\(total)", to: &FileHandle.standardError)
            }
        }
        
        do {
            // Perform conversion
            let converter = try PDFConverter(url: inputURL)
            let markdown = try await converter.convert(options: options)
            
            // Write output
            if let outputPath = output {
                let outputURL = URL(fileURLWithPath: outputPath)
                try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
                
                if verbose {
                    print("Conversion completed successfully. Output written to: \(outputPath)")
                }
            } else {
                // Write to stdout
                print(markdown)
            }
            
        } catch let error as PDFError {
            print("Error: \(error.localizedDescription)", to: &FileHandle.standardError)
            throw ExitCode.failure
        } catch {
            print("Unexpected error: \(error)", to: &FileHandle.standardError)
            throw ExitCode.failure
        }
        
        // Clean up temporary file if we created one
        if input == nil {
            try? FileManager.default.removeItem(at: inputURL)
        }
    }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        self.write(Data(string.utf8))
    }
} 