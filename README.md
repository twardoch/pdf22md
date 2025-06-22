# pdf22md

A blazingly fast PDF to Markdown converter for macOS.

`pdf22md` is a command-line tool that extracts all text and image content from a PDF file and converts it into a clean Markdown document. It uses Grand Central Dispatch (GCD) to process pages and save images in parallel, making it exceptionally fast for multi-page documents.

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

# Compile the tool
make

# Install it to /usr/local/bin
sudo make install
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
# Convert a local PDF file and save images to an 'assets' folder
pdf22md -i report.pdf -o report.md -a ./assets
```
