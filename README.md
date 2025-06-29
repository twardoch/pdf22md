# pdf22md: Blazingly Fast PDF to Markdown Converter for macOS

**pdf22md** is a high-performance command-line tool designed for macOS that intelligently extracts all text and image content from PDF files and converts them into clean, well-structured Markdown documents. Built with Swift and leveraging modern concurrency features like async/await (and optimized GCD-based versions), it excels at rapidly processing multi-page documents.

## Who is it for?

This tool is perfect for:

*   **Students and Researchers**: Quickly convert academic papers, lecture notes, and research articles into editable Markdown for note-taking and integration into other documents.
*   **Technical Writers and Developers**: Extract content from PDF documentation to update or repurpose it in Markdown-based systems (like wikis or static site generators).
*   **Content Creators**: Easily transform PDF reports, e-books, or brochures into Markdown for web publishing or content reuse.
*   **Anyone needing to get content out of PDFs**: If you've ever struggled with copying text and images from a PDF, pdf22md offers a streamlined solution.

## Why is it useful?

pdf22md offers several key advantages:

*   **High-Speed Conversion**: Utilizes all available CPU cores to process PDF pages concurrently, making it exceptionally fast, especially for large documents.
*   **Intelligent Heading Detection**: Analyzes font sizes and their frequency of use within the PDF to automatically format titles and headings (e.g., `#`, `##`, `###`) in the Markdown output, preserving the document's structure.
*   **Comprehensive Asset Extraction**:
    *   Extracts both raster (like JPEG, PNG) and vector images directly from the PDF's XObject streams.
    *   Saves images into a specified assets folder.
    *   Correctly links these images within the generated Markdown file using a clear naming convention: `<pdf-basename>-<page-number>-<asset-number>.<ext>`.
*   **Smart Image Formatting**: Automatically chooses between JPEG (ideal for photographs) and PNG (better for graphics with transparency or sharp lines) to optimize file size and visual quality. This is based on analyzing image properties like transparency and color complexity.
*   **Flexible Input/Output**:
    *   Reads from a PDF file specified by path.
    *   Can read PDF data from `stdin` (standard input).
    *   Writes Markdown to an output file.
    *   Can write Markdown to `stdout` (standard output).
*   **Customizable Rasterization**: Allows users to set a custom DPI (dots per inch) for converting vector graphics (like charts or diagrams found in PDFs) into bitmap images (PNG/JPEG).
*   **Multiple Performance Profiles**: Offers different conversion engines, including a highly optimized version using Grand Central Dispatch (GCD) and even an "ultra-optimized" variant for specific performance needs.

## Installation

### Using Homebrew

(Coming Soon) A Homebrew tap will be available for easy installation:

```bash
brew install twardoch/tap/pdf22md
```

### Building from Source

