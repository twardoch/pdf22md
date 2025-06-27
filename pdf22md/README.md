# pdf22md

A high-performance PDF to Markdown converter built with modern Swift features including async/await, actors, and structured concurrency.

## Features

- **Modern Swift**: Uses Swift 5.7+ features including async/await, actors, and result builders
- **Structured Concurrency**: Concurrent page processing with TaskGroup and proper cancellation
- **Memory Safe**: Automatic memory management with value types where appropriate
- **Type Safe**: Strong typing with enums, associated types, and generic constraints
- **Actor-Based Assets**: Thread-safe image processing with actors
- **Progress Streaming**: Real-time progress updates with AsyncSequence

## Building

### Using Swift Package Manager
```bash
# Build the project
swift build

# Build optimized release
swift build -c release

# Run tests
swift test

# Install executable
swift build -c release
cp .build/release/pdf22md /usr/local/bin/pdf22md
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "./pdf22md")
]
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
```

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter PDF22MDTests.testTextElementCreation

# Run tests with coverage
swift test --enable-code-coverage
```

## Requirements

- macOS 12.0 or later (for async/await)
- Swift 5.7 or later
- Xcode 14.0 or later

## License

MIT License - see LICENSE file in the root directory 