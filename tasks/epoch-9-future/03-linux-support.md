# Task 9.3: Linux Support (Future)

## Problem

macOS-only limits user base. Linux support would expand reach.

## Scope

This is a **future consideration**, not MVP 2.0 scope.

## Blockers

- Vision framework is macOS-only
- PDFKit is macOS/iOS-only
- Apple Intelligence is macOS-only

## Alternative Approaches

1. **Tesseract OCR**: Cross-platform OCR library
2. **Poppler/MuPDF**: Cross-platform PDF libraries
3. **Docker**: Package macOS tools in container (limited)

## Migration Path

1. Abstract PDF handling behind protocol
2. Abstract OCR behind protocol
3. Implement platform-specific backends
4. Conditional compilation with `#if os(macOS)`

## Effort Estimate

High. Requires significant architecture changes.

## Notes

Evaluate demand before committing resources.
