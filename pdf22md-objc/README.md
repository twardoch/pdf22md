# pdf22md-objc

A blazingly fast PDF to Markdown converter for macOS, built with Objective-C and optimized for performance using Grand Central Dispatch (GCD).

## Features

- **High-Speed Conversion**: Uses all available CPU cores to process PDF pages concurrently
- **Intelligent Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings
- **Asset Extraction**: Saves raster and vector images into a specified assets folder and links them correctly in the Markdown file
- **Smart Image Formatting**: Automatically chooses between JPEG (for photos) and PNG (for graphics with transparency)
- **Flexible I/O**: Reads from a PDF file or `stdin` and writes to a Markdown file or `stdout`
- **Customizable Rasterization**: Allows setting a custom DPI for converting vector graphics to bitmaps

## Building

### Using Make
```bash
# Build the project
make

# Build with debug symbols
make debug

# Build benchmark tool
make benchmark

# Install to /usr/local/bin
sudo make install

# Clean build artifacts
make clean
```

### Manual Build
```bash
# Compile manually
clang -fobjc-arc -framework Foundation -framework CoreGraphics -framework PDFKit -framework ImageIO \
  src/CLI/*.m src/Core/*.m src/Models/*.m src/Services/*.m shared-core/*.m shared-algorithms/*.m \
  -o pdf22md
```

## Installation

```bash
# Build and install
make
sudo make install
```

## Usage

```bash
# Convert a PDF file
./pdf22md -i document.pdf -o document.md

# Extract images to assets folder
./pdf22md -i report.pdf -o report.md -a ./assets

# Customize DPI for vector graphics
./pdf22md -i large.pdf -o large.md -d 300

# Use with pipes
cat document.pdf | ./pdf22md > document.md
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

## Architecture

The Objective-C implementation is organized into several key components:

### Core Components
- **PDF22MDConverter**: Main conversion coordinator
- **PDF22MDPageProcessor**: Handles individual page processing
- **PDF22MDFontAnalyzer**: Analyzes font usage for heading detection
- **PDF22MDAssetManager**: Manages image extraction and saving
- **PDF22MDMarkdownGenerator**: Generates final Markdown output

### Models
- **PDF22MDContentElement**: Base protocol for content elements
- **PDF22MDTextElement**: Represents text content with formatting
- **PDF22MDImageElement**: Represents image content

### Shared Components
- **PDF22MDConstants**: Shared constants and configuration
- **PDF22MDFileSystemUtils**: File system utilities
- **PDF22MDImageFormatDetection**: Image format detection algorithms

## Testing

```bash
# Run basic tests (requires implementation)
make test

# Run benchmark
make benchmark
./pdf22md-benchmark
```

## Performance

- Utilizes Grand Central Dispatch for concurrent page processing
- Memory-efficient processing with proper resource management
- Optimized image format detection and conversion
- Smart caching of font analysis results

## Requirements

- macOS 10.12 or later
- Xcode Command Line Tools
- Foundation, CoreGraphics, PDFKit, and ImageIO frameworks

## License

MIT License - see LICENSE file in the root directory 