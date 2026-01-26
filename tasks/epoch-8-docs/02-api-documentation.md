# Task 8.2: API Documentation

## Problem

Library can be used programmatically but lacks documentation.

## Acceptance Criteria

- [ ] DocC documentation for public APIs
- [ ] Code examples in documentation
- [ ] Generate documentation site
- [ ] Add to Package.swift as doc target

## Public API Surface

### PDFMarkdownConverter
```swift
/// Converts a PDF file to Markdown format.
///
/// - Parameters:
///   - pdfPath: Path to the PDF file
///   - options: Processing options
/// - Returns: Markdown string
/// - Throws: PDFConversionError
public func convert(pdfPath: String, options: ProcessingOptions) async throws -> String
```

### ProcessingOptions
```swift
/// Configuration for PDF processing.
public struct ProcessingOptions {
    /// DPI for rasterizing vector graphics
    public var dpi: Double
    /// Enable Vision OCR for scanned documents
    public var enableOCR: Bool
    /// Enable AI text correction
    public var enableAI: Bool
}
```

## Verification

```bash
swift package generate-documentation
open .build/docs/documentation/pdf22md/index.html
```
