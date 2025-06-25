# pdf22md

A blazingly fast PDF to Markdown converter for macOS, available in two high-performance implementations.

`pdf22md` extracts all text and image content from PDF files and converts them into clean Markdown documents. Both implementations use parallel processing to make conversion exceptionally fast for multi-page documents.

## Implementations

This repository contains two complete, self-contained implementations:

### 🔥 [pdf22md-objc](./pdf22md-objc/) - Objective-C Implementation
- **Mature & Battle-tested**: Production-ready with comprehensive features
- **Grand Central Dispatch**: Uses GCD for optimal concurrent page processing  
- **Native Performance**: Direct Core Foundation and PDFKit integration
- **Memory Efficient**: Careful resource management with ARC

### ⚡ [pdf22md-swift](./pdf22md-swift/) - Swift Implementation  
- **Modern Swift**: Built with Swift 5.7+ async/await and structured concurrency (framework ready)
- **Type Safe**: Strong typing with enums, protocols, and generic constraints
- **Library Foundation**: Swift Package Manager library ready for implementation
- **Memory Safe**: Automatic memory management with value types

## Key Features (Both Implementations)

- **High-Speed Conversion**: Uses all available CPU cores to process PDF pages concurrently
- **Intelligent Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings (`#`, `##`, etc.)
- **Asset Extraction**: Saves raster and vector images into a specified assets folder and links them correctly in the Markdown file
- **Smart Image Formatting**: Automatically chooses between JPEG (for photos) and PNG (for graphics with transparency) to optimize file size and quality
- **Flexible I/O**: Reads from a PDF file or `stdin` and writes to a Markdown file or `stdout`
- **Customizable Rasterization**: Allows setting a custom DPI for converting vector graphics to bitmaps

## Quick Start

### Objective-C Implementation
```bash
cd pdf22md-objc
make
./pdf22md -i document.pdf -o document.md -a ./assets
```

### Swift Implementation  
```bash
cd pdf22md-swift
swift build -c release
# Note: CLI implementation in progress - currently library framework only
```

## Usage

Both implementations share the same command-line interface:

```bash
# Convert a PDF file
pdf22md -i report.pdf -o report.md

# Extract images to assets folder  
pdf22md -i document.pdf -o document.md -a ./assets

# Customize DPI for vector graphics
pdf22md -i large.pdf -o large.md -d 300

# Use with pipes
cat document.pdf | pdf22md > document.md
```

### Command Line Options

```
Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
  Converts PDF documents to Markdown format
  -i <path>: Input PDF file (default: stdin)
  -o <path>: Output Markdown file (default: stdout)  
  -a <path>: Assets folder for extracted images
  -d <dpi>: DPI for rasterizing vector graphics (default: 144)
```

## Installation

### Homebrew (Coming Soon)
```bash
brew install twardoch/pdf22md/pdf22md
```

### Build from Source

#### Objective-C
```bash
cd pdf22md-objc
make
sudo make install
```

#### Swift
```bash
cd pdf22md-swift  
swift build -c release
# Note: Currently library framework only - CLI implementation in progress
```

## Requirements

- macOS 10.12 or later
- Xcode Command Line Tools
- For Swift: macOS 12.0+ and Swift 5.7+

## Performance

Both implementations are optimized for speed:

- **Concurrent Processing**: Utilizes all available CPU cores
- **Memory Efficient**: Proper resource management and cleanup
- **Smart Caching**: Font analysis and image format detection caching
- **Optimized I/O**: Efficient file reading and writing

## Documentation

- [Objective-C Implementation](./pdf22md-objc/README.md)
- [Swift Implementation](./pdf22md-swift/README.md)
- [Parallel Processing Details](./docs/PARALLEL_PROCESSING.md)

## Contributing

Contributions are welcome! Please see each implementation's directory for specific development guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.