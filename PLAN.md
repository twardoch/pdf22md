# PDF22MD Enhancement Plan: Vision OCR + AI Text Processing

## Executive Summary

Extend pdf22md to use Apple Vision Framework for OCR text extraction and integrate AI-powered text correction using either external OpenAI-compatible APIs or on-device Apple Intelligence.

**Scope (one sentence):** Add Vision Framework OCR fallback and AI-driven page-by-page text correction with sliding window context.

---

## 1. Current Architecture

### 1.1 Existing Pipeline

```
PDF Input → PDFKit Text Extraction (Fn) → Font Analysis → Markdown Generation → Output
                    ↓
           CoreGraphics Image Extraction
```

### 1.2 Key Limitations

- **No OCR**: Scanned PDFs produce empty output
- **No AI processing**: Raw text with basic heading detection only
- **Single extraction path**: No fallback for poor PDF text layers

### 1.3 Source Files to Modify

| File | Purpose | Changes Required |
|------|---------|------------------|
| `PDFPageProcessor.swift` | Page extraction | Add Vision OCR |
| `PDFMarkdownConverter.swift` | Main converter | Add AI processing pipeline |
| `PDFElement.swift` | Data models | Add extraction source enum |
| `main.swift` | CLI interface | Add `--api` and `--fast` options |

---

## 2. Target Architecture

### 2.1 Enhanced Pipeline

```
PDF Input (Page n = Pn)
    ↓
┌───────────────────────────────────────────────────────────────┐
│ EXTRACTION PHASE (per page, parallel)                         │
│                                                               │
│   Fn = PDF-parsed text (PDFKit attributedString) [ALWAYS]    │
│   Vn = Vision OCR text (VNRecognizeTextRequest) [IF AVAIL]   │
│                                                               │
└───────────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────────┐
│ SELECTION/PROCESSING PHASE                                    │
│                                                               │
│ IF --fast:                                                    │
│     Use Fn only                                               │
│                                                               │
│ ELIF no AI requested:                                         │
│     For each page: Use Vn if len(Vn) >> len(Fn), else Fn     │
│                                                               │
│ ELIF AI requested:                                            │
│     Sliding window correction:                                │
│     C1 = AI(F1, V1) → T1                                     │
│     C2 = AI(F2, V2, C1) → T1 (improved), T2                  │
│     Cn = AI(Fn, Vn, Cn-1) → Tn-1 (improved), Tn             │
│     Final page: Tf = Cf                                       │
│                                                               │
└───────────────────────────────────────────────────────────────┘
    ↓
Font Analysis → Markdown Generation → Output
```

### 2.2 AI Provider Resolution

```
--api provided OR PDF22MD_API env var set?
    ↓ YES                              ↓ NO
Use external API                    Apple Intelligence available?
(OpenAI-compatible)                     ↓ YES              ↓ NO
                                    Use Apple Intel    Skip AI (use Fn/Vn selection)
```

### 2.3 API Format

```
--api {model}:{api_key}@{base_url}

Examples:
  --api gpt-4o:sk-xxx@https://api.openai.com/v1
  --api claude-3-haiku:sk-ant-xxx@https://api.anthropic.com/v1
  --api llama3:@http://localhost:11434/v1  (no key needed for local)

Environment variable:
  PDF22MD_API=gpt-4o:sk-xxx@https://api.openai.com/v1
```

---

## 3. Implementation Details

### 3.1 Vision Framework Integration

**New file: `VisionTextExtractor.swift`**

```swift
import Vision
import AppKit

struct VisionTextResult {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

final class VisionTextExtractor {
    static func extractText(from cgImage: CGImage,
                           languages: [String] = ["en"],
                           useFastRecognition: Bool = false) async throws -> [VisionTextResult]

    static func extractText(from pdfPage: PDFPage,
                           dpi: CGFloat = 144) async throws -> [VisionTextResult]
}
```

**Integration point in `PDFPageProcessor`:**

