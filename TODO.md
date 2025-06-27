# TODO - Linearized Implementation Plan

## 🚨 PRIORITY 1: Implementation Renaming (pdf21md / pdf22md)

### Phase 1: Directory Renaming
- [x] Rename `pdf22md-objc/` directory to `pdf21md/`
- [ ] Keep `pdf22md/` directory as is

### Phase 2: Objective-C Updates (pdf21md)
#### Makefile
- [ ] Change target name from `pdf22md` to `pdf21md`
- [ ] Update `BINARY_NAME = pdf21md`
- [ ] Update installation path references

#### Source Code Renaming
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `src/CLI/` (all .h/.m files)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `src/Core/` (all .h/.m files)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `src/Models/` (all .h/.m files)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `src/Services/` (all .h/.m files)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `shared-core/` (all utility classes)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `shared-algorithms/` (all algorithm classes)
- [ ] Change class prefix `PDF22MD` to `PDF21MD` in `Tests/` (all test files)
- [ ] Update all `#import` statements to use new class names
- [ ] Update all `@class` forward declarations

### Phase 3: Swift Updates (pdf22md)
- [ ] Update Package.swift: Change executable product name from `pdf22md` to `pdf22md`
- [ ] Update main.swift: Change `commandName` from `pdf22md` to `pdf22md`

### Phase 4: Build Scripts
- [ ] Update build.sh: Replace all `pdf22md-objc` with `pdf21md`
- [ ] Update build.sh: Ensure both binaries are installed: `pdf21md` and `pdf22md`
- [ ] Update test_both.sh: Update all directory references
- [ ] Update test_both.sh: Update binary execution paths
- [ ] Update release.sh if it exists

### Phase 5: Documentation Updates
- [ ] Update README.md with new binary names
- [ ] Update CHANGELOG.md with renaming entry
- [x] Update CLAUDE.md project description
- [ ] Update pdf21md/README.md (formerly pdf22md-objc/README.md)
- [ ] Update pdf22md/README.md
- [ ] Create/update man pages for pdf21md and pdf22md

## 🚨 PRIORITY 2: Fix Markdown Output Generation

### Objective-C (pdf21md) Debugging
#### CLI Enhancement (`src/CLI/main.m`)
- [ ] Add debug flag (`-v/--verbose`) to show conversion progress
- [ ] Log markdown string length and first 100 chars before file write
- [ ] Add detailed error reporting for file write operations
- [ ] Verify output path permissions and parent directory existence
- [ ] Add fallback to stdout when file write fails

#### Markdown Generator (`src/Services/PDF21MDMarkdownGenerator.m`)
- [ ] Add element count validation (log how many elements processed)
- [ ] Log markdown generation stages (frontmatter, content, links)
- [ ] Validate non-empty output before returning
- [ ] Add error propagation for generation failures
- [ ] Add null/empty string checks

#### Converter Pipeline (`src/Core/PDF21MDConverter.m`)
- [ ] Log element extraction results per page
- [ ] Validate font analysis results (heading detection working)
- [ ] Monitor parallel processing completion
- [ ] Add timeout handling for stuck operations

### Swift (pdf22md) Debugging
#### Error Handling Enhancement
- [ ] Add comprehensive try-catch blocks around file operations
- [ ] Log conversion pipeline progress and intermediate results
- [ ] Validate markdown content length before writing
- [x] Add permission and path validation
- [x] Check parent directory existence and permissions
- [ ] Implement debug output mode

#### File Writing Robustness
- [ ] Add file write validation and retry logic
- [ ] Check parent directory existence and permissions
- [ ] Add atomic write operations with backup
- [ ] Implement fallback to stdout on file write failure

### Testing & Validation
- [ ] Test with `_private/jlm.pdf` to reproduce exact failure
- [ ] Add minimal test PDF with predictable content
- [ ] Verify conversion pipeline with simple document
- [ ] Create debug mode showing element extraction details
- [ ] Add validation scripts to verify markdown output quality

## 🚨 PRIORITY 2.5: Raster Image Extraction Improvements (Both Implementations)
- [ ] Create docs/IMAGE_EXTRACTION_ALGORITHM.md describing approach
- [ ] Add test PDFs with raster images for unit tests

### Swift (`pdf22md`)
- [x] Add CGPDFImageExtractor.swift (phase-1: annotation-based) and integrated into processors
- [x] Wire extractor into PDFPageProcessor & Optimized variant
- [ ] Implement down-scale (>20 MP) safeguard
- [ ] Update AssetExtractor with optional maxDimension parameter
- [ ] Unit test: verify images saved & format choice

### Objective-C (`pdf21md`)
- [ ] Add PDF21MDRawImageExtractor helper (category on CGPDFPage)
- [ ] Integrate into PageProcessor before heuristic grid scan
- [ ] Ensure PNG/JPEG selection parity with Swift
- [ ] Unit test raster extraction

### Shared / CLI / Tooling
- [ ] Add --no-images flag & hidden -m max-dimension flag
- [ ] Update test_new.sh assertions for asset counts
- [ ] Update README/man-pages with image extraction notes
- [ ] Update build.sh to include new files

## Priority 4: Code Quality Fixes
- [x] Remove unused `fontName` variable in PDFPageProcessorOptimized.swift:70
- [ ] Add comprehensive error messages throughout codebase
- [ ] Implement progress reporting for long conversions
- [ ] Add user-friendly error messages

## Phase 5: Testing & Integration
- [ ] End-to-end conversion validation with multiple PDFs
- [ ] Asset and markdown coordination testing
- [ ] Error recovery testing with simulated failures
- [ ] Performance regression testing
- [ ] Cross-implementation output comparison

## Phase 6: Release Preparation
- [ ] Ensure both `pdf21md` and `pdf22md` work correctly
- [ ] Update all documentation with correct binary names
- [ ] Create Homebrew formulas for both tools
- [ ] Set up GitHub Actions CI/CD
- [ ] Prepare release notes and announcement

## Success Criteria
- [x] PLAN.md updated with renaming strategy
- [ ] Both implementations renamed correctly
- [ ] Both tools generate Markdown files successfully
- [ ] Image extraction continues to work
- [ ] No critical warnings or errors
- [ ] Documentation is accurate
- [ ] Ready for public release