To build `pdf22md` from source, you'll need Xcode Command Line Tools installed on your macOS system.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/twardoch/pdf22md.git
    cd pdf22md
    ```

2.  **Build the tool using Make:**
    The `Makefile` provides convenient targets for building and installing.
    ```bash
    make build
    ```
    This will compile the release version of the tool. The binary will be located at `pdf22md/.build/release/pdf22md`.

3.  **Install the tool (optional):**
    To make `pdf22md` available system-wide, you can install it to `/usr/local/bin`:
    ```bash
    sudo make install
    ```

## Usage

`pdf22md` is a command-line tool. The basic syntax is:

```
pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi] [--optimized | --ultra-optimized]
```

**Command-line Options:**

*   `-i, --input <path>`: Path to the input PDF file. If omitted, `pdf22md` will read from `stdin`.
*   `-o, --output <path>`: Path to the output Markdown file. If omitted, `pdf22md` will write to `stdout`.
*   `-a, --assets <path>`: Path to the folder where extracted images should be saved. If provided, images will be extracted; otherwise, image extraction is skipped.
*   `-d, --dpi <value>`: DPI (dots per inch) for rasterizing vector graphics. Defaults to `144.0`. Higher values produce larger, more detailed images.
*   `--optimized`: Use the GCD-based optimized conversion engine.
*   `--ultra-optimized`: Use the highly optimized NSString-based conversion engine.

**Examples:**

1.  **Convert a PDF to Markdown, extracting images:**
    ```bash
    pdf22md -i my_document.pdf -o my_document.md -a ./assets
    ```
    This will create `my_document.md` and save all images from `my_document.pdf` into an `assets` folder in the current directory.

2.  **Convert a PDF using stdin and stdout:**
    ```bash
    cat report.pdf | pdf22md > report.md
    ```
    This pipes the content of `report.pdf` into `pdf22md` and saves the Markdown output to `report.md`. No images will be extracted unless `-a` is specified.

3.  **Convert with custom DPI for vector graphics and use the optimized engine:**
    ```bash
    pdf22md -i presentation.pdf -o slides.md -a ./images -d 300 --optimized
    ```
    This converts `presentation.pdf`, saves images to `./images`, and rasterizes vector graphics at 300 DPI using the optimized engine.

## Requirements

*   **Operating System**: macOS 12.0 or later (due to the use of modern Swift concurrency features).
*   **For Building from Source**:
    *   Swift 5.7 or later.
    *   Xcode Command Line Tools.

## Performance

`pdf22md` is engineered for speed and efficiency:

*   **Parallel Processing**: Leverages Swift's `async/await` or Grand Central Dispatch (GCD) in optimized versions to process PDF pages concurrently across all available CPU cores.
*   **Efficient Memory Use**: Designed to handle large documents without consuming excessive memory, with further optimizations in the specialized versions.
*   **Smart Algorithms**: Employs intelligent algorithms for font analysis (heading detection) and image processing (format selection, asset extraction) to minimize overhead.

## Technical Deep Dive

This section provides a more detailed look into how `pdf22md` works internally, its core components, and guidelines for contributing to the project.

### How the Code Works

`pdf22md` is built using Swift and leverages Apple's powerful frameworks like PDFKit and CoreGraphics. The primary goal is to parse PDF documents, understand their structure and content, and convert them into semantically accurate Markdown.

**Core Architecture:**

The conversion process is orchestrated by a main converter class (`PDFMarkdownConverter` or its optimized variants) which manages page processing, asset extraction, and Markdown generation. The tool supports multiple processing engines:

1.  **Async/Await Engine (`PDFMarkdownConverter.swift`)**: The standard engine using Swift's modern structured concurrency (`async/await`, `TaskGroup`) for parallel page processing.
2.  **GCD Optimized Engine (`PDFMarkdownConverterOptimized.swift`)**: An alternative engine that uses Grand Central Dispatch (GCD) directly for managing concurrency, which can offer performance benefits in certain scenarios.
3.  **Ultra-Optimized Engine (`PDFMarkdownConverterUltraOptimized.swift`)**: A highly specialized engine focused on raw speed, using `NSString` for text processing and other low-level optimizations.

**Core Components & Data Flow:**

The system relies on several key components to achieve PDF to Markdown conversion:

1.  **Document Structure Analysis & Font Statistics (`FontStatistics.swift`, `PDFMarkdownConverter*.swift`)**
    *   **Hierarchical Heading Detection**: The tool analyzes font usage throughout the PDF. It calculates the frequency and size of different fonts. Based on statistical analysis (e.g., less frequent, larger fonts are often headings), it assigns heading levels (H1-H6) to text segments. `FontStatistics.swift` encapsulates logic for determining heading levels based on font size against a pre-analyzed set of heading font sizes.
    *   **Positional Element Sorting**: Elements extracted from the PDF (text, images) are sorted based on their page number and then their vertical position on the page. This helps maintain the original document flow.

2.  **Content Classification System (`PDFElement.swift`)**
    *   PDF content is modeled into distinct element types, primarily:
        *   `TextElement`: Represents textual content. It stores the text string, bounding box (position and size), page index, font size, and style attributes like bold and italic.
        *   `ImageElement`: Represents graphical content. It can hold a `CGImage`, its bounds, page index, whether it was derived from a vector source, and the path to the saved asset file.
    *   These structures help in managing the properties of each piece of content extracted from the PDF.

3.  **PDF Page Processing (`PDFPageProcessor.swift`, `PDFPageProcessorOptimized.swift`, `PDFPageProcessorUltraOptimized.swift`)**
    *   Each page of the PDF is processed, often concurrently.
    *   **Text Extraction**: Text is extracted along with its attributes (font, size, style) using PDFKit's capabilities. `PDFPageProcessor` iterates through attributed strings on a page, extracting text runs, their fonts (for size and style analysis like bold/italic), and their bounding boxes.
    *   **Image Extraction (`CGPDFImageExtractor.swift`)**:
        *   Raster images (like JPEGs or PNGs embedded in the PDF) are extracted directly from the PDF's XObject image streams. `CGPDFImageExtractor.swift` navigates the PDF's internal structure (Page Dictionary -> Resources -> XObject) to find image objects, copies their data, and reconstructs `CGImage` objects. It handles various formats like JPEG, JPEG2000, and raw bitmap data.
        *   Vector graphics are not always directly "extracted" as vector files. Instead, `PDFPageProcessor` may identify regions containing vector graphics (e.g., by looking for areas with drawing commands or minimal text) and render these sections into bitmap images (PNG/JPEG) at a user-specified DPI.
    *   **Element Creation**: As text and images are processed, `TextElement` and `ImageElement` instances are created and populated with the extracted data and metadata.

4.  **Asset Processing Pipeline (`AssetExtractor.swift`)**
    *   **Asset Naming**: Extracted images are saved with a standardized naming convention: `[pdf-basename]-[page_number]-[asset_index_on_page].[format]`. For example, `report-001-02.png`.
    *   **Intelligent Format Selection**: `AssetExtractor.swift` decides whether to save an image as PNG or JPEG.
        *   PNG is typically chosen for images with transparency (alpha channel detected) or those with fewer colors/smaller dimensions (indicative of graphics, icons).
        *   JPEG is chosen for images without transparency that are likely photographs (e.g., complex color patterns, larger dimensions). This involves checking image properties like `alphaInfo`, `bitsPerPixel`, and dimensions.
    *   **Asset Saving**: Images are written to the specified assets folder. The path provided in the Markdown output correctly references these saved files.

5.  **Markdown Generation (`PDFMarkdownConverter*.swift`)**
    *   The sorted list of `PDFElement` objects is traversed.
    *   `TextElement`s are converted to Markdown text. Formatting (bold, italic) is applied using Markdown syntax (`**bold**`, `*italic*`). Heading levels determined by `FontStatistics` are applied (e.g., `## Heading`).
    *   `ImageElement`s are converted to Markdown image links (`![AltText](path/to/image.png)`), using the path returned by `AssetExtractor`.
    *   Page breaks can be represented by `---` if elements cross page boundaries.