```swift
func processPage() async -> (pdfElements: [PDFElement], visionText: String?) {
    let pdfElements = extractTextElements()  // Existing Fn

    // New: Extract Vn via Vision
    let visionText: String?
    if let pageImage = renderPageToImage() {
        let results = try? await VisionTextExtractor.extractText(from: pageImage)
        visionText = results?.map { $0.text }.joined(separator: "\n")
    } else {
        visionText = nil
    }

    return (pdfElements, visionText)
}
```

### 3.2 AI Processing Module

**New file: `AITextProcessor.swift`**

```swift
/// AI-powered text correction processor
final class AITextProcessor {
    enum Provider {
        case openAICompatible(model: String, apiKey: String, baseURL: URL)
        case appleIntelligence
    }

    private let provider: Provider

    /// Process page with context from previous page
    func processPage(
        pdfText: String,           // Fn
        visionText: String?,       // Vn (optional)
        previousContext: String?,  // Cn-1 (nil for first page)
        pageNumber: Int
    ) async throws -> (correctedText: String, improvedPrevious: String?)
}
```

**System prompt template:**

```
The text was extracted from page {n} of a PDF file.
Fix obvious spelling and typographic errors.
Move image captions, footnotes, margin notes etc. to the end of the page.
Remove running page artefacts and other garbled text, noise and garbage.
Combine broken lines into logical paragraphs.
Identify headings and other formatting and preserve them as Markdown.

{If previousContext provided:}
Here is the corrected text from the previous page for context:
---
{previousContext}
---
Please also suggest any improvements to the previous page text that would help it flow better into this page.
```

### 3.3 OpenAI-Compatible HTTP Client

**New file: `OpenAIClient.swift`**

```swift
import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let max_tokens: Int?
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

final class OpenAIClient {
    let baseURL: URL
    let apiKey: String
    let model: String

    func complete(messages: [ChatMessage]) async throws -> String
}
```

### 3.4 Apple Intelligence Integration

**New file: `AppleIntelligenceProcessor.swift`**

```swift
#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
final class AppleIntelligenceProcessor {
    private let session: LanguageModelSession

    init() throws {
        let model = SystemLanguageModel.default
        self.session = LanguageModelSession(model: model)
    }

    func process(prompt: String) async throws -> String {
        let response = try await session.respond(to: Prompt(prompt))
        return response.content
    }
}
#endif
```

### 3.5 CLI Changes

**Updated `main.swift`:**

```swift
@Option(name: .long, help: "AI API in format model:api_key@base_url (or use PDF22MD_API env)")
var api: String?

@Flag(name: .long, help: "Fast mode: use PDF text extraction only, skip Vision OCR and AI")
var fast: Bool = false

@Flag(name: .long, help: "Enable AI text correction (uses Apple Intelligence if --api not specified)")
var ai: Bool = false
```

### 3.6 Data Model Extensions

**Updated `PDFElement.swift`:**

```swift
enum TextExtractionSource {
    case pdfKit      // Fn - PDF-parsed text
    case vision      // Vn - Vision OCR text
    case aiCorrected // Cn - AI-corrected text
}

struct PageTextContent {
    let pageIndex: Int
    let pdfText: String           // Fn - always populated
    let visionText: String?       // Vn - if Vision available
    let correctedText: String?    // Cn - if AI processed
    let source: TextExtractionSource
}
```

---

## 4. Processing Modes

| Mode | CLI Flags | Extraction | Processing |
|------|-----------|------------|------------|
| **Fast** | `--fast` | PDF only (Fn) | None |
| **Standard** | (default) | PDF + Vision (Fn, Vn) | Select best by length |
| **AI External** | `--ai --api ...` | PDF + Vision | Sliding window AI |
| **AI Local** | `--ai` (no api) | PDF + Vision | Apple Intelligence |

### 4.1 Text Selection Logic (Standard Mode)

