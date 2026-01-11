# PDF22MD Enhancement Plan: Vision OCR + AI Text Processing

## Status: v1.6.0 Complete ✅

All planned features have been implemented. See CHANGELOG.md for release notes.

---

## Summary

Extended pdf22md with:
- Apple Vision Framework for OCR text extraction
- AI-powered text correction via OpenAI-compatible APIs
- Apple Intelligence integration (macOS 26+)

**Scope:** Add Vision Framework OCR fallback and AI-driven page-by-page text correction with sliding window context.

---

## Architecture

### Processing Pipeline

```
PDF Input (Page n = Pn)
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ EXTRACTION PHASE (per page, parallel)                           │
│   Fn = PDF-parsed text (PDFKit attributedString) [ALWAYS]       │
│   Vn = Vision OCR text (VNRecognizeTextRequest) [IF AVAIL]      │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ SELECTION/PROCESSING PHASE                                       │
│                                                                  │
│ IF --fast:        Use Fn only                                   │
│ ELIF no AI:       Use Vn if len(Vn) >> len(Fn), else Fn        │
│ ELIF AI:          Sliding window: Cn = AI(Fn, Vn, Cn-1)        │
└─────────────────────────────────────────────────────────────────┘
    ↓
Font Analysis → Markdown Generation → Output
```

### API Format

```
--api {model}:{api_key}@{base_url}

Examples:
  --api gpt-4o:sk-xxx@https://api.openai.com/v1
  --api claude-3-haiku:sk-ant-xxx@https://api.anthropic.com/v1
  --api llama3:@http://localhost:11434/v1
```

---

## Completed Implementation

### Phase 1: Vision Framework Integration ✅
- Created `VisionTextExtractor.swift`
- Modified `PDFPageProcessor` for Vision calls
- Added `--fast` flag and text selection logic

### Phase 2: OpenAI-Compatible API Client ✅
- Created `OpenAIClient.swift`
- Added `--api` argument and `PDF22MD_API` env var

### Phase 3: AI Processing Pipeline ✅
- Created `AITextProcessor.swift` with sliding window
- Integrated into `PDFMarkdownConverter`
- Added `--ai` flag

### Phase 4: Apple Intelligence ✅
- Created `AppleIntelligenceProcessor.swift` (stub for macOS 26+)
- Added availability checks

### Phase 5: Testing & Documentation ✅
- Updated README.md with all options
- Added comprehensive unit tests
- Wrote CHANGELOG entry

### Additional Features ✅
- `--password` for encrypted PDFs
- `--batch` for directory processing
- `-j/--jobs` for parallel batch
- `-q/--quiet` for silent mode
- `--max-pages` for page limits
- `--threshold` for Vision text selection
- `--languages` for OCR language support

---

## Future Considerations

- OCR result caching for repeated conversions
- Custom AI prompt templates
- Web UI for browser-based conversion
