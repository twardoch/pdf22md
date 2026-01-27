# pdf22md: Fast PDF to Markdown Converter for macOS

> **Status**: v1.6.1 — Production-ready with Vision OCR and AI text correction.

**pdf22md** extracts text and images from PDF files and converts them into clean Markdown documents. Built with Swift for macOS, it uses modern concurrency (async/await, GCD) to process multi-page documents quickly. Features include Vision-based OCR for scanned PDFs and optional AI-powered text correction via OpenAI or Apple Intelligence.

## Who is it for?

This tool is useful for:

*   **Students and Researchers**: Convert academic papers, lecture notes, and research articles into editable Markdown for note-taking or further editing.
*   **Technical Writers and Developers**: Extract content from PDF documentation for use in Markdown-based systems such as wikis or static site generators.
*   **Content Creators**: Transform PDF reports, e-books, or brochures into Markdown format for web publishing.
*   **Anyone extracting PDF content**: A straightforward solution for copying text and images out of PDFs.

## Why use it?

Key features include:

*   **Speed**: Uses all available CPU cores to process pages concurrently. Especially effective on large documents.
*   **Vision OCR**: Extracts text from scanned PDFs and images using Apple's Vision framework. Works automatically when PDFKit text extraction returns empty content.
*   **AI Text Correction**: Optional post-processing with OpenAI API or Apple Intelligence to fix OCR errors, improve formatting, and clean up extracted text.
*   **Smart Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings (`#`, `##`, `###`) in the Markdown output.
*   **Image Extraction**:
    *   Pulls both raster (JPEG, PNG) and vector images from the PDF's XObject streams.
    *   Saves images into a specified assets folder.
    *   Links images in Markdown using this naming convention: `<pdf-basename>-<page-number>-<asset-number>.<ext>`.
*   **Intelligent Image Formatting**: Chooses between JPEG and PNG based on image properties like transparency and color complexity to optimize file size and quality.
*   **Batch Processing**: Process multiple PDFs in parallel with configurable job count.
*   **Password Support**: Open password-protected PDFs.
*   **Flexible Input/Output**:
    *   Reads PDFs from file paths or `stdin`.
    *   Writes Markdown to files or `stdout`.
*   **Custom DPI Rasterization**: Converts vector graphics (charts, diagrams) into bitmaps at user-defined resolution. Default is 144 DPI.
*   **OCR Caching**: Results cached in `~/.cache/pdf22md/ocr/` to avoid re-processing unchanged PDFs.

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
pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi] [options]
```

**Options:**

*   `-i, --input <path>`: Input PDF file. If omitted, reads from `stdin`.
*   `-o, --output <path>`: Output Markdown file. If omitted, writes to `stdout`.
*   `-a, --assets <path>`: Folder to save extracted images. Image extraction is skipped if not provided.
*   `-d, --dpi <value>`: DPI for rasterizing vector graphics. Default: `144.0`.
*   `-p, --password <pwd>`: Password for protected PDFs.

**Processing Modes:**

*   Default: Standard mode with Vision OCR for enhanced text extraction.
*   `--fast`: Skip Vision OCR, use PDF text extraction only (faster but less accurate for scanned documents).

**AI Options:**

*   `--ai`: Enable AI-based text correction (uses Apple Intelligence if --api not specified).
*   `--api <config>`: AI API in format `model:api_key@base_url` (e.g., `gpt-4o:sk-xxx@https://api.openai.com/v1`).
*   `--ai-prompt <file>`: Custom AI prompt template (JSON file).

**OCR Options:**

*   `--languages <codes>`: Languages for Vision OCR (comma-separated ISO 639 codes, e.g., `en,fr,de`). Default: `en`.
*   `--threshold <value>`: Vision text preference threshold (default: 1.5, use Vision if >N times longer than PDF text).
*   `--no-cache`: Disable OCR result caching.

**Output Control:**

*   `-v, --verbose`: Show additional warnings and debug info.
*   `-q, --quiet`: Suppress all non-error output.

**Batch Mode:**

*   `--batch`: Enable batch processing of multiple PDFs.
*   `-j, --jobs <n>`: Number of parallel jobs in batch mode. Default: CPU core count.

**Examples:**

1.  **Convert PDF with images:**
    ```bash
    pdf22md -i my_document.pdf -o my_document.md -a ./assets
    ```

2.  **Use stdin/stdout:**
    ```bash
    cat report.pdf | pdf22md > report.md
    ```

3.  **High DPI for better image quality:**
    ```bash
    pdf22md -i presentation.pdf -o slides.md -a ./images -d 300
    ```

