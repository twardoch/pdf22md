---
title: "README.md"
creator: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0"
producer: "Skia/PDF m137"
created: 2025-06-23T01:33:53+02:00
modified: 2025-06-23T01:33:53+02:00
pdf_metadata:
  page_count: 2
conversion:
  tool: "pdf22md"
  version: "v1.1.0-dirty"
  date: 2025-06-23T02:28:31+02:00
---

23/06/2025, 01:33 README.md

![Image](image_000.png)

![Image](image_001.png)

pdf22md

MIT

License MIT

License

10.15+

![Image](image_002.png)

![Image](image_003.png)

macOS 10.15+

macOS

Build and Release Build and Release passing passing

A blazingly fast PDF to Markdown converter for macOS.

pdf22md is a command-line tool that extracts all text and image content from a PDF file and converts it into a

![Image](image_004.png)

![Image](image_005.png)

![Image](image_006.png)

clean Markdown document. It uses Grand Central Dispatch (GCD) to process pages and save images in

parallel, making it exceptionally fast for multi-page documents.

Key Features

High-Speed Conversion: Uses all available CPU cores to process PDF pages concurrently

Intelligent Heading Detection: Analyzes font sizes and usage frequency to automatically format titles

![Image](image_007.png)

![Image](image_008.png)

![Image](image_009.png)

and headings ( # , ## , etc.)

Asset Extraction: Saves raster and vector images into a specified assets folder and links them correctly

in the Markdown file

Smart Image Formatting: Automatically chooses between JPEG (for photos) and PNG (for graphics with

transparency) to optimize file size and quality

Flexible I/O: Reads from a PDF file or stdin and writes to a Markdown file or stdout

![Image](image_010.png)

![Image](image_011.png)

![Image](image_012.png)

Customizable Rasterization: Allows setting a custom DPI for converting vector graphics to bitmaps

Installation

Using Homebrew (Coming Soon)

brew tap twardoch/pdf22md

brew install pdf22md

![Image](image_013.png)

![Image](image_014.png)

Building from Source

To build the project manually, you need Xcode Command Line Tools installed.

# Clone the repository

git clone https://github.com/twardoch/pdf22md.git

cd pdf22md

# Compile the tool

make

# Install it to /usr/local/bin (optional)

sudo make install

Download Pre-built Binary

Pre-built binaries are available from the Releases page.

Usage

Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets

_

folder] [-d dpi]

Converts PDF documents to Markdown format

-i <path>: Input PDF file (default: stdin)

-o <path>: Output Markdown file (default: stdout)

-a <path>: Assets folder for extracted images

-d <dpi>: DPI for rasterizing vector graphics (default: 144)

Examples

# Convert a PDF file to Markdown

pdf22md -i document.pdf -o document.md

# Convert with images saved to an 'assets' folder

pdf22md -i report.pdf -o report.md -a ./assets

# Convert with custom DPI for vector graphics

pdf22md -i presentation.pdf -o presentation.md -a ./images -d 300

# Use with pipes

cat document.pdf | pdf22md > document.md

# Convert and view in less

pdf22md -i manual.pdf | less

Requirements

macOS 10.15 (Catalina) or later

Xcode Command Line Tools (for building from source)

Project Structure

pdf22md/

├── src/ # Source code

│ ├── main.m # Entry point

│ ├── PDFMarkdownConverter.* # Main conversion logic

│ ├── PDFPageProcessor.* # PDF page processing

│ ├── ContentElement.* # Content element definitions

│ └── AssetExtractor.* # Image extraction logic

├── docs/ # Additional documentation

├── test/ # Test files

file:///Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/README.md 1/2

23/06/2025, 01:33 README.md

![Image](image_015.png)

![Image](image_016.png)

├── LICENSE # MIT License

├── Makefile # Build configuration

└── README.md # This file

Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an

![Image](image_017.png)

![Image](image_018.png)

![Image](image_019.png)

issue first to discuss what you

would like to change.

1. Fork the repository

2. Create your feature branch ( git checkout -b feature/AmazingFeature )

3. Commit your changes ( git commit -m 'Add some AmazingFeature' )

![Image](image_020.png)

![Image](image_021.png)

![Image](image_022.png)

4. Push to the branch ( git push origin feature/AmazingFeature )

5. Open a Pull Request

License

This project is licensed under the MIT License - see the LICENSE file for details.

Acknowledgments

![Image](image_023.png)

![Image](image_024.png)

![Image](image_025.png)

![Image](image_026.png)

![Image](image_027.png)

Built with Apple’s PDFKit and Core Graphics frameworks

Parallel processing powered by Grand Central Dispatch (GCD)

Inspired by the need for fast, accurate PDF to Markdown conversion

Related Projects

pdfplumber - Python library for PDF processing

![Image](image_028.png)

pdf2md - Another PDF to Markdown converter

![Image](image_029.png)

![Image](image_030.png)

![Image](image_031.png)

![Image](image_032.png)

pandoc - Universal document converter

Changelog

See CHANGELOG.md for a list of changes in each version.

Support

If you encounter any issues or have questions, please open an issue on GitHub.

![Image](image_033.png)

![Image](image_034.png)

file:///Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/README.md 2/2