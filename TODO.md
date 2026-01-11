# TODO: PDF22MD

## Completed Features

### Vision OCR + AI Enhancement (v1.6.0)
- [x] Vision Framework OCR integration (VisionTextExtractor)
- [x] AI text correction with sliding window (AITextProcessor)
- [x] OpenAI-compatible API client (OpenAIClient)
- [x] CLI options: `--fast`, `--ai`, `--api`, `--languages`, `--verbose`
- [x] Smart text selection (Vision vs PDF based on content length)
- [x] Progress reporting with `--verbose` flag
- [x] Input validation with clear error messages
- [x] Unit tests for API parsing, text selection, serialization
- [x] CLI option: `--max-pages` to limit pages processed
- [x] CLI option: `--threshold` to customize Vision vs PDF text selection

## Completed

### Apple Intelligence (requires macOS 26+)
- [x] Create `AppleIntelligenceProcessor.swift` with stub implementation
- [x] Implement `@available(macOS 26.0, *)` availability check (in comments)
- [x] Add future implementation template for FoundationModels API

### Additional Testing
- [ ] Integration tests for AI processing pipeline
- [ ] Test with scanned PDF documents (OCR-only)
- [ ] Test AI mode with external API (OpenAI/Claude/Ollama)

### Future Features
- [NOT NOW] Batch processing for multiple PDFs
- [NOT NOW] Password-protected PDF support
- [NOT NOW] OCR result caching

## Notes

- Vision OCR can be slow for multi-page PDFs
- Fast mode (`--fast`) recommended for PDFs with good text layers
- AI processing requires external API or macOS 26+ for Apple Intelligence
- Test PDFs available in `testdata/pdf/`