4.  **With AI text correction (OpenAI):**
    ```bash
    pdf22md -i scanned.pdf -o cleaned.md --ai --api "gpt-4o:sk-xxx@https://api.openai.com/v1"
    ```

5.  **Fast mode (PDF text only, no Vision OCR):**
    ```bash
    pdf22md -i document.pdf -o output.md --fast
    ```

6.  **Multi-language OCR:**
    ```bash
    pdf22md -i french_german.pdf -o output.md --languages fr,de
    ```

7.  **Batch process multiple PDFs:**
    ```bash
    pdf22md --batch -i ./docs/ -o ./output/ -a ./assets/ -j 4
    ```

8.  **Open password-protected PDF:**
    ```bash
    pdf22md -i protected.pdf -o output.md --password "secret"
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

## Troubleshooting

### "No such module 'XCTest'" when running tests

This occurs when `xcode-select` points to Command Line Tools instead of Xcode.app:

```bash
# Check current setting
xcode-select -p

# Fix (requires admin)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Vision OCR returns empty text

*   Ensure the PDF contains actual scanned images, not digital text
*   Try increasing DPI: `--dpi 300`
*   Check language setting: `--languages en,fr` for multi-language documents

### AI API errors

*   Verify API key format: `model:api_key@base_url`
*   Test with curl: `curl -H "Authorization: Bearer YOUR_KEY" https://api.openai.com/v1/models`
*   For local models (Ollama): use empty key: `llama3:@http://localhost:11434/v1`

### High memory usage on large PDFs

*   Process fewer pages at once: `--max-pages 10`
*   Use `--fast` mode to skip Vision OCR
*   Close other applications to free memory

### Slow processing

*   Use `--fast` for digital PDFs (skips Vision OCR)
*   Reduce DPI for images: `--dpi 72`
*   Use batch mode with parallel jobs: `--batch -j 4`

## Performance

Designed for speed and efficiency:

*   **Parallel Processing**: Uses Swift's `async/await` and `TaskGroup` to process PDF pages concurrently across all CPU cores.
*   **Memory Efficient**: Handles large documents without excessive memory usage.
*   **Smart Algorithms**: Applies intelligent font analysis and image processing to minimize overhead.

### Performance Tips

**For fastest processing:**
```bash
# Digital PDFs with embedded text - skip Vision OCR
pdf22md -i document.pdf -o output.md --fast

# Lower DPI for smaller images (default: 144)
pdf22md -i document.pdf -o output.md -a ./images --dpi 72
```

**For batch processing:**
```bash
# Process multiple PDFs with 4 parallel jobs
pdf22md --batch -i ./pdfs/ -o ./output/ -j 4

# Preview large PDFs - process first 3 pages only
pdf22md -i large.pdf -o preview.md --max-pages 3
```

**For scanned PDFs (OCR-heavy):**
```bash
# OCR results are cached by default (~/.cache/pdf22md/ocr/)
# Second run on same PDF is instant

# Disable cache for fresh OCR
pdf22md -i scanned.pdf -o output.md --no-cache

# Specify languages for better accuracy
pdf22md -i multilingual.pdf -o output.md --languages de,fr,en
```

**Memory considerations:**
*   Large PDFs (100+ pages) process incrementally
*   Use `--max-pages` to limit processing for previews
*   Image extraction at high DPI uses more memory

## Technical Overview

### Core Architecture

Single unified converter using Swift's structured concurrency:

*   **`PDFMarkdownConverter.swift`**: Main converter with Vision OCR integration and optional AI processing. Uses `async/await` and `TaskGroup` for parallel page processing.

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

*   Pages processed in parallel using Swift's `TaskGroup`.
*   Vision OCR requests execute concurrently per page.
*   AI text correction processes pages sequentially with sliding window context.

### Vision OCR Pipeline

*   Automatically activates when PDFKit returns empty text (scanned PDFs).
*   Uses `VNRecognizeTextRequest` with accurate recognition level.
*   Processes page images at configurable DPI for optimal accuracy.
*   Results integrated into the same `TextElement` model.

### AI Text Correction

*   Optional post-processing step using LLM APIs.
*   OpenAI: GPT-4o-mini for efficient text cleanup.
*   Apple Intelligence: On-device processing (macOS 15+).
*   Corrects OCR errors, improves formatting, normalizes whitespace.

### Integration Points

*   **Content Extraction Layer**: Bridges PDFKit parsing with structured `PDFElement` representation.
*   **Vision OCR Layer**: Fallback text extraction using Apple's Vision framework.
*   **AI Processing Layer**: Optional LLM-based text enhancement and correction.
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