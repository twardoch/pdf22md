# TODO

## 🚨 CRITICAL: Fix Hanging Issue (Highest Priority)

<!-- RESOLVED: Hanging issue fixed in src/PDFPageProcessor.m (2025-06-22) -->

The tool currently hangs when processing PDF files. This must be fixed before any other work.

I run `./pdf22md -i test/README.pdf` and I get the content of `issues/issue101.txt` and then it hangs. FIXME!



### Root Cause Analysis
- **Issue**: `CGPDFScannerScan` hangs indefinitely on certain PDFs (confirmed with test/jlm-bachotex2013a.pdf)
- **Location**: `src/PDFPageProcessor.m` in the `extractContentElements` method
- **Cause**: The PDF content scanner enters an infinite loop or deadlock condition

### Detailed Fix Plan

1. **Replace Low-Level PDF Scanning** ⚠️
   - [ ] Remove the manual CGPDFScanner implementation
   - [ ] Use PDFKit's high-level API instead (PDFPage string extraction)
   - [ ] Fallback: Add operation count limits and timeouts

2. **Implement Robust PDF Processing**
   - [ ] Use PDFPage's `string` property for text extraction
   - [ ] Use PDFPage's `attributedString` for formatting info
   - [ ] Extract images using PDFPage annotations/media
   - [ ] Handle vector graphics as rendered bitmaps only

3. **Add Safety Mechanisms**
   - [ ] Implement per-page processing timeout (5 seconds max)
   - [ ] Add graceful error recovery for failed pages
   - [ ] Log and skip problematic content instead of hanging

4. **Testing Strategy**
   - [ ] Test with both problematic PDFs (jlm-bachotex2013a.pdf, digitallegacies-twardoch2018.pdf)
   - [ ] Add test cases for various PDF types (text-only, image-heavy, complex graphics)
   - [ ] Verify no memory leaks or crashes

### Implementation Steps

```objc
// Replace current implementation with:
- (NSArray<id<ContentElement>> *)extractContentElements {
    NSMutableArray<id<ContentElement>> *elements = [NSMutableArray array];
    
    // Use PDFKit's high-level API
    NSString *pageText = [self.pdfPage string];
    if (pageText && pageText.length > 0) {
        TextElement *textElement = [[TextElement alloc] init];
        textElement.text = pageText;
        textElement.pageIndex = self.pageIndex;
        [elements addObject:textElement];
    }
    
    // Extract images separately
    // ... simplified image extraction ...
    
    return elements;
}
```

## Completed Tasks ✅

All professional repository refactoring tasks have been completed:

- [x] Cleaned up build artifacts (.o files) from root directory
- [x] Updated Makefile to use dedicated build directory
- [x] Fixed .gitignore to properly exclude build artifacts
- [x] Added MIT LICENSE file
- [x] Created GitHub issue templates (bug_report.md, feature_request.md)
- [x] Fixed GitHub Actions workflow (build-release.yml)
- [x] Added comprehensive CHANGELOG.md
- [x] Reviewed and applied PR #1 suggestions (already merged)
- [x] Created release.sh script for semver versioning
- [x] Developed GitHub action for macOS builds on semver tags (release.yml)
- [x] Removed verbose DEBUG logging from converter and processor (code cleanup).
- [x] Fixed hanging issue by replacing low-level CGPDFScanner logic with PDFKit high-level text extraction (`src/PDFPageProcessor.m`).

## Future Enhancements (After Core Fix)

### Core Features
- [ ] Preserve PDF bookmarks/outline structure and extracting metadata (author, title, creation date) into YAML frontmatter
- [ ] Improve heading detection algorithm
- [ ] Better handling of tables and lists
- [ ] Support for PDF forms and annotations

### Code Quality
- [ ] Add unit tests for core functionality
- [ ] Implement proper error handling with descriptive messages
- [ ] Add code comments and documentation
- [ ] Create man page for the tool
- [ ] Add performance benchmarks

### Distribution
- [ ] Create Homebrew formula for easy installation
- [ ] Set up automated nightly builds
- [ ] Add support for Linux (using GNUstep)
- [ ] Create Docker image for cross-platform usage

### Documentation
- [ ] Add detailed API documentation
- [ ] Write blog post about the implementation
- [ ] Add more examples to README
