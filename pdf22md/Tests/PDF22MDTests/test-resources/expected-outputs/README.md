Sure! Here's a cleaned-up and simplified version of the README.md file, with artificial fluff removed and the tone made more direct and lively, while preserving all useful information:

---

# pdf22md

MIT License · macOS 10.15+

[![Build and Release](image_004.png)](image_005.png)

A fast PDF to Markdown converter for macOS.

`pdf22md` extracts text and images from a PDF and outputs a clean Markdown document. It uses Grand Central Dispatch (GCD) to process pages and save images in parallel, making it quick even with large documents.

## Key Features

- **Fast conversion:** Leverages all CPU cores for concurrent page processing.
- **Smart headings:** Detects titles and headings based on font size and frequency.
- **Image extraction:** Saves raster and vector images to a folder and links them in the Markdown output.
- **Optimized image formats:** Uses JPEG for photos, PNG for graphics with transparency.
- **Flexible input/output:** Reads from a PDF file or stdin, writes to a Markdown file or stdout.
- **Custom DPI rasterization:** Set custom resolution when converting vector graphics.

## Installation

### Homebrew (Coming Soon)

```bash
brew tap twardoch/pdf22md
brew install pdf22md
```

### Build from Source

You’ll need Xcode Command Line Tools.

```bash
# Clone the repo
git clone https://github.com/twardoch/pdf22md.git
cd pdf22md

# Build
make

# Optional: Install to /usr/local/bin
sudo make install
```

### Pre-built Binary

Download from the [Releases page](https://github.com/twardoch/pdf22md/releases).

## Usage

```bash
pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
```

### Options

- `-i <path>`: Input PDF file (default: stdin)
- `-o <path>`: Output Markdown file (default: stdout)
- `-a <path>`: Folder to save extracted images
- `-d <dpi>`: DPI for rasterizing vector graphics (default: 144)

### Examples

```bash
# Basic conversion
pdf22md -i document.pdf -o document.md

# Save images to 'assets' folder
pdf22md -i report.pdf -o report.md -a ./assets

# Custom DPI
pdf22md -i presentation.pdf -o presentation.md -a ./images -d 300

# Pipe usage
cat document.pdf | pdf22md > document.md

# View output directly
pdf22md -i manual.pdf | less
```

## Requirements

- macOS 10.15 (Catalina) or later
- Xcode Command Line Tools (for building from source)

## Project Structure

```
pdf22md/
├── src/                  # Source code
│   ├── main.m            # Entry point
│   ├── PDFMarkdownConverter.*  # Core conversion logic
│   ├── PDFPageProcessor.*      # Page handling
│   ├── ContentElement.*        # Content structure
│   └── AssetExtractor.*       # Image extraction
├── docs/                 # Documentation
├── test/                 # Test files
├── LICENSE               # MIT License
├── Makefile              # Build script
└── README.md             # This file
```

## Contributing

Pull requests are welcome. For major changes, open an issue first.

1. Fork the repo  
2. Create your feature branch: `git checkout -b feature/AmazingFeature`  
3. Commit your changes: `git commit -m 'Add some AmazingFeature'`  
4. Push to the branch: `git push origin feature/AmazingFeature`  
5. Open a pull request

## License

MIT — see `LICENSE` for details.

## Acknowledgments

- Built with Apple’s PDFKit and Core Graphics
- Parallelized with Grand Central Dispatch
- Inspired by the need for speed and accuracy

## Related Projects

- [pdfplumber](https://github.com/jsvine/pdfplumber) – Python library for PDF text extraction
- [pdf2md](https://github.com/jzillmann/pdf-to-markdown) – Another PDF to Markdown tool
- [pandoc](https://pandoc.org) – Universal document converter

## Changelog

See `CHANGELOG.md` for version history.

## Support

Found a bug or have a question? [Open an issue on GitHub](https://github.com/twardoch/pdf22md/issues).

--- 

Let me know if you want a version tailored for a specific audience (e.g. developers, general users, etc.).