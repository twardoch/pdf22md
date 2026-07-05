# Usage

## Synopsis

```
pdf22md [-i input.pdf] [-o output.md] [-a assets/] [options]
```

If `-i` is omitted, pdf22md reads from stdin. If `-o` is omitted, Markdown is written to stdout.

---

## Options

### Input / Output

| Flag | Description |
|------|-------------|
| `-i, --input <path>` | Input PDF file path |
| `-o, --output <path>` | Output Markdown file path |
| `-a, --assets <path>` | Directory for extracted images |
| `-p, --password <pwd>` | Password for encrypted PDFs |

### Processing mode

| Flag | Description |
|------|-------------|
| _(default)_ | PDF text + Vision OCR |
| `--fast` | PDF text only — no Vision OCR |

### AI correction

| Flag | Description |
|------|-------------|
| `--ai` | Enable AI text correction |
| `--api <config>` | API config: `model:key@base_url` |
| `--apis <configs>` | Multiple APIs separated by `;` |
| `--ai-prompt <file>` | Custom prompt template (JSON) |
| `--dry-run` | Preview without writing output |

### OCR options

| Flag | Default | Description |
|------|---------|-------------|
| `--languages <codes>` | `en` | ISO 639 codes, comma-separated |
| `--threshold <n>` | `1.5` | Vision preference ratio over PDFKit |
| `--no-cache` | — | Disable OCR result caching |
| `--dpi <n>` | `144` | DPI for vector rasterisation |

### Batch mode

| Flag | Description |
|------|-------------|
| `--batch` | Process all PDFs in input directory |
| `-j, --jobs <n>` | Parallel job count (default: CPU count) |
| `--max-pages <n>` | Limit pages processed per file |

### Output control

| Flag | Description |
|------|-------------|
| `-v, --verbose` | Show warnings and AI input/output |
| `-q, --quiet` | Suppress non-error output |
| `--progress` | Show per-page progress with ETA |

---

## Examples

### Basic conversion

```bash
# Digital PDF — text + images
pdf22md -i paper.pdf -o paper.md -a ./paper-assets

# Pipe via stdin/stdout
cat report.pdf | pdf22md > report.md
```

### Fast mode (skip Vision OCR)

```bash
pdf22md -i document.pdf -o document.md --fast
```

Use this when the PDF was digitally created and you do not need OCR. Typically 3–10× faster.

### Vision OCR with explicit language

```bash
# French + German document
pdf22md -i notice.pdf -o notice.md --languages fr,de

# Chinese OCR
pdf22md -i manual.pdf -o manual.md --languages zh-Hans
```

### AI correction

```bash
# Using OpenAI
pdf22md -i scanned.pdf -o clean.md --ai \
        --api "gpt-4o:sk-xxx@https://api.openai.com/v1"

# Preview estimated cost before running
pdf22md -i scanned.pdf --dry-run --ai \
        --api "gpt-4o:sk-xxx@https://api.openai.com/v1"

# Apple Intelligence (macOS 15.1+, no API key needed)
pdf22md -i scanned.pdf -o clean.md --ai
```

### High-quality image extraction

```bash
# 300 DPI for print-quality vector rasterisation
pdf22md -i slides.pdf -o slides.md -a ./img -d 300
```

### Batch processing

```bash
# Convert all PDFs in a directory, 4 parallel jobs
pdf22md --batch -i ./pdfs/ -o ./output/ -a ./assets/ -j 4
```

### Password-protected PDFs

```bash
pdf22md -i confidential.pdf -o output.md --password "s3cr3t"
```

---

## Prompt template (AI customisation)

Create a JSON file matching the `PromptTemplate` format to override the default AI instructions. Pass it with `--ai-prompt prompt.json`.

See `pdf22md/examples/` for the bundled templates:

- `default-prompt.json` — general text correction
- `academic-prompt.json` — preserves citations, formulae references
- `legal-prompt.json` — preserves clause numbering and defined terms

---

## Troubleshooting

### `No such module 'XCTest'` when building tests

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Vision OCR returns empty text

- Confirm the page actually contains scanned images (not digital text)
- Raise DPI: `--dpi 300`
- Specify the correct language: `--languages <code>`

### AI correction produces garbled output

The built-in `TextValidator` (cosine word-similarity ≥ 0.85) will reject hallucinated responses and fall back to the raw extracted text. If you see warnings about validation failures, the AI is likely changing the text too aggressively — try a smaller, more focused prompt template.

### OCR results look stale

Use `--no-cache` to bypass the on-disk cache at `~/.cache/pdf22md/ocr/`.
