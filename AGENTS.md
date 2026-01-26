# Development Guidelines for pdf22md

> **Project Scope**: Convert PDF files to Markdown with Vision OCR and optional AI text correction.

## Language & Platform

- **Language**: Swift 5.7+
- **Platform**: macOS 12.0+ (Monterey and later)
- **Package Manager**: Swift Package Manager
- **Dependencies**: swift-argument-parser (CLI), PDFKit, Vision, CoreGraphics

## Foundation: Chain-of-Thought Reasoning

Before generating any response, assume your first instinct is wrong. Apply chain-of-thought reasoning:

1. **Problem Analysis**: What exactly are we solving and why?
2. **Constraints**: What limitations must we respect?
3. **Solution Options**: 2-3 viable approaches with trade-offs?
4. **Edge Cases**: What could go wrong and how do we handle it?
5. **Test Strategy**: How will we verify this works correctly?

Your first response should be what you'd produce after finding and fixing three critical issues.

## No Sycophancy, Accuracy First

- If confidence is below 90%, search the codebase, references, and web.
- State confidence levels: "I'm certain" vs "I believe" vs "This is an educated guess".
- Challenge incorrect statements immediately.
- Facts matter more than feelings: accuracy is non-negotiable.
- NEVER use validation phrases like "You're absolutely right".

## Absolute Priority: Never Overcomplicate

- **Stop and assess**: Before writing code, ask "Has this been done before?"
- **Build vs buy**: Prefer well-maintained Swift packages over custom solutions.
- **Verify, don't assume**: Never assume code works—test every function.
- **Complexity kills**: Every line of custom code is technical debt.
- **Ruthless deletion**: Remove features, don't add them.
- **Test or it doesn't exist**: Untested code is broken code.

## Swift-Specific Standards

### Code Style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Use `struct` over `class` unless reference semantics are needed.
- Prefer value types and immutability.
- Use `async/await` for concurrency; avoid callbacks when possible.
- Use Swift's `Error` protocol for error handling.
- Define custom errors (e.g., `PDFConversionError`) with clear cases.

### Naming Conventions

- Types and protocols: `UpperCamelCase` (e.g., `PDFMarkdownConverter`)
- Methods, properties, variables: `lowerCamelCase` (e.g., `extractText()`)
- Constants: `lowerCamelCase` or `SCREAMING_SNAKE_CASE` for globals
- Boolean properties: use `is`, `has`, `should` prefixes (e.g., `isProcessing`)

### Type Safety

- Use explicit types where clarity helps; rely on inference elsewhere.
- Avoid force unwrapping (`!`) except in tests or truly guaranteed cases.
- Prefer `guard let` for early returns over nested `if let`.
- Use `Result<T, Error>` or throwing functions for error handling.

### Concurrency

- Use Swift's structured concurrency (`async/await`, `TaskGroup`).
- For GCD: use `DispatchQueue.concurrentPerform` for parallel loops.
- Ensure thread safety with actors or serial queues for shared state.
- Mark `@MainActor` for UI-related code (if applicable).

## Project Architecture

### Source Layout

```
pdf22md/
├── Sources/
│   ├── PDF22MD/           # Core library
│   │   ├── PDFMarkdownConverter.swift      # Main converter
│   │   ├── PDFPageProcessor.swift          # Page-level processing
│   │   ├── PDFElement.swift                # Data models
│   │   ├── FontStatistics.swift            # Heading detection
│   │   ├── AssetExtractor.swift            # Image saving
│   │   ├── CGPDFImageExtractor.swift       # Low-level image extraction
│   │   ├── Vision/                         # OCR components
│   │   └── AI/                             # AI text correction
│   └── PDF22MDCli/        # CLI executable
│       └── main.swift
└── Tests/
    └── PDF22MDTests/      # XCTest tests
```

### Processing Pipeline

