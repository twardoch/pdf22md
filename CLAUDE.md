# pdf22md

A blazingly fast PDF to Markdown converter for macOS, available in two implementations: `pdf21md` (Objective-C) and `pdf22md` (Swift).

`pdf21md` and `pdf22md` are command-line tools that extract all text and image content from a PDF file and convert it into a clean Markdown document. The Objective-C version (`pdf21md`) uses Grand Central Dispatch (GCD) while the Swift version (`pdf22md`) uses modern async/await for parallel processing, making both exceptionally fast for multi-page documents.

### Key Features

  * **High-Speed Conversion**: Uses all available CPU cores to process PDF pages concurrently.
  * **Intelligent Heading Detection**: Analyzes font sizes and usage frequency to automatically format titles and headings (`#`, `##`, etc.).
  * **Asset Extraction**: Saves raster and vector images into a specified assets folder and links them correctly in the Markdown file.
  * **Smart Image Formatting**: Automatically chooses between JPEG (for photos) and PNG (for graphics with transparency) to optimize file size and quality.
  * **Flexible I/O**: Reads from a PDF file or `stdin` and writes to a Markdown file or `stdout`.
  * **Customizable Rasterization**: Allows setting a custom DPI for converting vector graphics to bitmaps.

### Installation

Once the Homebrew tap is set up (see plan below), installation is simple:

```bash
brew install <your-username>/pdf22md/pdf22md
```

### Building from Source

To build the project manually, you need Xcode Command Line Tools installed.

```bash
# Clone the repository (once it's public)
git clone https://github.com/<your-username>/pdf22md.git
cd pdf22md

# For Objective-C version (pdf21md)
cd pdf21md
make
sudo make install

# For Swift version (pdf22md)
cd ../pdf22md
swift build -c release
sudo cp .build/release/pdf22md /usr/local/bin/
```

### Usage

```
Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
  Converts PDF documents to Markdown format
  -i <path>: Input PDF file (default: stdin)
  -o <path>: Output Markdown file (default: stdout)
  -a <path>: Assets folder for extracted images
  -d <dpi>: DPI for rasterizing vector graphics (default: 144)
```

**Example:**

```bash
# Convert using Objective-C version
pdf21md -i report.pdf -o report.md -a ./assets

# Or using Swift version
pdf22md -i report.pdf -o report.md -a ./assets
```

---


# main-overview

## Development Guidelines

- Only modify code directly relevant to the specific request. Avoid changing unrelated functionality.
- Never replace code with placeholders like `# ... rest of the processing ...`. Always include complete code.
- Break problems into smaller steps. Think through each step separately before implementing.
- Always provide a complete PLAN with REASONING based on evidence from code and logs before making changes.
- Explain your OBSERVATIONS clearly, then provide REASONING to identify the exact issue. Add console logs when needed to gather more information.


pdf22md is a PDF to Markdown converter that transforms PDF documents while preserving their semantic structure and content relationships.

Core Business Components:

1. Document Structure Analysis (Importance: 95)
- Hierarchical heading detection using font statistics
- Document structure preservation through positional element sorting
- Automated heading level assignment (H1-H6) based on font usage patterns

2. Content Classification System (Importance: 85)
- TextElement: Handles formatted text with style attributes
- ImageElement: Manages both raster and vector graphics
- Content relationship tracking between elements

3. Asset Processing Pipeline (Importance: 80)
- Intelligent format selection between PNG/JPEG based on:
  * Transparency detection
  * Color complexity analysis
  * Dimension-based optimization
- Asset extraction with maintained document references

4. PDF Content Processing (Importance: 90)
- Text styling and formatting context preservation
- Vector graphics path construction tracking
- Coordinate system transformation management
- Element bounds calculation for layout fidelity

Key Integration Points:

1. Content Extraction Layer
- Connects PDF parsing with markdown generation
- Maintains element relationships and hierarchy
- Preserves formatting context across transformations

2. Asset Management Layer
- Links extracted images with markdown references
- Maintains asset organization structure
- Handles format conversions while preserving quality

The system organizes business logic around content transformation pipelines while maintaining document semantic structure throughout the conversion process.

—— When you’re done with a round of updates, update CHANGELOG.md with the changes, remove done things from TODO.md, identify new things that need to be done and add them to TODO.md. Then build the app or run ./release.sh and then continue updates. 