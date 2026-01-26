# Task 7.2: Graceful Degradation

## Problem

Failures in optional features (OCR, AI) should not crash conversion.

## Acceptance Criteria

- [ ] OCR failure → fallback to empty text + warning
- [ ] AI failure → skip correction + warning
- [ ] Image extraction failure → continue without images
- [ ] Single page failure → continue with other pages
- [ ] Report all warnings at end

## Implementation

### Warning Collection
```swift
struct ConversionWarnings {
    var ocrFailures: [(page: Int, error: String)]
    var aiFailures: [(page: Int, error: String)]
    var imageFailures: [(page: Int, asset: String, error: String)]
    var pageFailures: [(page: Int, error: String)]
}
```

### Output Format
```
⚠️  Completed with warnings:
  - OCR failed on pages: 5, 12
  - AI correction skipped on pages: 5, 12
  - 2 images could not be extracted
  
Output written to: output.md
```

## Verification

Simulate failures and verify conversion completes with warnings.
