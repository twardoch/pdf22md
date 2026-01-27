# CLI Flag Refactoring Plan (Issue #402)

## Summary

Simplify CLI by removing legacy converter flags and making Vision OCR the default.

## Requirements

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Remove `--ultra-optimized` flag | [x] Done |
| 2 | Remove `--optimized` flag | [x] Done |
| 3 | Use enhanced converter by default | [x] Done |
| 4 | Enable Vision OCR by default | [x] Done (--fast skips it) |
| 5 | `--fast` skips Vision (PDF text only) | [x] Done |
| 6 | `--ai` passes results to LLM | [x] Done |
| 7 | Progress reporting for Vision and AI | [x] Done |
| 8 | Suppress PDFKit stderr noise | [x] Already done |
| 9 | Display progress to stderr by default | [x] Done |
| 10 | `--verbose` shows additional warnings/errors | [x] Done |
| 11 | `--quiet` suppresses progress and warnings | [x] Done |
| 12 | Always output serious errors | [x] Done |

## Changes Made

### PDF22MDCommand.swift
- Removed `--optimized` and `--ultra-optimized` flags
- Simplified `processSinglePDF()` to always use `PDFMarkdownConverter.convertEnhanced()`
- Updated `--verbose` help text: "Show additional warnings and debug info"
- Progress shown by default, respects `--quiet`

### Deleted Files
- `PDFPageProcessorOptimized.swift` - unused after converter consolidation

### Updated Tests
- `testOptimizedConversion` → `testFastModeConversion` (async, uses PDFMarkdownConverter)
- `testConversionPerformance` - now uses PDFMarkdownConverter with fast mode
- `testEmptyPDF` - now uses PDFMarkdownConverter with fast mode

## CLI Behavior Summary

| Flags | Behavior |
|-------|----------|
| (default) | Vision OCR enabled, progress shown |
| `--fast` | Vision OCR disabled (PDF text only) |
| `--ai` | AI text correction enabled |
| `--verbose` | Show warnings and debug info |
| `--quiet` | Suppress progress and warnings |
| `--quiet` + error | Errors always shown |
