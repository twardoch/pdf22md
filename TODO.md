# pdf22md TODO

> Future improvements for pdf22md. See [CHANGELOG.md](CHANGELOG.md) for completed work.

## P1: High Impact

### Performance
- [ ] Replace VectorGraphicsExtractor O(n^2) grid scanning with content stream analysis
- [ ] Parallelize XObject image extraction
- [ ] Profile memory for 100+ page PDFs

### CLI/UX
- [ ] Add `--json` output flag for scripting
- [ ] Add `--format` flag (markdown, html, plain, json)

### Error Handling
- [ ] Audit all catch blocks for empty handlers
- [ ] Validate PDF magic bytes before processing

## P2: Medium Impact

### AI Improvements
- [ ] Add `--ai-endpoint` flag for custom endpoints
- [ ] Add `--ai-model` flag for local models
- [ ] Implement Ollama API format detection

### Output Formats
- [ ] Implement HTMLGenerator
- [ ] Implement PlainTextGenerator
- [ ] Implement JSONGenerator

### Configuration
- [ ] Add config file support (~/.config/pdf22md/config.toml)
- [ ] Add `--config` flag for custom location

### OCR
- [ ] Add `--ocr-level` flag (fast/accurate)
- [ ] Add optional image preprocessing pipeline

## P3: Nice to Have

### Documentation
- [ ] Add DocC documentation to public APIs
- [ ] Create example scripts (batch-convert, python-integration)

### Future
- [ ] Evaluate web interface demand
- [ ] Research table detection approaches
- [ ] Evaluate Linux support feasibility
