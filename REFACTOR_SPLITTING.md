# Code Refactoring Plan: Splitting Large Swift Files

This document outlines steps for a junior developer to refactor large Swift files in the `pdf22md` project. The goal is to improve code organization without changing functionality.

## General Guidelines

1.  **Preserve functionality**: The tool must work exactly as before.
2.  **Work incrementally**: One file at a time. Build and test after each change.
3.  **Use version control**: Create a new branch. Commit frequently with clear messages.
4.  **Test thoroughly**: Run `make test` after each step. Manually verify with sample PDFs when needed.
5.  **Keep code clean**: New files should be well-formatted and readable.

## Files to Refactor

Based on `REFACTOR_FILELIST.txt`:

1.  `PDFMarkdownConverterOptimized.swift`
2.  `PDFPageProcessor.swift`
3.  `PDFMarkdownConverterUltraOptimized.swift`
4.  `PDFMarkdownConverter.swift`
5.  `CGPDFImageExtractor.swift`
6.  `PDFPageProcessorOptimized.swift`
7.  `AssetExtractor.swift`

---

## Refactoring `PDFMarkdownConverterOptimized.swift`

**Current**: Contains font analysis and Markdown generation methods.

**Plan**: Extract these into dedicated files.

### Create `MarkdownGenerator.swift`

- Move `generateMarkdown(from:fontStats:)` and `shouldAddLineBreak(current:previous:)` here
- Make both methods static
- Pass `pdfBasename` and `assetsPath` as parameters where needed

### Create `FontAnalyzer.swift`

- Move `analyzeFonts(from:)` here
- Make it static

### Update Original File

- Remove moved methods
- Replace calls with `FontAnalyzer.analyzeFonts(...)` and `MarkdownGenerator.generateMarkdown(...)`

---

## Refactoring `PDFPageProcessor.swift`

**Current**: Handles text and vector graphics extraction.

**Plan**: Split into specialized modules.

### Create `TextExtractor.swift`

- Move `extractTextElements()` and `getBounds(for:)` here
- Make static
- Accept `PDFPage` and `pageIndex` as parameters

### Create `VectorGraphicsExtractor.swift`

- Move `extractVectorGraphics()`, `sectionContainsImageContent(_:)`, and `renderPageSection(_:)` here
- Make static
- Accept `PDFPage`, `pageIndex`, and `dpi` as parameters

### Update Original File

- Remove moved methods
- Replace calls with new module methods
- Remove unused `extractImageElements()` method

---

## Refactoring `PDFMarkdownConverterUltraOptimized.swift`

**Current**: Contains two classes in one file.

**Plan**: Separate them.

### Create `PDFPageProcessorUltraOptimized.swift`

- Move the entire `PDFPageProcessorUltraOptimized` class to this new file

### Update Original File

- Keep only `PDFMarkdownConverterUltraOptimized` class
- Verify references to the moved class still work

---

## Refactoring `PDFMarkdownConverter.swift`

**Current**: Contains duplicated font analysis and Markdown generation logic.

**Plan**: Reuse the new shared modules.

### Update File

- Remove `analyzeFonts` and `generateMarkdown` methods
- Replace calls with `FontAnalyzer.analyzeFonts(...)` and `MarkdownGenerator.generateMarkdown(...)`
- Ensure `AssetExtractor` integration remains intact

---

## Review `CGPDFImageExtractor.swift`

**Current**: Well-organized image extraction logic.

**Plan**: No splitting required. Clean up internal structure only.

### Tasks

- Verify helper methods (`createImage`, `createImageFromRawData`, `getImageBounds`) are `private static func`
- No code movement necessary

---

## Refactoring `PDFPageProcessorOptimized.swift`

**Current**: Contains duplicated extraction logic.

**Plan**: Reuse shared modules created earlier.

### Update File

- Remove `extractTextElements` and `extractVectorGraphics` methods
- Replace calls with `TextExtractor.extractTextElements(...)` and `VectorGraphicsExtractor.extractVectorGraphics(...)`
- Verify `extractImageElements()` correctly calls `CGPDFImageExtractor.extractImages`

---

## Review `AssetExtractor.swift`

**Current**: Cohesive asset management functionality.

**Plan**: No splitting required. Confirm internal structure.

### Tasks

- Verify `shouldUsePNG`, `savePNG`, and `saveJPEG` are `private func`
- No code movement necessary

---

## Testing

After each refactoring step:
1. Run `make build`
2. Run `make test`  
3. Manually test with sample PDFs:
   - Standard conversion
   - `--optimized` flag
   - `--ultra-optimized` flag
   - PDFs with images and text

The end result should be smaller, more focused files with the same tool functionality intact.