# pdf22md TODO

> Flat list of actionable items for MVP 2.0. See [TASKS.md](TASKS.md) for full roadmap.

## Epoch 1: Foundation (CRITICAL)

- [ ] Fix xcode-select to point to Xcode.app (requires: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`)
- [ ] Verify `swift test` runs without infrastructure errors
- [x] Add unit tests for PDFElement types (TextElement, ImageElement) - tests updated for new API
- [x] Add unit tests for ProcessingOptions defaults - tests exist and verified
- [x] Add unit tests for FontStatistics calculations - tests updated for new API
- [ ] Add integration tests with testdata/ sample PDFs
- [x] Create GitHub Actions CI workflow for macOS
- [x] CI: Run swift build, swift test, example.sh

## Epoch 2: Refactoring (HIGH)

- [x] Extract FontAnalyzer from PDFMarkdownConverter.swift
- [x] Extract MarkdownGenerator from PDFMarkdownConverter.swift
- [x] Verify PDFMarkdownConverter.swift is under 200 lines
- [x] Extract TextExtractor from PDFPageProcessor.swift
- [x] Extract VectorGraphicsExtractor from PDFPageProcessor.swift
- [x] Verify PDFPageProcessor.swift is under 150 lines
- [-] Extract ProcessingOptionsBuilder from main.swift (minor - 26 lines)
- [-] Extract BatchProcessor from main.swift (blocked: async closure typing)
- [-] Verify main.swift is under 150 lines (deferred - currently 322)
- [x] Analyze shared code between 3 converter variants
- [x] Extract common converter utilities
- [x] Reduce duplication across converter variants by 50%+

## Epoch 3: Performance (MEDIUM)

- [x] Create benchmark.sh script for all 4 methods
- [ ] Measure: wall time, CPU time, memory, pages/sec
- [ ] Profile image extraction performance
- [ ] Parallelize XObject image extraction
- [ ] Implement streaming writes for images
- [ ] Profile memory for 100+ page PDFs
- [ ] Implement page-by-page streaming
- [ ] Add autoreleasepool in processing loops
- [ ] Target: stable memory regardless of PDF size

## Epoch 4: OCR (HIGH)

- [ ] Design OCR cache schema (~/.cache/pdf22md/ocr/)
- [ ] Implement cache key from PDF hash + page number
- [ ] Add cache lookup before OCR processing
- [ ] Add cache write after OCR processing
- [ ] Add --no-cache CLI flag
- [ ] Add --ocr-languages flag for language hints
- [ ] Add --ocr-level flag (fast/accurate)
- [ ] Implement optional image preprocessing pipeline
- [ ] Add --ocr-preprocess flag

## Epoch 5: AI (MEDIUM)

- [ ] Design prompt template format
- [ ] Implement template loading from ~/.config/pdf22md/prompts/
- [ ] Add --ai-prompt CLI flag
- [ ] Create default prompt templates (default, academic, legal)
- [ ] Add --ai-endpoint flag for custom endpoints
- [ ] Add --ai-model flag for local models
- [ ] Implement Ollama API format detection
- [ ] Implement llama.cpp server format detection
- [ ] Implement intelligent text chunking for large docs
- [ ] Handle partial AI failures gracefully

## Epoch 6: CLI/UX (MEDIUM)

- [ ] Implement progress bar for multi-page PDFs
- [ ] Show page count, elapsed time, ETA
- [ ] Suppress progress in quiet mode (-q)
- [ ] Add batch mode progress (file X of Y)
- [ ] Add --format flag (markdown, html, plain, json)
- [ ] Implement HTMLGenerator
- [ ] Implement PlainTextGenerator
- [ ] Implement JSONGenerator
- [ ] Design config file format (TOML)
- [ ] Implement config loading from ~/.config/pdf22md/config.toml
- [ ] Add --config flag for custom location
- [ ] Implement config + CLI flag precedence

## Epoch 7: Robustness (HIGH)

- [ ] Audit all catch blocks for empty handlers
- [ ] Ensure all errors have actionable messages
- [ ] Standardize user-facing error format
- [ ] Implement graceful OCR failure fallback
- [ ] Implement graceful AI failure fallback
- [ ] Implement graceful image extraction failure fallback
- [ ] Continue processing on single page failure
- [ ] Report all warnings at conversion end
- [ ] Validate PDF magic bytes before processing
- [ ] Validate output path is writable
- [ ] Validate DPI range (1-1200)
- [ ] Validate job count (1-256)

## Epoch 8: Documentation (MEDIUM)

- [ ] Update README with all CLI flags
- [ ] Add troubleshooting section to README
- [ ] Add performance tips section to README
- [ ] Keep README under 300 lines
- [ ] Add DocC documentation to public APIs
- [ ] Generate documentation site
- [ ] Create examples/batch-convert.sh
- [ ] Create examples/ocr-workflow.sh
- [ ] Create examples/python-integration.py

## Epoch 9: Future (DEFERRED)

- [ ] Evaluate web interface demand
- [ ] Research table detection approaches
- [ ] Evaluate Linux support feasibility
