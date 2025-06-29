# pdf22md: Blazingly Fast PDF to Markdown Converter for macOS

A high-performance command-line tool that extracts all text and image content from PDF files and converts them into clean Markdown documents. Built with Swift and modern async/await for parallel processing, making it exceptionally fast for multi-page documents.

## Key Features

-   **High-Speed Conversion**: Uses all available CPU cores to process PDF pages concurrently
-   **Intelligent Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings (`#`, `##`, etc.)
-   **Asset Extraction**: Saves raster and vector images into a specified assets folder and links them correctly in the Markdown file
-   **Smart Image Formatting**: Automatically chooses between JPEG (for photos) and PNG (for graphics with transparency) to optimize file size and quality
-   **Flexible I/O**: Reads from a PDF file or `stdin` and writes to a Markdown file or `stdout`
-   **Customizable Rasterization**: Allows setting a custom DPI for converting vector graphics to bitmaps

## Installation

### Using Homebrew (Coming Soon)

```bash
brew install twardoch/tap/pdf22md
```

### Building from Source

You need Xcode Command Line Tools installed.

```bash
# Clone the repository
git clone https://github.com/twardoch/pdf22md.git
cd pdf22md

# Build using Make
make build
sudo make install
```

## Usage

```
Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
  Converts PDF documents to Markdown format
  -i <path>: Input PDF file (default: stdin)
  -o <path>: Output Markdown file (default: stdout)
  -a <path>: Assets folder for extracted images
  -d <dpi>: DPI for rasterizing vector graphics (default: 144)
```

### Examples

```bash
# Convert a PDF to Markdown with images extracted to an assets folder
pdf22md -i report.pdf -o report.md -a ./assets

# Convert a PDF using stdin/stdout
cat document.pdf | pdf22md > document.md

# Convert with custom DPI for vector graphics
pdf22md -i presentation.pdf -o slides.md -a ./images -d 300
```

## Requirements

-   macOS 12.0 or later
-   Swift 5.7+ (for building from source)
-   Xcode Command Line Tools (for building from source)

## Performance

`pdf22md` is engineered for speed:

-   **Parallel Processing**: Uses Swift's async/await to process PDF pages concurrently across all available CPU cores
-   **Efficient Memory Use**: Designed to handle large documents without excessive memory consumption
-   **Smart Optimizations**: Includes intelligent algorithms for font analysis and image handling

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

`pdf22md` is released under the MIT License. See the [LICENSE](LICENSE) file for details.
