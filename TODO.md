# TODO: PDF22MD

## Completed (v1.6.0)

- [x] Vision Framework OCR integration (VisionTextExtractor)
- [x] AI text correction with sliding window (AITextProcessor)
- [x] OpenAI-compatible API client (OpenAIClient)
- [x] AppleIntelligenceProcessor stub for macOS 26+
- [x] CLI options: `--fast`, `--ai`, `--api`, `--languages`, `--verbose`, `--max-pages`, `--threshold`
- [x] Smart text selection (Vision vs PDF based on content length)
- [x] Progress reporting with `--verbose` flag
- [x] Input validation with clear error messages
- [x] Unit tests for API parsing, text selection, serialization
- [x] Password-protected PDF support (`--password`)
- [x] Batch processing (`--batch` flag)
- [x] AI integration tests (sliding window context pattern)

## Optional Testing

- [ ] Test with scanned PDF documents (OCR-only)
- [ ] Test AI mode with external API (OpenAI/Claude/Ollama)

## Future Enhancements

- [ ] OCR result caching
- [ ] Parallel batch processing (concurrent file processing)
- [ ] Custom AI prompt templates

## Notes

- Vision OCR can be slow for multi-page PDFs
- Fast mode (`--fast`) recommended for PDFs with good text layers
- AI processing requires external API or macOS 26+ for Apple Intelligence
- Test PDFs available in `testdata/pdf/`
