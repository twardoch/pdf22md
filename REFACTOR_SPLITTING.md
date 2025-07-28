# Code Refactoring Plan: Splitting Large Swift Files

This document outlines a meticulously detailed plan for a junior software developer to refactor and split large Swift code files within the `pdf22md` project into smaller, more manageable units. The primary goal is to improve code readability, maintainability, and reusability without altering the existing functionality.

## General Guidelines for Refactoring

Before starting, please ensure you understand these principles:
1.  **Functionality Intact**: Every change must preserve the existing behavior of the application. The `pdf22md` tool must function exactly as it did before the refactoring.
2.  **Small, Incremental Changes**: Perform one splitting task at a time. Build and test after each step to quickly identify and fix any issues.
3.  **Version Control**: Always work on a new branch and commit your changes frequently with clear, descriptive messages.
4.  **Testing**: After each refactoring step, run the project's tests (`make test`) to ensure no regressions have been introduced. If no specific tests exist for a module, perform manual testing to verify functionality.
5.  **Readability**: Ensure the new files and the remaining code are clean, well-formatted, and easy to understand.

## Files to Refactor

Based on the `REFACTOR_FILELIST.txt`, the following Swift files are candidates for splitting:

1.  `pdf22md/Sources/PDF22MD/PDFMarkdownConverterOptimized.swift`
2.  `pdf22md/Sources/PDF22MD/PDFPageProcessor.swift`
3.  `pdf22md/Sources/PDF22MD/PDFMarkdownConverterUltraOptimized.swift`
4.  `pdf22md/Sources/PDF22MD/PDFMarkdownConverter.swift`
5.  `pdf22md/Sources/PDF22MD/CGPDFImageExtractor.swift`
6.  `pdf22md/Sources/PDF22MD/PDFPageProcessorOptimized.swift`
7.  `pdf22md/Sources/PDF22MD/AssetExtractor.swift`

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/PDFMarkdownConverterOptimized.swift`

**Current State:**
This file contains the `PDFMarkdownConverterOptimized` class, which orchestrates the PDF to Markdown conversion using Grand Central Dispatch (GCD). It includes methods for font analysis (`analyzeFonts`) and Markdown generation (`generateMarkdown`), along with a small helper (`shouldAddLineBreak`).

**Proposed Refactoring:**
We will extract the font analysis and Markdown generation logic into separate, dedicated files to improve modularity and readability.

-   **New File:** `pdf22md/Sources/PDF22MD/MarkdownGenerator.swift`
    -   Move the `generateMarkdown(from:fontStats:)` method into this new file. It will become a static method or part of a new `MarkdownGenerator` struct/class.
    -   Move the `shouldAddLineBreak(current:previous:)` helper method into this new file as a private helper for `generateMarkdown`.
-   **New File:** `pdf22md/Sources/PDF22MD/FontAnalyzer.swift`
    -   Move the `analyzeFonts(from:)` method into this new file. It will become a static method or part of a new `FontAnalyzer` struct/class.

**Reasoning:**
-   **Separation of Concerns**: The `PDFMarkdownConverterOptimized` class's primary role should be coordinating the conversion process, not directly handling font analysis or Markdown string construction.
-   **Improved Readability**: Smaller files are easier to navigate and understand.
-   **Potential Reusability**: `FontAnalyzer` and `MarkdownGenerator` could potentially be reused or adapted for other conversion tasks in the future.

**Steps for Junior Developer:**

1.  **Create `MarkdownGenerator.swift`:**
    *   Create a new file: `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/MarkdownGenerator.swift`.
    *   Add the necessary `import` statements: `import Foundation`, `import CoreGraphics`, `import PDFKit`.
    *   Define a new struct or class, e.g., `struct MarkdownGenerator { ... }`.
    *   Move the `generateMarkdown(from:fontStats:)` method from `PDFMarkdownConverterOptimized.swift` into `MarkdownGenerator.swift`. Make it a static function: `static func generateMarkdown(...) -> String { ... }`.
    *   Move the `shouldAddLineBreak(current:previous:)` method into `MarkdownGenerator.swift` as a private static helper function.
    *   Ensure `AssetExtractor` is accessible. You might need to pass `pdfBasename` and `assetsPath` to the `generateMarkdown` function or initialize `AssetExtractor` within it.

2.  **Create `FontAnalyzer.swift`:**
    *   Create a new file: `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/FontAnalyzer.swift`.
    *   Add the necessary `import` statements: `import Foundation`, `import CoreGraphics`.
    *   Define a new struct or class, e.g., `struct FontAnalyzer { ... }`.
    *   Move the `analyzeFonts(from:)` method from `PDFMarkdownConverterOptimized.swift` into `FontAnalyzer.swift`. Make it a static function: `static func analyzeFonts(...) -> FontStatistics { ... }`.

3.  **Update `PDFMarkdownConverterOptimized.swift`:**
    *   Remove the `analyzeFonts` and `generateMarkdown` methods.
    *   In the `convert()` method, replace calls to `self.analyzeFonts(...)` with `FontAnalyzer.analyzeFonts(...)`.
    *   Replace calls to `self.generateMarkdown(...)` with `MarkdownGenerator.generateMarkdown(...)`.
    *   Ensure `AssetExtractor` is initialized correctly and passed to `MarkdownGenerator.generateMarkdown` if needed.

4.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable with a sample PDF to ensure the conversion still works as expected, especially with image extraction and heading detection.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/PDFPageProcessor.swift`

