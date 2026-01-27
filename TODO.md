# pdf22md TODO

> Flat list of actionable items for MVP 2.0. See [TASKS.md](TASKS.md) for full roadmap.

## P0: Critical (Blocks Development)

- [ ] Fix xcode-select: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- [ ] Verify `swift test` runs without infrastructure errors
- [ ] Add integration tests with testdata/ sample PDFs

## P1: High Impact

### Performance
- [ ] Replace VectorGraphicsExtractor O(n²) grid scanning with content stream analysis
- [ ] Parallelize XObject image extraction
- [ ] Implement streaming writes for images
- [ ] Profile memory for 100+ page PDFs

### CLI/UX
- [ ] Implement progress bar with ETA for multi-page PDFs
- [ ] Add `--dry-run` flag to preview conversion
- [ ] Add `--json` output flag for scripting

### Error Handling
- [ ] Audit all catch blocks for empty handlers
- [ ] Ensure all errors have actionable messages
- [ ] Validate PDF magic bytes before processing

## P2: Medium Impact

### AI Improvements
- [ ] Add `--ai-endpoint` flag for custom endpoints
- [ ] Add `--ai-model` flag for local models
- [ ] Implement Ollama API format detection
- [ ] Better token estimation (consider tiktoken)

### Output Formats
- [ ] Add `--format` flag (markdown, html, plain, json)
- [ ] Implement HTMLGenerator
- [ ] Implement PlainTextGenerator
- [ ] Implement JSONGenerator

### Configuration
- [ ] Design config file format (TOML)
- [ ] Implement config loading from ~/.config/pdf22md/config.toml
- [ ] Add `--config` flag for custom location

### OCR
- [ ] Add `--ocr-level` flag (fast/accurate)
- [ ] Implement optional image preprocessing pipeline
- [ ] Add `--ocr-preprocess` flag

## P3: Nice to Have

### Documentation
- [ ] Add DocC documentation to public APIs
- [ ] Generate documentation site
- [ ] Create examples/batch-convert.sh
- [ ] Create examples/ocr-workflow.sh
- [ ] Create examples/python-integration.py

### Future
- [ ] Evaluate web interface demand
- [ ] Research table detection approaches
- [ ] Evaluate Linux support feasibility

---

## Recently Completed (v1.7.0)

### AI V3 Multi-Pass
- [x] TextValidator with word frequency cosine similarity (0.85 threshold)
- [x] ParagraphChunker for sentence-aware splitting (≤3500 chars)
- [x] PassPrompts: 3 simple passes (dehyphenation, OCR correction, cleanup)
- [x] MultiPassProcessor orchestrating pipeline with validation fallback
- [x] Word retention improved from 78% (V2) to 93% (V3)

### Code Refactoring
- [x] Extract FontAnalyzer from PDFMarkdownConverter.swift
- [x] Extract MarkdownGenerator from PDFMarkdownConverter.swift
- [x] Extract TextExtractor from PDFPageProcessor.swift
- [x] Extract VectorGraphicsExtractor from PDFPageProcessor.swift
- [x] Consolidate converter variants (removed Optimized/UltraOptimized)
- [x] PDFMarkdownConverter.swift: 393→199 lines
- [x] PDFPageProcessor.swift: 317→150 lines

### Infrastructure
- [x] GitHub Actions CI workflow (swift build, swift test)
- [x] example.sh benchmark script
- [x] Unit tests for PDFElement, ProcessingOptions, FontStatistics

### OCR
- [x] OCR result caching (~/.cache/pdf22md/ocr/)
- [x] --no-cache CLI flag
- [x] --languages flag for language hints

### Robustness
- [x] AI multi-provider failover
- [x] Validation fallback (reject bad AI output)
- [x] DPI range validation (1-1200)
- [x] Job count validation (1-256)
