# Conversion Quality and Limitations

pdf22md layers three extraction methods. Each has distinct quality characteristics and failure modes.

---

## Method 1 — PDFKit text extraction (always active)

PDFKit's `attributedString(for:)` API reads the text layer embedded in the PDF content stream. It is the fastest path and the default source of truth.

### When it works well

- Digitally created PDFs (exported from Word, LaTeX, InDesign, Pages, Keynote)
- PDFs with embedded Unicode font mappings (`ToUnicode` CMap)
- Single-column documents with straightforward reading order

### Known limitations

| Issue | Cause | Workaround |
|-------|-------|-----------|
| Garbled or empty text | Missing `ToUnicode` map; fonts encoded with non-standard glyph IDs | Enable Vision OCR (omit `--fast`) |
| Wrong reading order | PDFKit returns text in content-stream order, not visual order | Use `--fast` off — Vision OCR reads visually |
| Ligatures split oddly | PDFKit decomposes `ﬁ`, `ﬄ` etc. inconsistently | Enable AI correction to rejoin them |
| Hyphenation artefacts | Hard hyphens from line-breaking remain in the output | Enable AI correction (`--ai`) |
| Multi-column confusion | Columns merged into a single stream | Enable Vision OCR; AI correction helps further |
| Header/footer noise | Running headers and page numbers appear inline | Manual post-processing or AI correction |

---

## Method 2 — Vision OCR (default, disable with `--fast`)

When PDFKit text is absent or suspiciously short (by default: Vision text is ≥ 1.5× longer), the Vision framework rasterises the page and runs `VNRecognizeTextRequest` on it.

### When it works well

- Scanned documents (photographed or photocopied paper)
- PDFs composed entirely of images (no text layer at all)
- Documents where PDFKit returns garbled content

### Known limitations

| Issue | Cause | Workaround |
|-------|-------|-----------|
| Slower processing | Full page rasterisation + neural network inference | Use `--fast` when you know text is digital |
| OCR errors on low-quality scans | Poor contrast, skew, or resolution below ~150 DPI | Pre-process scans; use `--dpi 300` |
| Right-to-left scripts | Vision primarily targets left-to-right languages | Results may be reversed; manual review required |
| Mathematical notation | Formulae recognised as approximate text strings | No automatic fix; AI correction has limited help |
| Tables | Column alignment lost; cells merged or split | No structural table output; plain text only |
| Handwriting | Vision's `accurate` model handles print only | Handwritten text is unreliable |
| Language coverage | Accuracy drops for uncommon or mixed-script pages | Specify `--languages` explicitly; add all relevant codes |

The `--threshold` option (default `1.5`) controls when Vision text wins over PDFKit text. Raise it to trust PDFKit more; lower it to prefer Vision more aggressively.

OCR results are cached by PDF content hash in `~/.cache/pdf22md/ocr/` so re-processing the same file is instant. Use `--no-cache` to force re-extraction.

---

## Method 3 — AI text correction (opt-in with `--ai`)

An OpenAI-compatible chat completion API (or Apple Intelligence) receives raw extracted text page-by-page and returns a corrected version. The multi-pass pipeline (V3) runs three specialised prompts: dehyphenation, OCR error correction, and final cleanup.

### When it works well

- Scanned documents with occasional character errors
- PDFs with hard hyphens from automated line-breaking
- Lightly corrupted text that retains word boundaries

### Known limitations

| Issue | Cause | Workaround |
|-------|-------|-----------|
| Hallucination | The AI invents words not in the source | `TextValidator` cosine similarity check (0.85 threshold) rejects bad responses and falls back to raw text |
| Slow for large documents | Sequential API calls per page group | Use `--jobs` for batch mode; one AI call per file runs sequentially by design |
| Cost | GPT-4o: ~$0.03/1K tokens, ~1K tokens/page | Use `--dry-run` to preview estimated cost before committing |
| Context window exceeded | Very long pages overflow the model's context | Automatic `ParagraphChunker` splits at sentence boundaries with 15% overlap |
| Apple Intelligence availability | Requires macOS 15.1+ with model downloaded | Check Settings → Apple Intelligence; falls back to error if unavailable |
| Non-English content | Prompts are English; correction quality drops for other languages | Use an OpenAI-compatible endpoint with a multilingual model |

---

## Heading detection

Font-size analysis (`FontStatistics`) identifies the most common font size as body text. Sizes larger than body are mapped to `#`, `##`, or `###` headings. This is a frequency heuristic, not semantic analysis.

**Limitations:**

- All-caps text at body size is not promoted to headings
- Documents that use bold (not size) to mark headings produce no heading markup
- Variable-size footnotes may be misclassified as sub-headings

---

## Image extraction

Raster images are extracted from PDF XObject streams (`/Subtype /Image`) using CoreGraphics. Vector graphics pages are rasterised to PNG at the DPI you specify (default 144, raise to 300 for print quality).

**Limitations:**

- Images inside form XObjects (nested PDF structures) may be missed
- Very large images are held in memory simultaneously during extraction
- Vector extraction re-rasterises the entire page, which captures decorative backgrounds too

---

## Output format

Output is plain Markdown (`*.md`). No tables, no footnotes, no math notation — only paragraphs, headings (`#`/`##`/`###`), bold, italic, and image references. Documents that rely heavily on these structural elements will lose formatting fidelity.