**Current State:**
This file contains the `PDFPageProcessor` class, responsible for extracting text and vector graphics from a single PDF page. It includes several private helper methods for text extraction (`extractTextElements`, `getBounds`) and vector graphics processing (`extractVectorGraphics`, `sectionContainsImageContent`, `renderPageSection`).

**Proposed Refactoring:**
We will separate the text extraction and vector graphics processing logic into distinct files.

-   **New File:** `pdf22md/Sources/PDF22MD/TextExtractor.swift`
    -   Move the `extractTextElements()` method into this new file. It will become a static method or part of a new `TextExtractor` struct/class.
    -   Move the `getBounds(for:)` method into this new file as a private static helper for `extractTextElements`.
-   **New File:** `pdf22md/Sources/PDF22MD/VectorGraphicsExtractor.swift`
    -   Move the `extractVectorGraphics()` method into this new file. It will become a static method or part of a new `VectorGraphicsExtractor` struct/class.
    -   Move the `sectionContainsImageContent(_:)` and `renderPageSection(_:)` methods into this new file as private static helpers for `extractVectorGraphics`.

**Reasoning:**
-   **Clearer Responsibilities**: `PDFPageProcessor` can focus on coordinating the extraction process, delegating specific tasks to specialized modules.
-   **Improved Testability**: Individual extraction components can be tested in isolation.
-   **Modularity**: Makes it easier to swap out or improve specific extraction algorithms without affecting the entire processor.

**Steps for Junior Developer:**

1.  **Create `TextExtractor.swift`:**
    *   Create a new file: `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/TextExtractor.swift`.
    *   Add the necessary `import` statements: `import Foundation`, `import PDFKit`, `import CoreGraphics`.
    *   Define a new struct or class, e.g., `struct TextExtractor { ... }`.
    *   Move `extractTextElements()` and `getBounds(for:)` from `PDFPageProcessor.swift` into `TextExtractor.swift`. Make them static functions.
    *   The `extractTextElements` function will need access to the `PDFPage` object. You will need to pass the `PDFPage` and `pageIndex` as parameters to this static function.

2.  **Create `VectorGraphicsExtractor.swift`:**
    *   Create a new file: `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/VectorGraphicsExtractor.swift`.
    *   Add the necessary `import` statements: `import Foundation`, `import PDFKit`, `import CoreGraphics`.
    *   Define a new struct or class, e.g., `struct VectorGraphicsExtractor { ... }`.
    *   Move `extractVectorGraphics()`, `sectionContainsImageContent(_:)`, and `renderPageSection(_:)` from `PDFPageProcessor.swift` into `VectorGraphicsExtractor.swift`. Make them static functions.
    *   These functions will need access to the `PDFPage`, `pageIndex`, and `dpi`. Pass them as parameters.

3.  **Update `PDFPageProcessor.swift`:**
    *   Remove the `extractTextElements`, `getBounds`, `extractVectorGraphics`, `sectionContainsImageContent`, and `renderPageSection` methods.
    *   In the `processPage()` method, replace calls to `extractTextElements()` with `TextExtractor.extractTextElements(from: pdfPage, pageIndex: pageIndex)`.
    *   Replace calls to `extractVectorGraphics()` with `VectorGraphicsExtractor.extractVectorGraphics(from: pdfPage, pageIndex: pageIndex, dpi: dpi)`.
    *   Remove the empty `extractImageElements()` method as it's not used and `CGPDFImageExtractor` is already called directly.

