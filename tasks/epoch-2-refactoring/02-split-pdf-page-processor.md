# Task 2.2: Split PDFPageProcessor.swift

## Problem

`PDFPageProcessor.swift` is 317 lines. Mixes text extraction with vector graphics rendering.

## Acceptance Criteria

- [ ] Extract `TextExtractor` struct to new file
- [ ] Extract `VectorGraphicsExtractor` struct to new file
- [ ] `PDFPageProcessor.swift` reduced to <150 lines
- [ ] All tests pass after refactoring
- [ ] No behavior changes

## Extraction Plan

### TextExtractor.swift (~100 lines)
- PDFKit text extraction
- Text element creation
- Font detection helpers

### VectorGraphicsExtractor.swift (~100 lines)
- Vector content detection
- Rasterization at DPI
- CGContext rendering

### PDFPageProcessor.swift (~150 lines)
- Page processing orchestration
- Element collection
- EnhancedPageResult creation

## Verification

```bash
swift build && swift test && ./example.sh -q
```

Expected: Build succeeds, all tests pass, output identical.
