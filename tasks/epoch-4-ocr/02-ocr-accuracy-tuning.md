# Task 4.2: OCR Accuracy Tuning

## Problem

Vision OCR may produce suboptimal results for certain document types.

## Acceptance Criteria

- [ ] Add `--ocr-languages` flag for language hints
- [ ] Add `--ocr-level` flag (fast/accurate)
- [ ] Optimize preprocessing for better recognition
- [ ] Document best practices for different doc types

## Implementation

### New CLI Flags
```
--ocr-languages <codes>   Comma-separated language codes (e.g., "en,de")
--ocr-level <level>       Recognition level: fast, accurate (default)
```

### VNRecognizeTextRequest Configuration
- `.recognitionLevel`: `.fast` or `.accurate`
- `.recognitionLanguages`: Custom language list
- `.usesLanguageCorrection`: Enable/disable

## Verification

Test with PDFs in different languages and measure accuracy.
