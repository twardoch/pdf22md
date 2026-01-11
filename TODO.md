# TODO: PDF22MD Vision OCR + AI Enhancement

## Completed

### Phase 1: Vision Framework Integration

- [x] Create `pdf22md/Sources/PDF22MD/Vision/` directory
- [x] Create `VisionTextExtractor.swift` with `VisionTextResult` struct
- [x] Implement `VisionTextExtractor.extractText(from:CGImage)` using `VNRecognizeTextRequest`
- [x] Implement `VisionTextExtractor.extractText(from:PDFPage)` with page-to-image rendering
- [x] Add `renderPageToImage()` method to `PDFPageProcessor`
- [x] Modify `PDFPageProcessor.processPage()` to return both PDF text and Vision text
- [x] Update `PDFMarkdownConverter` to handle dual text extraction
- [x] Add `--fast` flag to `main.swift` CLI arguments
- [x] Implement text selection logic: use Vision text if >50% more content than PDF text

### Phase 2: Data Models Update

- [x] Add `TextExtractionSource` enum to `PDFElement.swift`
- [x] Create `PageTextContent` struct for holding both extraction sources
- [x] Create `ProcessingOptions` struct for configuration
- [x] Create `APIConfiguration` struct for API parsing
- [x] Update `PDFMarkdownConverter` to use `PageTextContent`

### Phase 3: OpenAI-Compatible API Client

- [x] Create `pdf22md/Sources/PDF22MD/AI/` directory
- [x] Create `OpenAIClient.swift` with `ChatMessage` struct
- [x] Create `ChatCompletionRequest` and `ChatCompletionResponse` structs
- [x] Implement `OpenAIClient.complete(messages:)` using URLSession
- [x] Add error handling for network failures, timeouts, invalid responses
- [x] Add retry logic with exponential backoff (max 2 retries)
- [x] Parse `--api` argument format: `model:api_key@base_url`
- [x] Add `PDF22MD_API` environment variable support

### Phase 4: AI Text Processing Pipeline

- [x] Create `AITextProcessor.swift` with `Provider` enum
- [x] Implement system prompt template with page number placeholder
- [x] Implement `processPage()` method for single-page correction
- [x] Implement sliding window logic in `PDFMarkdownConverter`
- [x] Handle previous page context passing (Cn-1 to Cn)
- [x] Add `--ai` flag to `main.swift` CLI arguments

### Phase 5: CLI Updates

- [x] Add `--fast` flag for fast mode
- [x] Add `--ai` flag for AI processing
- [x] Add `--api` option for external API
- [x] Add `--languages` option for Vision OCR languages

### Phase 6: Documentation

- [x] Update `pdf22md/README.md` with new CLI options
- [x] Update `PLAN.md` with implementation details
- [x] Create this `TODO.md` with task tracking

## Remaining

### Phase 5: Apple Intelligence Integration (optional, requires macOS 26+)

- [ ] Create `AppleIntelligenceProcessor.swift` with `#if canImport(FoundationModels)`
- [ ] Implement `@available(macOS 26.0, *)` availability check
- [ ] Create `LanguageModelSession` wrapper
- [ ] Test on macOS 26+ hardware (if available)

### Phase 7: Testing (optional)

- [x] Write unit tests for `VisionTextExtractor` (basic structure tests)
- [x] Write unit tests for `OpenAIClient` request/response serialization
- [x] Write unit tests for API argument parsing
- [x] Write unit tests for text selection logic
- [x] Write unit tests for `PageTextContent` bestText logic
- [ ] Write integration tests for AI processing pipeline
- [ ] Test with scanned PDF documents (OCR-only)
- [ ] Test AI mode with external API (OpenAI/Claude/Ollama)

### Future Enhancements

- [x] Add progress reporting for long-running conversions (--verbose flag)
- [x] Add verbose logging mode
- [ ] Add batch processing for multiple PDFs
- [ ] Add support for password-protected PDFs
- [ ] Add caching of OCR results

## Notes

- Vision OCR can be slow for multi-page PDFs (processes each page serially)
- Fast mode (`--fast`) recommended for PDFs with good text layers
- AI processing requires external API or macOS 26+ for Apple Intelligence
- Test PDFs available in `testdata/pdf/`
