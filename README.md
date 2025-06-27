# pdf22md: Your Fast PDF to Markdown Converter

Tired of manually copying text and images from PDFs? `pdf22md` is a powerful tool that automatically converts your PDF documents into clean, readable Markdown files. It's designed for speed and accuracy, making it perfect for researchers, developers, and anyone who needs to repurpose content from PDFs.

## What Does It Do?

`pdf22md` takes your PDF files and transforms them into Markdown, a simple formatting language that's easy to read and convert into other formats like HTML or Word documents. It intelligently extracts:

-   **Text**: All readable text from your PDF.
-   **Headings**: Automatically detects titles and headings (like `## Section Title`) based on font sizes.
-   **Images**: Extracts images and saves them to a separate folder, linking them correctly in your Markdown file. It even chooses the best image format (JPEG for photos, PNG for graphics) to keep file sizes small.

## Why Use pdf22md?

-   **Blazing Fast**: `pdf22md` uses all available processing power to convert even large PDFs quickly.
-   **Accurate**: It's smart about how it extracts content, preserving the structure and readability of your document.
-   **Easy to Use**: Simple commands get your PDFs converted in no time.
-   **Flexible**: Works with both single files and multiple documents, and you can even pipe content directly into it.

## How It Works (A Little Technical Detail)

`pdf22md` is unique because it offers two highly optimized versions:

-   **Objective-C Version (`pdf21md`)**: A mature, robust implementation built for maximum performance on macOS.
-   **Swift Version (`pdf22md`)**: A modern, type-safe implementation using the latest Swift features, designed for future development and integration into other Swift projects.

Both versions share the same core goal: to give you the fastest, most accurate PDF to Markdown conversion possible.

## Get Started Quickly

### Installation

Currently, you can build `pdf22md` from its source code. Homebrew installation will be available soon for easier setup!

#### Build from Source (Recommended)

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/twardoch/pdf22md.git
    cd pdf22md
    ```
2.  **Run the build script**: This script will build both the Objective-C and Swift versions.
    ```bash
    ./build.sh
    ```
    After a successful build, you'll find the executables in `pdf21md/pdf21md` (Objective-C) and `pdf22md/.build/release/pdf22md` (Swift).

### Basic Usage

Once installed, you can use `pdf22md` from your terminal:

```bash
# Convert a PDF file and save the Markdown output
pdf22md -i your_document.pdf -o output.md

# Extract images to a subfolder named 'assets'
pdf22md -i your_document.pdf -o output.md -a ./assets

# Convert a PDF and pipe the output directly to your screen
cat your_document.pdf | pdf22md
```

#### Command Line Options:

```
Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
  Converts PDF documents to Markdown format.
  -i <path>: Input PDF file (default: stdin)
  -o <path>: Output Markdown file (default: stdout)
  -a <path>: Assets folder for extracted images (optional)
  -d <dpi>: DPI for rasterizing vector graphics (default: 144, optional)
```

## Requirements

-   macOS 10.12 or later
-   Xcode Command Line Tools (for building from source)
-   For Swift version: macOS 12.0+ and Swift 5.7+

## Performance

`pdf22md` is engineered for speed:

-   **Parallel Processing**: It uses all available CPU cores to process PDF pages simultaneously.
-   **Efficient Memory Use**: Designed to handle large documents without hogging your system's memory.
-   **Smart Optimizations**: Includes intelligent algorithms for font analysis and image handling.

## Need More Details?

-   **For Developers**: Check out `CONTRIBUTING.md` (coming soon) for in-depth technical explanations and contribution guidelines.
-   **Specific Implementations**:
    -   [Objective-C Version Details](./pdf21md/README.md)
    -   [Swift Version Details](./pdf22md/README.md)
-   **Parallel Processing**: Learn more about how `pdf22md` achieves its speed in [PARALLEL_PROCESSING.md](./docs/PARALLEL_PROCESSING.md).

## License

`pdf22md` is released under the MIT License. See the [LICENSE](LICENSE) file for details.