4.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable with a sample PDF to ensure text and vector graphics extraction still work correctly.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/PDFMarkdownConverterUltraOptimized.swift`

**Current State:**
This file contains two distinct classes: `PDFMarkdownConverterUltraOptimized` and `PDFPageProcessorUltraOptimized`. This is a clear violation of the single responsibility principle for files.

**Proposed Refactoring:**
Separate these two classes into their own dedicated files.

-   **New File:** `pdf22md/Sources/PDF22MD/PDFPageProcessorUltraOptimized.swift`
    -   Move the entire `PDFPageProcessorUltraOptimized` class into this new file.

**Reasoning:**
-   **Single Responsibility Principle**: Each file should ideally contain one primary class or a set of closely related functions.
-   **Improved Discoverability**: Developers will know exactly where to find the ultra-optimized page processing logic.
-   **Reduced File Size**: Makes both files smaller and easier to manage.

**Steps for Junior Developer:**

1.  **Create `PDFPageProcessorUltraOptimized.swift`:**
    *   Create a new file: `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/PDFPageProcessorUltraOptimized.swift`.
    *   Add the necessary `import` statements: `import Foundation`, `import PDFKit`, `import CoreGraphics`.
    *   Cut the entire `final class PDFPageProcessorUltraOptimized { ... }` definition from `PDFMarkdownConverterUltraOptimized.swift` and paste it into the new `PDFPageProcessorUltraOptimized.swift` file.

2.  **Update `PDFMarkdownConverterUltraOptimized.swift`:**
    *   Ensure that `PDFMarkdownConverterUltraOptimized.swift` still imports `PDFKit` and `Foundation`.
    *   Verify that the `PDFMarkdownConverterUltraOptimized` class correctly references `PDFPageProcessorUltraOptimized` (it should, as it's now in the same module).

3.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable using the `--ultra-optimized` flag to ensure the conversion still works.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/PDFMarkdownConverter.swift`

**Current State:**
This file contains the `PDFMarkdownConverter` class, which is the main async/await-based converter. Similar to `PDFMarkdownConverterOptimized`, it includes methods for font analysis (`analyzeFonts`) and Markdown generation (`generateMarkdown`).

**Proposed Refactoring:**
Leverage the newly created `FontAnalyzer.swift` and `MarkdownGenerator.swift` files.

-   **Reuse:** `pdf22md/Sources/PDF22MD/MarkdownGenerator.swift`
    -   The `generateMarkdown(from:fontStats:)` method in `MarkdownGenerator.swift` should be designed to be generic enough to be used by both `PDFMarkdownConverter` and `PDFMarkdownConverterOptimized`.
-   **Reuse:** `pdf22md/Sources/PDF22MD/FontAnalyzer.swift`
    -   The `analyzeFonts(from:)` method in `FontAnalyzer.swift` should also be generic enough for both converters.

**Reasoning:**
-   **Code Duplication**: Avoid duplicating the font analysis and Markdown generation logic across different converter implementations.
-   **Consistency**: Maintain a consistent structure for how these common tasks are handled.
-   **Maintainability**: Changes to font analysis or Markdown generation only need to be made in one place.

**Steps for Junior Developer:**

1.  **Ensure `MarkdownGenerator.swift` and `FontAnalyzer.swift` are Generic:**
    *   Before starting this step, ensure you have completed the refactoring for `PDFMarkdownConverterOptimized.swift` and that `MarkdownGenerator.swift` and `FontAnalyzer.swift` contain static methods that accept all necessary parameters (e.g., `pdfURL` or `pdfBasename` for `MarkdownGenerator`, and `elements` for `FontAnalyzer`).

2.  **Update `PDFMarkdownConverter.swift`:**
    *   Remove the `analyzeFonts` and `generateMarkdown` methods from `PDFMarkdownConverter.swift`.
    *   In the `convert()` method, replace calls to `self.analyzeFonts(...)` with `FontAnalyzer.analyzeFonts(...)`.
    *   Replace calls to `self.generateMarkdown(...)` with `MarkdownGenerator.generateMarkdown(...)`.
    *   Ensure `AssetExtractor` is initialized correctly and passed to `MarkdownGenerator.generateMarkdown` if needed.

3.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable (without `--optimized` or `--ultra-optimized` flags) with a sample PDF to ensure the conversion still works as expected.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/CGPDFImageExtractor.swift`

**Current State:**
This file contains the `CGPDFImageExtractor` struct and its private helper methods (`extractXObjectImages`, `createImage`, `createImageFromRawData`, `getImageBounds`). These methods are tightly coupled to the process of extracting images from `CGPDFPage` objects.

**Proposed Refactoring:**
While the current structure is already quite cohesive, we can extract the image creation logic into a separate utility if it's deemed reusable outside of this specific extractor. For now, given its specific use case, we will keep the core extraction logic together. However, the `createImage` and `createImageFromRawData` methods could be moved to a more general `CGImageUtilities.swift` file if there's a future need for similar image creation from raw data elsewhere. For this refactoring, we will focus on making the internal structure cleaner.

-   **Internal Refinement:**
    -   Ensure `createImage`, `createImageFromRawData`, and `getImageBounds` are clearly marked as private helpers within `CGPDFImageExtractor`.

**Reasoning:**
-   **Cohesion**: All methods in `CGPDFImageExtractor` are directly related to extracting images from PDF pages using CoreGraphics.
-   **Future-Proofing**: If image creation logic becomes more generic, it can be easily extracted later.

**Steps for Junior Developer:**

1.  **Review `CGPDFImageExtractor.swift`:**
    *   Open `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/CGPDFImageExtractor.swift`.
    *   Verify that `createImage`, `createImageFromRawData`, and `getImageBounds` are declared as `private static func`.

2.  **No Code Movement (for now):**
    *   For this file, the primary task is to confirm its internal structure is sound. No code needs to be moved to new files at this stage.

3.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable with a sample PDF that includes images to ensure image extraction still works.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/PDFPageProcessorOptimized.swift`

