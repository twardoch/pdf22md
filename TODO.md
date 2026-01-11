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

## Optional Enhancements

### Apple Intelligence (requires macOS 26+)
- [ ] Create `AppleIntelligenceProcessor.swift` with `#if canImport(FoundationModels)`
- [ ] Implement `@available(macOS 26.0, *)` availability check

### Additional Testing
- [ ] Integration tests for AI processing pipeline
- [ ] Test with scanned PDF documents (OCR-only)
- [ ] Test AI mode with external API (OpenAI/Claude/Ollama)

### Future Features
- [ ] Batch processing for multiple PDFs
- [ ] Password-protected PDF support
- [ ] OCR result caching

## Notes

- Vision OCR can be slow for multi-page PDFs
- Fast mode (`--fast`) recommended for PDFs with good text layers
- AI processing requires external API or macOS 26+ for Apple Intelligence
- Test PDFs available in `testdata/pdf/`
