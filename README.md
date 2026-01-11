# pdf22md: Fast PDF to Markdown Converter for macOS

**pdf22md** extracts text and images from PDF files and converts them into clean Markdown documents. Built with Swift, it uses modern concurrency features like async/await and optimized GCD-based versions to process multi-page documents quickly.

## Who is it for?

This tool is useful for:

*   **Students and Researchers**: Convert academic papers, lecture notes, and research articles into editable Markdown for note-taking or further editing.
*   **Technical Writers and Developers**: Extract content from PDF documentation for use in Markdown-based systems such as wikis or static site generators.
*   **Content Creators**: Transform PDF reports, e-books, or brochures into Markdown format for web publishing.
*   **Anyone extracting PDF content**: A straightforward solution for copying text and images out of PDFs.

## Why use it?

Key features include:

*   **Speed**: Uses all available CPU cores to process pages concurrently. Especially effective on large documents.
*   **Smart Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings (`#`, `##`, `###`) in the Markdown output.
*   **Image Extraction**:
    *   Pulls both raster (JPEG, PNG) and vector images from the PDF's XObject streams.
    *   Saves images into a specified assets folder.
    *   Links images in Markdown using this naming convention: `<pdf-basename>-<page-number>-<asset-number>.<ext>`.
*   **Intelligent Image Formatting**: Chooses between JPEG and PNG based on image properties like transparency and color complexity to optimize file size and quality.
*   **Flexible Input/Output**:
    *   Reads PDFs from file paths or `stdin`.
    *   Writes Markdown to files or `stdout`.
*   **Custom DPI Rasterization**: Converts vector graphics (charts, diagrams) into bitmaps at user-defined resolution. Default is 144 DPI.
*   **Multiple Engines**: Includes standard async/await implementation and optimized GCD variants for performance tuning.

## Installation

### Using Homebrew

(Coming Soon) Install via Homebrew tap:

```bash
brew install twardoch/tap/pdf22md
```

### Building from Source

Requires Xcode Command Line Tools.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/twardoch/pdf22md.git
    cd pdf22md
    ```

2.  **Build the tool:**
    ```bash
    make build
    ```
    The binary will be located at `pdf22md/.build/release/pdf22md`.

3.  **Install system-wide (optional):**
    ```bash
    sudo make install
    ```

## Usage

Basic syntax:

```
pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi] [--optimized | --ultra-optimized]
```

**Options:**

*   `-i, --input <path>`: Input PDF file. If omitted, reads from `stdin`.
*   `-o, --output <path>`: Output Markdown file. If omitted, writes to `stdout`.
*   `-a, --assets <path>`: Folder to save extracted images. Image extraction is skipped if not provided.
*   `-d, --dpi <value>`: DPI for rasterizing vector graphics. Default: `144.0`.
*   `--optimized`: Use GCD-based engine.
*   `--ultra-optimized`: Use NSString-based high-performance engine.

**Examples:**

1.  **Convert PDF with images:**
    ```bash
    pdf22md -i my_document.pdf -o my_document.md -a ./assets
    ```

2.  **Use stdin/stdout:**
    ```bash
    cat report.pdf | pdf22md > report.md
    ```

3.  **Custom DPI with optimized engine:**
    ```bash
    pdf22md -i presentation.pdf -o slides.md -a ./images -d 300 --optimized
    ```

## Batch Testing

The `example.sh` script converts sample PDFs using all four conversion methods for testing and comparison:

```bash
# Run all methods on testdata/pdf/*.pdf
./example.sh

# Quiet mode (summary only)
./example.sh -q

# Custom timeout and specific methods
./example.sh -t 60 -m fast,ultra