**Current State:**
This file contains the `PDFPageProcessorOptimized` class, which is an optimized version of the page processor. It includes `extractTextElements`, `extractImageElements`, and `extractVectorGraphics`.

**Proposed Refactoring:**
Similar to `PDFPageProcessor.swift`, we will leverage the `TextExtractor` and `VectorGraphicsExtractor` modules.

-   **Reuse:** `pdf22md/Sources/PDF22MD/TextExtractor.swift`
    -   The `extractTextElements` method in `TextExtractor.swift` should be generic enough to be used by `PDFPageProcessorOptimized`.
-   **Reuse:** `pdf22md/Sources/PDF22MD/VectorGraphicsExtractor.swift`
    -   The `extractVectorGraphics` method in `VectorGraphicsExtractor.swift` should be generic enough to be used by `PDFPageProcessorOptimized`.

**Reasoning:**
-   **Eliminate Duplication**: Avoid re-implementing text and vector graphics extraction logic.
-   **Consistency**: Ensure both optimized and non-optimized page processors use the same underlying extraction logic.

**Steps for Junior Developer:**

1.  **Ensure `TextExtractor.swift` and `VectorGraphicsExtractor.swift` are Generic:**
    *   Before starting this step, ensure you have completed the refactoring for `PDFPageProcessor.swift` and that `TextExtractor.swift` and `VectorGraphicsExtractor.swift` contain static methods that accept all necessary parameters.

2.  **Update `PDFPageProcessorOptimized.swift`:**
    *   Remove the `extractTextElements` and `extractVectorGraphics` methods from `PDFPageProcessorOptimized.swift`.
    *   In the `processPage()` method, replace calls to `extractTextElements()` with `TextExtractor.extractTextElements(from: pdfPage, pageIndex: pageIndex)`.
    *   Replace calls to `extractVectorGraphics()` with `VectorGraphicsExtractor.extractVectorGraphics(from: pdfPage, pageIndex: pageIndex, dpi: dpi)`.
    *   The `extractImageElements()` method in `PDFPageProcessorOptimized` already calls `CGPDFImageExtractor.extractImages`. Ensure this call is correct and that `CGPDFImageExtractor` is imported.

3.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable using the `--optimized` flag with a sample PDF to ensure text, image, and vector graphics extraction still work correctly.

---

## Refactoring Plan for `pdf22md/Sources/PDF22MD/AssetExtractor.swift`

**Current State:**
This file contains the `AssetExtractor` class, responsible for saving image assets and determining their format. It includes private helper methods `shouldUsePNG`, `savePNG`, and `saveJPEG`.

**Proposed Refactoring:**
The image saving logic (`savePNG`, `saveJPEG`) and format decision (`shouldUsePNG`) could be moved to a more general `ImageUtilities.swift` file if there's a future need for these functionalities outside of `AssetExtractor`. For this refactoring, we will keep the core asset extraction logic together, but ensure the internal helpers are well-defined.

-   **Internal Refinement:**
    -   Ensure `shouldUsePNG`, `savePNG`, and `saveJPEG` are clearly marked as `private func`.

**Reasoning:**
-   **Cohesion**: All methods in `AssetExtractor` are directly related to managing and saving assets.
-   **Future-Proofing**: If image saving logic becomes more generic, it can be easily extracted later.

**Steps for Junior Developer:**

1.  **Review `AssetExtractor.swift`:**
    *   Open `/Users/adam/Developer/vcs/github.twardoch/pub/pdf22md/pdf22md/Sources/PDF22MD/AssetExtractor.swift`.
    *   Verify that `shouldUsePNG`, `savePNG`, and `saveJPEG` are declared as `private func`.

2.  **No Code Movement (for now):**
    *   For this file, the primary task is to confirm its internal structure is sound. No code needs to be moved to new files at this stage.

3.  **Build and Test:**
    *   Run `make build` from the project root.
    *   Run `make test` from the project root.
    *   Manually test the `pdf22md` executable with a sample PDF that includes images to ensure image saving still works.

---

This detailed plan provides a clear roadmap for splitting the identified large Swift files. Remember to follow the general guidelines, especially building and testing after each incremental change. Good luck!