**Concurrency Model:**

*   The system is designed for parallel processing of PDF pages to enhance speed.
*   `PDFMarkdownConverter` uses Swift's `async/await` and `TaskGroup` to distribute page processing tasks across available CPU cores.
*   `PDFMarkdownConverterOptimized` uses Grand Central Dispatch (GCD) with concurrent queues and dispatch groups to manage parallelism.
*   `PDFMarkdownConverterUltraOptimized` also uses GCD, often with more aggressive pre-allocation and direct buffer manipulation.

**Key Integration Points:**

*   **Content Extraction Layer**: This logical layer connects the low-level PDF parsing (handled by PDFKit and custom extractors like `CGPDFImageExtractor`) with the structured `PDFElement` representation. It ensures that the hierarchy and formatting context are maintained during the transformation.
*   **Asset Management Layer**: This layer, primarily `AssetExtractor.swift`, links the extracted `CGImage` objects with their on-disk representation and ensures that the Markdown output contains correct references to these assets. It manages the organization of the assets folder and handles format conversions.

### Coding and Contribution Rules

We welcome contributions to `pdf22md`! Please follow these guidelines to ensure a smooth collaboration.

**Development Guidelines (from `CLAUDE.md` & `AGENTS.md`):**

*   **Focused Changes**: Only modify code directly relevant to the specific feature or bug you are addressing. Avoid unrelated refactoring in the same pull request.
*   **Complete Code**: Never replace functional code with placeholders (e.g., `# ... rest of the processing ...`). Ensure your submissions are complete.
*   **Incremental Approach**: Break down complex problems into smaller, manageable steps.
*   **Clear Reasoning**: If proposing significant changes, provide a clear plan with reasoning based on evidence from the code or observed behavior. Explain your observations and how your solution addresses the issue.
*   **AGENTS.md**: Be mindful of any instructions or guidelines present in `AGENTS.md` files within the directories you are working in.

