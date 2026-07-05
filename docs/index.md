# pdf22md

**pdf22md** converts PDF files to clean Markdown on macOS. It uses PDFKit for digital text, Vision OCR for scanned pages, and optionally an AI API (OpenAI-compatible or Apple Intelligence) to correct extraction artefacts.

## Quick start

```bash
# Build
git clone https://github.com/twardoch/pdf22md.git
cd pdf22md
make build

# Convert a PDF (text + images extracted)
pdf22md -i paper.pdf -o paper.md -a ./assets

# Fast mode — PDF text only, no Vision OCR
pdf22md -i document.pdf -o document.md --fast

# AI correction via OpenAI
pdf22md -i scanned.pdf -o cleaned.md --ai \
        --api "gpt-4o:sk-xxx@https://api.openai.com/v1"
```

## Requirements

| Component | Minimum |
|-----------|---------|
| macOS     | 12.0    |
| Swift     | 5.7     |
| Xcode CLT | any     |

## Installation

```bash
# From source
make build
sudo make install
```

Homebrew tap coming soon.

## Key features

- **Concurrent extraction** — all pages processed in parallel via Swift's structured concurrency
- **Vision OCR** — automatic fallback for scanned or image-only pages
- **AI correction** — optional multi-pass pipeline fixing hyphenation, OCR noise, and formatting
- **Smart headings** — font-size analysis to emit `#`/`##`/`###` Markdown headings
- **Image extraction** — raster XObjects and vector graphics rasterised at configurable DPI
- **Batch mode** — process entire directories with `-j` parallel jobs
- **Password support** — open encrypted PDFs with `--password`
- **OCR caching** — Vision results cached in `~/.cache/pdf22md/ocr/`

See [Conversion Quality](quality.md) for a realistic picture of what to expect from each extraction method.
