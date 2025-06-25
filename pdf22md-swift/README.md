# pdf22md - Modern Swift Implementation

A high-performance PDF to Markdown converter built with modern Swift features including async/await, actors, and structured concurrency.

## Features

- **Modern Swift**: Uses Swift 5.7+ features including async/await, actors, and result builders
- **Structured Concurrency**: Concurrent page processing with TaskGroup and proper cancellation
- **Memory Safe**: Automatic memory management with value types where appropriate
- **Type Safe**: Strong typing with enums, associated types, and generic constraints
- **Actor-Based Assets**: Thread-safe image processing with actors
- **Progress Streaming**: Real-time progress updates with AsyncSequence

## Architecture

```
pdf22md-swift/
├── Sources/
│   ├── PDF22MD/                 # Library module
│   │   ├── Core/                # Core conversion logic
│   │   │   ├── PDFConverter     # Main coordinator
│   │   │   ├── PDFPageProcessor # Page content extraction
│   │   │   ├── FontAnalyzer     # Heading detection
│   │   │   ├── PDFError         # Error handling
│   │   │   └── ConversionOptions # Configuration
│   │   ├── Models/              # Data models
│   │   │   ├── ContentElement   # Protocol definition
│   │   │   ├── TextElement      # Text content (struct)
│   │   │   └── ImageElement     # Image content (class)
│   │   └── Services/            # Business logic services
│   │       ├── AssetManager     # Image extraction (actor)
│   │       └── MarkdownGenerator # Markdown generation
│   └── pdf22md/                 # CLI executable
│       └── main.swift
├── Tests/
│   └── PDF22MDTests/
├── Package.swift
└── README.md
```

## Building

```bash
# Build with Swift Package Manager
swift build

# Build optimized release
swift build -c release

# Run tests
swift test

# Generate documentation
swift package generate-documentation
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/twardoch/pdf22md-swift", from: "1.0.0")
]
```

### Executable

```bash
# Build executable
swift build -c release

# Copy to PATH
cp .build/release/pdf22md /usr/local/bin/
```

## Usage

### Command Line

```bash
# Convert a PDF file
pdf22md -i document.pdf -o document.md

# Extract images to assets folder
pdf22md -i report.pdf -o report.md -a ./assets

# Customize DPI and concurrency
pdf22md -i large.pdf -o large.md -d 300 --max-concurrency 8

# Use with pipes
cat document.pdf | pdf22md > document.md

# Verbose output with progress
pdf22md -i document.pdf -o document.md --verbose
```

### Programmatic Usage

```swift
import PDF22MD

// Simple conversion
let converter = try PDFConverter(url: inputURL)
let markdown = try await converter.convert()

// With custom options
let options = ConversionOptions(
    assetsFolderPath: "./assets",
    rasterizationDPI: 300.0,
    includeMetadata: true
)

let markdown = try await converter.convert(options: options)

// Using builder pattern
let options = ConversionOptionsBuilder()
    .assetsFolderPath("./images")
    .rasterizationDPI(300)
    .maxConcurrentPages(4)
    .progressHandler { page, total in
        print("Processing \(page)/\(total)")
    }
    .build()

// Convenience method
try await PDFConverter.convert(
    inputURL: inputURL,
    outputURL: outputURL,
    options: options
)
```

## Key Swift Features Used

### 1. Async/Await
```swift
public func convert(options: ConversionOptions = .default) async throws -> String {
    return try await withThrowingTaskGroup(of: (Int, [ContentElement]).self) { group in
        // Process pages concurrently
    }
}
```

### 2. Actors for Thread Safety
```swift
public actor AssetManager {
    private var usedFilenames: Set<String> = []
    
    public func saveImage(_ image: CGImage) async throws -> String {
        // Thread-safe image saving
    }
}
```

### 3. Result Types
```swift
public enum PDFError: LocalizedError {
    case invalidPDF(reason: String?)
    case processingFailed(reason: String, underlyingError: Error?)
    // ...
}
```

### 4. Value Types
```swift
public struct TextElement: ContentElement, Equatable, Hashable {
    public let text: String
    public let bounds: CGRect
    // Immutable by default
}
```

### 5. Protocol Extensions
```swift
public extension ContentElement {
    func isOnSameLine(as other: ContentElement) -> Bool {
        // Default implementation
    }
}
```

### 6. Structured Concurrency
```swift
return try await withThrowingTaskGroup(of: (Int, [ContentElement]).self) { group in
    for pageIndex in 0..<pageCount {
        group.addTask {
            // Process page concurrently
        }
    }
    // Collect results
}
```

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter PDF22MDTests.testTextElementCreation

# Run tests with coverage
swift test --enable-code-coverage

# Performance tests
swift test --filter Performance
```

## Performance

- Utilizes all available CPU cores with structured concurrency
- Actor-based asset management for thread-safe operations
- Memory-efficient with proper value/reference type usage
- Cancellation support for long-running operations
- Streaming progress updates

## Error Handling

```swift
do {
    let markdown = try await converter.convert()
} catch PDFError.invalidPDF(let reason) {
    print("Invalid PDF: \(reason ?? "Unknown error")")
} catch PDFError.processingFailed(let reason, let underlying) {
    print("Processing failed: \(reason)")
    if let underlying = underlying {
        print("Underlying error: \(underlying)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Requirements

- macOS 12.0 or later (for async/await)
- Swift 5.7 or later
- Xcode 14.0 or later

## Documentation

Generate documentation with:

```bash
swift package generate-documentation
```

View documentation:

```bash
swift package preview-documentation
```

## License

MIT License - see LICENSE file in the root directory