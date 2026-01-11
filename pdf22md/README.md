# pdf22md

A PDF to Markdown converter written in Swift, using modern concurrency features.

## Features

- **Modern Swift**: Uses async/await, actors, and result builders from Swift 5.7+
- **Structured Concurrency**: Processes pages concurrently with TaskGroup
- **Vision Framework OCR**: Extracts text from scanned PDFs using Apple Vision
- **AI Text Correction**: Optional AI-powered text cleanup via OpenAI-compatible APIs or Apple Intelligence
- **Smart Text Selection**: Automatically chooses best text source (PDF or OCR)
- **Memory Safe**: Leverages Swift's automatic memory management and value types

## Building

```bash
# Build the project
swift build

# Build optimized release version
swift build -c release

# Run tests
swift test

# Install executable
cp .build/release/pdf22md /usr/local/bin/pdf22md
```

## Usage

### Command Line

```bash
# Basic conversion (uses Vision OCR for best text extraction)
pdf22md -i document.pdf -o document.md

# Fast mode (PDF text only, no Vision OCR)
pdf22md -i document.pdf -o document.md --fast

# Extract images into an assets folder
pdf22md -i report.pdf -o report.md -a ./assets

# Set custom DPI for image rendering
pdf22md -i large.pdf -o large.md -d 300

# Use with pipes
cat document.pdf | pdf22md > document.md

# Enable AI text correction with external API
pdf22md -i scanned.pdf -o clean.md --ai --api gpt-4o:sk-xxx@https://api.openai.com/v1

# Enable AI text correction (uses Apple Intelligence if available)
pdf22md -i document.pdf -o document.md --ai

# Specify languages for Vision OCR
pdf22md -i french.pdf -o french.md --languages fr,en
```

### CLI Options

| Option | Description |
|--------|-------------|
| `-i, --input` | Input PDF file (default: stdin) |
| `-o, --output` | Output Markdown file (default: stdout) |
| `-a, --assets` | Assets folder for extracted images |
| `-d, --dpi` | DPI for rasterizing vector graphics (default: 144) |
| `--fast` | Fast mode: use PDF text only, skip Vision OCR |
| `--ai` | Enable AI text correction |
| `--api` | AI API in format `model:api_key@base_url` |
| `--languages` | Languages for Vision OCR (comma-separated ISO 639 codes) |
| `-v, --verbose` | Show progress during conversion |
| `--optimized` | Use GCD implementation |
| `--ultra-optimized` | Use aggressive optimization |

### API Format

The `--api` option accepts a string in the format: `model:api_key@base_url`

Examples:
- OpenAI: `gpt-4o:sk-xxx@https://api.openai.com/v1`
- Anthropic: `claude-3-haiku:sk-ant-xxx@https://api.anthropic.com/v1`
- Local Ollama: `llama3:@http://localhost:11434/v1`

You can also set the `PDF22MD_API` environment variable instead of using `--api`.

### Processing Modes

| Mode | Flags | Description |
|------|-------|-------------|
| Standard | (default) | PDF + Vision OCR, selects best text |
| Fast | `--fast` | PDF text only, fastest |
| AI (External) | `--ai --api ...` | PDF + Vision + AI correction via API |
| AI (Local) | `--ai` | PDF + Vision + Apple Intelligence |

### In Code

```swift
import PDF22MD

// Basic conversion (fast mode)
let converter = PDFMarkdownConverter(
    pdfURL: inputURL,
    outputPath: outputPath,
    assetsPath: assetsPath,
    dpi: 144
)
try await converter.convert()

// Enhanced conversion with Vision and AI
var options = ProcessingOptions()
options.fastMode = false
options.enableAI = true
options.apiConfig = try APIConfiguration.parse("gpt-4o:sk-xxx@https://api.openai.com/v1")

let converter = PDFMarkdownConverter(
    pdfURL: inputURL,
    outputPath: outputPath,
    assetsPath: assetsPath,
    options: options
)
try await converter.convertEnhanced()
```

## How It Works

1. **PDF Text Extraction**: Always extracts text using PDFKit's `attributedString` (Fn)
2. **Vision OCR** (unless `--fast`): Renders each page to image and runs Vision text recognition (Vn)
3. **Text Selection**: If Vision text is significantly longer (>50% more), uses Vision text
4. **AI Processing** (if `--ai`): Sequential sliding-window correction where each page is processed with context from the previous page
5. **Markdown Generation**: Converts to Markdown with heading detection based on font sizes

## Requirements

- macOS 12.0+ (Vision Framework)
- macOS 26+ (Apple Intelligence, optional)
- Swift 5.7+

## License

MIT