**Technical Requirements & Conventions (from `CONTRIBUTING.md`):**

*   **Language**: Swift 5.7 or later.
*   **Platform**: macOS 12.0 or later.
*   **Package Manager**: The project uses Swift Package Manager (SPM). Ensure your changes integrate with the `Package.swift` manifest.
*   **Concurrency**: Utilize Swift's modern concurrency features (`async/await`, `Actors`) appropriately. For performance-critical sections where GCD is used, ensure thread safety and efficient dispatch.
*   **Code Style**:
    *   Adhere to [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
    *   Use SwiftFormat (if a configuration is provided) or maintain a consistent style with the existing codebase.
*   **Error Handling**:
    *   Use Swift's native `Error` protocol. Define custom error enums (like `PDFConversionError` in `PDFElement.swift`) for specific failure cases.
    *   Propagate errors using `throws` and handle them gracefully.
*   **Value Types**: Prefer `struct`s over `class`es where appropriate to leverage value semantics and improve memory safety, unless reference semantics are explicitly needed (e.g., for shared state managed by an actor).
*   **Testing**:
    *   All new features and bug fixes **must** be accompanied by unit tests and/or integration tests.
    *   Tests are located in `pdf22md/Tests/PDF22MDTests/`.
    *   Use XCTest framework for tests.

**Development Workflow:**

1.  **Fork & Clone**: Fork the repository on GitHub and clone your fork locally.
2.  **Create a Branch**: Create a new branch for your feature or bugfix (e.g., `feature/your-feature-name` or `bugfix/issue-123`).
3.  **Implement Changes**: Write your code, adhering to the guidelines above.
4.  **Write Tests**: Add tests to cover your. Ensure all existing and new tests pass.
    ```bash
    # From the pdf22md directory (containing Package.swift)
    swift test
    # Or using make from the root directory
    make test
    ```
5.  **Build the Project**: Verify that the project builds successfully.
    ```bash
    # From the pdf22md directory
    swift build -c release
    # Or using make from the root directory
    make build
    ```
6.  **Update Documentation**: If your changes affect functionality, usage, or the build process, update `README.md`, `CHANGELOG.md`, or other relevant documentation.
7.  **Commit Changes**: Write clear, concise, and descriptive commit messages.
8.  **Push to Your Fork**: Push your changes to your forked repository.
9.  **Open a Pull Request (PR)**: Submit a PR to the `main` branch of the original `twardoch/pdf22md` repository. Clearly describe the changes in your PR.

For more detailed contribution guidelines, please refer to `CONTRIBUTING.md`.

**Updating Changelog and TODO (as per `CLAUDE.md`):**

*   After completing a set of updates, remember to:
    *   Update `CHANGELOG.md` with a summary of the changes.
    *   Review `TODO.md`, remove completed items, and add any new tasks identified.
    *   Build the application (e.g., `make build` or `./build.sh`) to ensure everything is still working.
```