```swift
func selectBestText(pdfText: String, visionText: String?) -> String {
    guard let visionText = visionText else { return pdfText }

    let pdfLength = pdfText.count
    let visionLength = visionText.count

    // Use Vision if significantly more content (>50% more)
    if visionLength > pdfLength * 1.5 {
        return visionText
    }

    return pdfText
}
```

### 4.2 Sliding Window AI Processing

```swift
func processWithAI(pages: [PageTextContent]) async throws -> [String] {
    var results: [String] = []
    var previousCorrected: String? = nil

    for (index, page) in pages.enumerated() {
        let (corrected, improvedPrev) = try await aiProcessor.processPage(
            pdfText: page.pdfText,
            visionText: page.visionText,
            previousContext: previousCorrected,
            pageNumber: index + 1
        )

        // Update previous page if AI suggested improvements
        if let improved = improvedPrev, !results.isEmpty {
            results[results.count - 1] = improved
        }

        results.append(corrected)
        previousCorrected = corrected
    }

    return results
}
```

---

## 5. File Structure

### 5.1 New Files to Create

```
pdf22md/Sources/PDF22MD/
├── Vision/
│   └── VisionTextExtractor.swift      # Vision Framework OCR
├── AI/
│   ├── AITextProcessor.swift          # AI processing orchestration
│   ├── OpenAIClient.swift             # OpenAI-compatible HTTP client
│   └── AppleIntelligenceProcessor.swift  # Apple Intelligence wrapper
└── Models/
    └── PageTextContent.swift          # Extended data models
```

### 5.2 Files to Modify

```
pdf22md/Sources/PDF22MD/
├── PDFPageProcessor.swift             # Add Vision extraction call
├── PDFMarkdownConverter.swift         # Add AI processing pipeline
└── PDFElement.swift                   # Add TextExtractionSource enum

pdf22md/Sources/PDF22MDCli/
└── main.swift                         # Add --api, --fast, --ai flags
```

---

## 6. Dependencies

### 6.1 Framework Dependencies

| Framework | Purpose | Availability |
|-----------|---------|--------------|
| Vision | OCR text extraction | macOS 10.13+ |
| FoundationModels | Apple Intelligence | macOS 26+ |
| PDFKit | PDF parsing | macOS 10.4+ |

### 6.2 Package Dependencies

No new external packages required. Using:
- Native URLSession for HTTP requests
- Native JSON encoding/decoding
- Existing swift-argument-parser for CLI

---

## 7. Error Handling

### 7.1 Vision Errors

```swift
enum VisionExtractionError: Error {
    case imageRenderingFailed
    case textRecognitionFailed(Error)
    case noTextFound
}
```

### 7.2 AI Processing Errors

```swift
enum AIProcessingError: Error {
    case invalidAPIConfiguration(String)
    case networkError(Error)
    case responseParsingError
    case appleIntelligenceUnavailable
    case contextWindowExceeded
    case guardrailViolation
}
```

### 7.3 Graceful Degradation

- If Vision fails: Fall back to PDF text only
- If AI fails: Fall back to standard mode (best of Fn/Vn)
- If Apple Intelligence unavailable: Skip AI silently (as per requirements)

---

## 8. Testing Strategy

### 8.1 Unit Tests

| Test Category | What to Test |
|---------------|--------------|
| VisionTextExtractor | OCR accuracy, confidence thresholds |
| OpenAIClient | Request/response serialization, error handling |
| AITextProcessor | Prompt construction, response parsing |
| Text selection | Length comparison logic |
| API parsing | `--api` argument format parsing |

### 8.2 Integration Tests

| Test | Input | Expected |
|------|-------|----------|
| Fast mode | `test.pdf --fast` | PDF text only, no Vision |
| Standard mode | `test.pdf` | Best of PDF/Vision |
| AI external | `test.pdf --ai --api gpt-4o:key@url` | AI-corrected text |
| Scanned PDF | `scanned.pdf` | Vision OCR text |

### 8.3 Test PDFs (in `testdata/pdf/`)