# Show help
./example.sh -h
```

Results are stored in `testdata/{fast,standard,optimized,ultra}/` with extracted assets.

## Requirements

*   **macOS**: 12.0 or later
*   **Swift**: 5.7 or later (for building from source)
*   **Xcode Command Line Tools** (for building)

## Performance

Designed for speed and efficiency:

*   **Parallel Processing**: Uses Swift's `async/await` or Grand Central Dispatch (GCD) to process PDF pages concurrently across all CPU cores.
*   **Memory Efficient**: Handles large documents without excessive memory usage. Further optimized in alternative engines.
*   **Smart Algorithms**: Applies intelligent font analysis and image processing to minimize overhead.

## Technical Overview

### Core Architecture

Three processing engines:

1.  **Async/Await (`PDFMarkdownConverter.swift`)**: Standard engine using Swift's structured concurrency (`async/await`, `TaskGroup`).
2.  **GCD Optimized (`PDFMarkdownConverterOptimized.swift`)**: Alternative engine using Grand Central Dispatch directly.
3.  **Ultra-Optimized (`PDFMarkdownConverterUltraOptimized.swift`)**: High-speed engine using `NSString` and low-level optimizations.

### Data Flow

1.  **Document Analysis & Font Statistics (`FontStatistics.swift`)**
    *   Detects headings by analyzing font size frequency and usage.
    *   Sorts elements by page number and vertical position to preserve document flow.

2.  **Content Modeling (`PDFElement.swift`)**
    *   `TextElement`: Stores text string, bounding box, page index, font size, and style (bold, italic).
    *   `ImageElement`: Stores `CGImage`, bounds, page index, vector source status, and asset file path.

3.  **Page Processing (`PDFPageProcessor*.swift`)**
    *   Extracts text and its attributes (font, size, style) using PDFKit.
    *   **Image Extraction (`CGPDFImageExtractor.swift`)**:
        *   Pulls raster images from XObject streams.
        *   Rasterizes vector graphics at specified DPI.
    *   Creates `TextElement` and `ImageElement` instances with extracted data.

4.  **Asset Pipeline (`AssetExtractor.swift`)**
    *   Saves images with naming convention: `[pdf-basename]-[page_number]-[asset_index_on_page].[format]`.
    *   Selects PNG for images with transparency or fewer colors; JPEG for complex color patterns.
    *   Writes images to assets folder and returns correct paths for Markdown linking.

5.  **Markdown Output (`PDFMarkdownConverter*.swift`)**
    *   Traverses sorted `PDFElement` list.
    *   Converts `TextElement` to Markdown with proper formatting (bold, italic, headings).
    *   Converts `ImageElement` to Markdown image links.
    *   Inserts page breaks (`---`) between pages when needed.

### Concurrency Model

*   Pages processed in parallel for speed.
*   Standard version uses Swift's `TaskGroup`.
*   Optimized versions use GCD with concurrent queues and dispatch groups.
*   Ultra-optimized version adds aggressive pre-allocation and buffer manipulation.

### Integration Points

*   **Content Extraction Layer**: Bridges PDFKit parsing with structured `PDFElement` representation.
*   **Asset Management Layer**: Links `CGImage` objects to disk files and manages folder organization.

## Contributing

We welcome contributions. Follow these guidelines for smooth collaboration.

### Development Rules

*   **Focused Changes**: Only modify code relevant to your feature or bug fix.
*   **Complete Code**: No placeholders. Submit working implementations.
*   **Incremental Approach**: Break complex problems into smaller steps.
*   **Clear Reasoning**: Explain your solution with evidence from code or behavior.
*   **Follow AGENTS.md**: Respect local directory guidelines if present.

### Technical Standards

*   **Swift**: 5.7+
*   **macOS**: 12.0+
*   **Package Manager**: Swift Package Manager. Update `Package.swift` as needed.
*   **Concurrency**: Use `async/await` and `Actors` appropriately. Ensure thread safety with GCD.
*   **Code Style**: Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Use SwiftFormat if config provided.
*   **Error Handling**: Use Swift's `Error` protocol. Define custom errors (e.g., `PDFConversionError`) and propagate gracefully.
*   **Value Types**: Prefer `struct` over `class` unless reference semantics are required.

### Testing

*   All new code must include unit or integration tests.
*   Tests located in `pdf22md/Tests/PDF22MDTests/`.
*   Use XCTest framework.

### Workflow

1.  Fork and clone the repository.
2.  Create a branch (`feature/your-feature` or `bugfix/issue-number`).
3.  Implement changes following guidelines.
4.  Write tests and verify all pass:
    ```bash
    swift test
    # or
    make test
    ```
5.  Build project:
    ```bash
    swift build -c release
    # or
    make build
    ```
6.  Update documentation (`README.md`, `CHANGELOG.md`) if needed.
7.  Commit with clear messages.
8.  Push to your fork.
9.  Open PR to `main` branch of original repository.

For full details, see `CONTRIBUTING.md`.

### Changelog and TODO

*   After updates:
    *   Update `CHANGELOG.md`.
    *   Review `TODO.md` - remove completed items, add new ones.
    *   Build application to verify functionality.