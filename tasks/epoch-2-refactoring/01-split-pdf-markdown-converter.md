# Task 2.1: Split PDFMarkdownConverter.swift

## Problem

`PDFMarkdownConverter.swift` is 393 lines. Contains font analysis and markdown generation mixed with conversion logic.

## Acceptance Criteria

- [ ] Extract `FontAnalyzer` struct to new file
- [ ] Extract `MarkdownGenerator` struct to new file
- [ ] `PDFMarkdownConverter.swift` reduced to <200 lines
- [ ] All tests pass after refactoring
- [ ] No behavior changes

## Extraction Plan

### FontAnalyzer.swift (~80 lines)
- `calculateFontStatistics()`
- `determineHeadingLevel()`
- Related font size constants

### MarkdownGenerator.swift (~100 lines)
- `generateMarkdown(from elements:)`
- Text formatting helpers
- Image markdown generation

### PDFMarkdownConverter.swift (~200 lines)
- Keep orchestration logic
- Page processing coordination
- Public API surface

## Verification

```bash
swift build && swift test && ./example.sh -q
```

Expected: Build succeeds, all tests pass, output identical.