1. **PDF Loading**: Open PDF with PDFKit, handle password protection
2. **Text Extraction**: PDFKit first, Vision OCR fallback for scanned docs
3. **Font Analysis**: Detect headings via frequency analysis
4. **Image Extraction**: XObject streams + vector rasterization
5. **AI Processing**: Optional LLM-based text correction
6. **Markdown Generation**: Convert elements to formatted output

### Three Engines

1. **Standard** (`PDFMarkdownConverter.swift`): async/await + TaskGroup
2. **Optimized** (`PDFMarkdownConverterOptimized.swift`): GCD-based
3. **Ultra-Optimized** (`PDFMarkdownConverterUltraOptimized.swift`): NSString + low-level

## Verification Workflow

1. **Build**: `swift build -c release` or `make build`
2. **Test**: `swift test` or `make test`
3. **Run**: `./pdf22md/.build/release/pdf22md -i test.pdf -o test.md`
4. **Batch test**: `./example.sh` (tests all 4 methods)

### Before Submitting Changes

- [ ] `swift build` passes without errors
- [ ] `swift test` passes (fix infrastructure if broken)
- [ ] Manual test with sample PDF
- [ ] No force unwraps added without justification
- [ ] Error handling is complete (no empty catch blocks)

## Complexity Detection Triggers

Rethink your approach if you're:

- Writing a utility function that feels "general purpose"
- Creating abstractions "for future flexibility"
- Adding error handling for errors that never happen
- More than 3 levels of indentation
- Functions longer than 30 lines
- Files longer than 300 lines (current files exceed this—refactoring needed)

## File Size Guidelines

Current state (needs refactoring):
- `PDFMarkdownConverter.swift`: 393 lines → split FontAnalyzer, MarkdownGenerator
- `main.swift`: 321 lines → extract ProcessingOptions builder
- `PDFPageProcessor.swift`: 317 lines → split TextExtractor, VectorGraphicsExtractor

Target: No file exceeds 200 lines of actual logic.

## Documentation to Maintain

| File | Purpose |
|------|---------|
| `README.md` | Purpose, installation, usage (≤250 lines) |
| `CHANGELOG.md` | Release notes (accumulative) |
| `TASKS.md` | PRD/specification with epoch links |
| `TODO.md` | Flat `- [ ]` actionable items |
| `WORK.md` | Work progress and test results |

## Testing Standards

- **XCTest**: Use XCTest framework for unit tests
- **Location**: `pdf22md/Tests/PDF22MDTests/`
- **Naming**: `test_functionName_whenCondition_thenResult`
- **Coverage**: Test all public functions
- **Edge cases**: Empty PDFs, password-protected, scanned images, huge files
- **Functional tests**: `example.sh` for real-world scenarios

## Build Commands

```bash
# Development build
swift build

# Release build
swift build -c release
make build

# Run tests
swift test
make test

# Install system-wide
sudo make install

# Create distribution package
make dist
```

## Anti-Bloat Guidelines

### RED LIST: Never Add

- Analytics/metrics collection
- Performance monitoring frameworks
- Sophisticated caching systems
- Configuration validation systems
- Health monitoring and diagnostics
- Enterprise error handling frameworks

### GREEN LIST: Acceptable

- Basic error handling (do/catch, show error)
- Simple retry (3 attempts max)
- Basic logging (print/os_log for debug)
- Input validation (check required args)
- Help text and usage examples

## Special Commands

### /test

```bash
swift build -c release && swift test && ./example.sh -q
```

### /work

1. Read `TODO.md` and `TASKS.md`
2. Work on highest-priority incomplete item
3. Write test first, then implement
4. Verify with `swift test` and manual test
5. Update `WORK.md` with progress
6. Mark item complete in `TODO.md`

### /report

1. Run tests and document results
2. Update `CHANGELOG.md` with changes
3. Clean completed items from `TODO.md`
4. Update version in `Version.swift` if releasing

---

**Project Scope (One Sentence)**: Convert PDF files to clean Markdown with parallel processing, Vision OCR for scanned documents, and optional AI text correction.