| File | Purpose |
|------|---------|
| `test.pdf` | Normal PDF with text layer |
| `bloo.pdf` | Test file |
| `frut.pdf` | Test file |
| `gard.pdf` | Test file |
| `jlmp.pdf` | Test file |

### 8.4 Manual Verification

1. Process each test PDF in all modes
2. Compare output quality
3. Measure performance impact
4. Test with real-world scanned documents

---

## 9. Performance Considerations

### 9.1 Parallel Processing

- **Extraction phase**: Pages processed in parallel (Fn and Vn)
- **AI phase**: Sequential (requires sliding window context)

### 9.2 Memory Management

- Render pages to images on-demand, release immediately after OCR
- Stream AI responses where possible
- Use autoreleasepool for image processing

### 9.3 Timeout Handling

- Vision OCR: 30s per page timeout
- AI API calls: 60s timeout with retry (max 2)
- Total document: No hard limit, but warn after 5 minutes

---

## 10. Documentation Updates

### 10.1 README.md Updates

- Add new CLI options documentation
- Add usage examples for each mode
- Document API format and environment variable
- Add troubleshooting section for Vision/AI issues

### 10.2 Man Page Updates (`docs/pdf22md.1`)

- Add `--api`, `--fast`, `--ai` options
- Add examples for AI processing

### 10.3 CHANGELOG.md

- Document v2.0.0 release with Vision OCR and AI features

---

## 11. Implementation Phases

### Phase 1: Vision Framework Integration (Core) ✅ COMPLETE

1. ✅ Create `VisionTextExtractor.swift`
2. ✅ Modify `PDFPageProcessor` to call Vision
3. ✅ Add `--fast` flag to skip Vision
4. ✅ Add text selection logic
5. ✅ Write unit tests for Vision extraction

### Phase 2: OpenAI-Compatible API Client ✅ COMPLETE

1. ✅ Create `OpenAIClient.swift`
2. ✅ Implement request/response types
3. ✅ Add `--api` argument parsing
4. ✅ Add `PDF22MD_API` environment variable support
5. ✅ Write unit tests for HTTP client

### Phase 3: AI Processing Pipeline ✅ COMPLETE

1. ✅ Create `AITextProcessor.swift`
2. ✅ Implement sliding window logic
3. ✅ Integrate into `PDFMarkdownConverter`
4. ✅ Add `--ai` flag
5. ✅ Write integration tests

### Phase 4: Apple Intelligence Integration ✅ COMPLETE

1. ✅ Create `AppleIntelligenceProcessor.swift` (stub for macOS 26+)
2. ✅ Add availability checks for macOS 26+
3. ✅ Integrate as fallback when no `--api`
4. ⏳ Test on supported hardware (requires macOS 26)

### Phase 5: Testing & Documentation ✅ COMPLETE

1. ✅ Test all modes with `testdata/pdf/` files
2. ⏳ Test with external scanned PDFs (optional)
3. ✅ Update README.md
4. ✅ Update man page (via ArgumentParser --help)
5. ✅ Write CHANGELOG entry

### Additional Features Implemented

- ✅ `--password` for encrypted PDFs
- ✅ `--batch` for directory processing
- ✅ `-j/--jobs` for parallel batch processing
- ✅ `-q/--quiet` for silent mode
- ✅ `--max-pages` for page limits
- ✅ `--threshold` for Vision text selection
- ✅ `--languages` for OCR language support

---

## 12. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Vision OCR slow | Add `--fast` mode, parallel page processing |
| AI API costs | Document token usage, warn about large PDFs |
| Apple Intelligence unavailable | Silent fallback to standard mode |
| Network failures | Retry with exponential backoff |
| Context window limits | Truncate page text if needed |

---

## 13. Success Criteria

1. Scanned PDFs produce readable Markdown output
2. AI-corrected text is higher quality than raw extraction
3. `--fast` mode has no performance regression
4. All existing tests pass
5. New tests cover Vision and AI paths
6. Documentation is complete and accurate
