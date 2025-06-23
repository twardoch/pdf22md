import Foundation
import Benchmark
import PDF22MD

// Define benchmark configuration
let benchmarks = {
    // Benchmark suite comparing ObjC and Swift implementations
    
    let testPDFs = [
        ("small", "test/small.pdf", 5),      // 5 pages
        ("medium", "test/medium.pdf", 50),   // 50 pages
        ("large", "test/large.pdf", 200),    // 200 pages
        ("image-heavy", "test/images.pdf", 20) // 20 pages with many images
    ]
    
    for (name, path, pageCount) in testPDFs {
        let pdfPath = FileManager.default.currentDirectoryPath + "/" + path
        
        // Swift implementation benchmarks
        Benchmark("Swift-\(name)-pdf", 
                 configuration: .init(timeUnits: .milliseconds)) { benchmark in
            for _ in benchmark.scaledIterations {
                Task {
                    let url = URL(fileURLWithPath: pdfPath)
                    let outputPath = "/tmp/swift-output.md"
                    let assetsPath = "/tmp/swift-assets"
                    
                    let converter = PDFMarkdownConverter(
                        pdfURL: url,
                        outputPath: outputPath,
                        assetsPath: assetsPath,
                        dpi: 144.0
                    )
                    
                    try await converter.convert()
                }
            }
        }
        
        // ObjC implementation benchmarks
        Benchmark("ObjC-\(name)-pdf",
                 configuration: .init(timeUnits: .milliseconds)) { benchmark in
            for _ in benchmark.scaledIterations {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "./pdf22md")
                process.arguments = [
                    "-i", pdfPath,
                    "-o", "/tmp/objc-output.md",
                    "-a", "/tmp/objc-assets",
                    "-d", "144"
                ]
                
                try process.run()
                process.waitUntilExit()
            }
        }
    }
    
    // Memory usage benchmarks
    Benchmark("Swift-memory-large",
             configuration: .init(
                timeUnits: .milliseconds,
                scalingFactor: .one,
                maxIterations: 1
             )) { benchmark in
        autoreleasepool {
            let info = ProcessInfo.processInfo
            let startMemory = info.physicalMemory
            
            Task {
                let url = URL(fileURLWithPath: "test/large.pdf")
                let converter = PDFMarkdownConverter(
                    pdfURL: url,
                    outputPath: nil,
                    assetsPath: nil,
                    dpi: 144.0
                )
                
                try await converter.convert()
            }
            
            let endMemory = info.physicalMemory
            let memoryUsed = endMemory - startMemory
            
            benchmark.measurement(.custom("memory_mb"), Double(memoryUsed) / 1_048_576)
        }
    }
    
    // Concurrent processing benchmark
    Benchmark("Swift-concurrent-pages",
             configuration: .init(timeUnits: .milliseconds)) { benchmark in
        for _ in benchmark.scaledIterations {
            Task {
                let url = URL(fileURLWithPath: "test/medium.pdf")
                let converter = PDFMarkdownConverter(
                    pdfURL: url,
                    outputPath: nil,
                    assetsPath: nil,
                    dpi: 144.0
                )
                
                try await converter.convert()
            }
        }
    }
}

// Run benchmarks
Benchmark.main()