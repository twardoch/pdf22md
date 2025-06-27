# PDF to Markdown Converter - Project Plan

## 1. 🚨 **PRIORITY 1: Implementation Renaming (pdf21md / pdf22md)**

### 1.1. Overview
The project will maintain two implementations with distinct names:
- **pdf21md**: Objective-C implementation (formerly pdf22md-objc)
- **pdf22md**: Swift implementation (formerly pdf22md-swift)

### 1.2. Renaming Strategy - CRITICAL FIRST STEPS

#### 1.2.1. Phase 1: Directory Structure (DO FIRST)
1. ✅ Rename `pdf22md-objc/` directory to `pdf21md/`
2. Keep `pdf22md-swift/` directory as is (already correct)

#### 1.2.2. Phase 2: Update Objective-C Implementation (pdf21md)
1. **Makefile Updates**:
   - Change target name from `pdf22md` to `pdf21md`
   - Update `BINARY_NAME = pdf21md`
   - Update installation path references

2. **Source Code Class Prefix Changes**:
   - Change all class prefixes from `PDF22MD` to `PDF21MD` in:
     - `src/CLI/` - all `.h` and `.m` files
     - `src/Core/` - all `.h` and `.m` files  
     - `src/Models/` - all `.h` and `.m` files
     - `src/Services/` - all `.h` and `.m` files
     - `shared-core/` - all utility classes
     - `shared-algorithms/` - all algorithm classes
     - `Tests/` - all test files
   - Update all `#import` statements to use new class names
   - Update all `@class` forward declarations

#### 1.2.3. Phase 3: Update Swift Implementation (pdf22md)
1. **Package.swift**:
   - Change executable product name from `pdf22md-swift` to `pdf22md`
   - Update executable target name

2. **main.swift**:
   - Change `commandName` from `pdf22md-swift` to `pdf22md`

#### 1.2.4. Phase 4: Update Build and Test Scripts
1. **build.sh**:
   - Replace all `pdf22md-objc` with `pdf21md`
   - Update binary paths and installation logic
   - Ensure both binaries are installed: `pdf21md` and `pdf22md`

2. **test_both.sh**:
   - Update all directory references
   - Update binary execution paths
   - Fix test output paths

3. **release.sh** (if exists):
   - Update all references

#### 1.2.5. Phase 5: Update Documentation
1. **Main documentation**:
   - README.md - update all references
   - CHANGELOG.md - add renaming entry
   - TODO.md - update as linearized PLAN.md
   - CLAUDE.md - update project description

2. **Implementation docs**:
   - pdf21md/README.md (formerly pdf22md-objc/README.md)
   - pdf22md-swift/README.md

3. **Other docs**:
   - docs/pdf22md.1 - create separate man pages for pdf21md and pdf22md
   - Any other documentation files

## 2. 🚨 **PRIORITY 2: Critical Bug Fix - No Markdown Output**

### 2.1. Issue Summary
Both implementations currently:
- ✅ Successfully process PDF pages
- ✅ Extract and save images to assets folder (134 PNGs)
- ❌ **FAIL to generate the actual Markdown file**

### 2.2. Root Cause Analysis
The conversion pipeline completes all steps except writing the final markdown file. Possible causes:
1. Text extraction returning empty results
2. Markdown generator producing empty string
3. File writing silently failing
4. Output path calculation errors

### 2.3. Investigation Plan

#### 2.3.1. Objective-C (pdf21md) Investigation
1. **Check PDF21MDConverter**:
   - Add logging for extracted elements count
   - Verify text elements are being created
   - Log markdown string before file write

2. **Check PDF21MDMarkdownGenerator**:
   - Validate input elements array
   - Log each markdown generation stage
   - Ensure non-empty output

3. **Check main.m**:
   - Add file write validation
   - Check output path permissions
   - Add fallback to stdout if file write fails

#### 2.3.2. Swift (pdf22md) Investigation  
1. **Check PDFConverter**:
   - Verify text extraction logic exists
   - Log element extraction results
   - Validate markdown generation call

2. **Check MarkdownWriter**:
   - Ensure file writing is implemented
   - Add error handling for I/O operations
   - Validate output path

### 2.4. Fix Implementation Steps
1. Add comprehensive logging throughout conversion pipeline
2. Implement missing markdown generation if not present
3. Add error handling and validation at each stage
4. Test with simple PDF to isolate issues
5. Ensure both implementations have feature parity

## 3. Priority 3: Fix CMap Warnings

### 3.1. Issue
"can't create CMap 'Adobe-Identity-UCS2'" warnings appear during processing

### 3.2. Plan
1. Research PDF font encoding requirements
2. Check if warnings affect text extraction quality
3. Implement proper CMap handling or suppress if benign

## 4. Priority 4: Minor Code Quality Fixes

### 4.1. Swift Implementation
- Remove unused `fontName` variable in PDFPageProcessorOptimized.swift:70

## 5. 🚨 **PRIORITY 2.5: Add Robust Raster-Image Extraction (Swift & Objective-C)**

### 5.1. Current State
1. **Swift (`pdf22md`)**
   • `PDFPageProcessor.extractImageElements()` and the optimized variant are stubs – raster images are never detected.
2. **Objective-C (`pdf21md`)**
   • There is a heuristic that renders page regions and annotation snapshots, but it misses many photos and performs unnecessary rasterisation work.

### 5.2. Overarching Goals
1. Extract every raster image that exists inside the PDF (embedded XObject images) **without** unnecessary re-rasterisation.
2. Preserve image quality and original dimensions; use smart format selection (PNG vs JPEG) already present in `AssetExtractor` / `PDF21MDAssetManager`.
3. Keep processing fast by avoiding full-page renders; leverage multi-core.
4. Maintain identical Markdown references between implementations.

### 5.3. Detailed Step-by-Step Plan

#### 5.3.1. Groundwork
0.1 Create shared documentation page `docs/IMAGE_EXTRACTION_ALGORITHM.md` describing the algorithm flow once implemented.  
0.2 Add new unit-test PDFs (tiny with single photo; complex with mixed vector + raster).

#### 5.3.2. Swift Implementation
1.1 Add new file `CGPDFImageExtractor.swift` under `PDF22MD/Sources/PDF22MD/` implementing:  
 • Scans each `CGPDFPage` resource dictionary → `/XObject` → image objects (`Subtype = Image`).  
 • Extracts the image stream into `CGImage` via `CGPDFImageCreate` or manual decode when necessary.  
 • Returns `[ImageElement]` array.
1.2 Wire this into `PDFPageProcessor.extractImageElements()` (standard & optimised). Fallback to annotation/grid heuristic **only if** XObject scan returns 0 images.
1.3 Add caching of colour-spaces to reduce allocations.
1.4 Guard against very large images (>20 MP) by down-scaling using `vImageScale`.
1.5 Unit tests: `PDF22MDTests/AssetExtractorImageTests.swift` verifying:
 • Number of images saved matches expectation.  
 • PNG chosen when alpha; JPEG chosen otherwise.
1.6 Integration test updates in `test_new.sh` – assert asset count ≥ 1 for large PDF.

#### 5.3.3. Objective-C Implementation
2.1 Create helper class `PDF21MDRawImageExtractor` (ObjC category on `CGPDFPage`).  
 • Mirrors Swift's XObject traversal using Core Graphics C APIs.  
 • Converts image streams into `CGImageRef`.
2.2 Refactor existing `extractImageElements` to first call raw extractor; keep annotation/grid heuristics as fallback only.
2.3 Implement identical down-scale rule & smart PNG/JPEG selection (reuse existing utility).
2.4 Add lock-free batching to allow concurrent extraction on separate pages.
2.5 Add unit test `PDF21MDAssetExtractorImageTests.m` validating same conditions as Swift.

#### 5.3.4. Shared Enhancements
3.1 Extend `AssetExtractor` / `PDF21MDAssetManager` with optional `maxDimension` parameter (default = no resize) so down-scale can be configured via CLI (`-m` flag, hidden for now).
3.2 CLI: add `--no-images` switch to skip extraction when user not interested (helps benchmarking).
3.3 Progress reporting: include per-page "images found" count in verbose/debug modes.

#### 5.3.5. Documentation & Tooling
4.1 Update man-pages, README examples, and usage descriptions to mention image extraction improvements.  
4.2 Update `CHANGELOG.md` under **Added** & **Changed**.
4.3 Ensure `build.sh` includes new Swift source file and Objective-C .m file automatically.
4.4 Update Homebrew formula placeholders with new version.

#### 5.3.6. Timeline / Milestones
• Day 1: Swift extractor prototype (single image PDF) + tests passing.  
• Day 2: Finish Swift integration + down-scale; update AssetExtractor.  
• Day 3: Objective-C raw extractor & integration.  
• Day 4: CLI flags, shared docs, unit/integration test green.  
• Day 5: Clean-up, docs, release candidate.

### 5.4. Risks & Mitigations
• **Complex encodings (JPEG2000, CCITT)** – rely on Core Graphics decode; fallback to region render if decode fails.  
• **Large images memory spikes** – cap size, process in autoreleasepool, use down-scale.  
• **Performance regressions** – keep XObject scan light, use concurrent queues.

### 5.5. Success Criteria
✔ `test_new.sh` passes with ≥ 1 asset for large PDF on both implementations.  
✔ Code coverage > 85 % for new extractor classes.  
✔ No hangs with 500-page mixed PDF in < 2× current conversion time.

## 6. Implementation Roadmap

### 6.1. Week 1: Critical Fixes
1. **Days 1-2**: Complete renaming of implementations
2. **Days 3-4**: Fix markdown output generation bug
3. **Day 5**: Test and validate fixes

### 6.2. Week 2: Polish and Testing
1. Fix CMap warnings
2. Add comprehensive test coverage
3. Performance optimization
4. Documentation updates

### 6.3. Week 3: Release Preparation
1. Create Homebrew formulas
2. Set up GitHub Actions CI/CD
3. Prepare release documentation
4. Community guidelines

## 7. Success Criteria
1. ✅ `pdf21md` (Objective-C) compiles and runs correctly
2. ✅ `pdf22md` (Swift) compiles and runs correctly  
3. ✅ Both tools successfully generate Markdown files from PDFs
4. ✅ Image extraction works correctly
5. ✅ No critical warnings or errors
6. ✅ Documentation is accurate and complete
7. ✅ Ready for public release

## 8. Key Decisions
- Maintain two implementations with distinct binary names
- pdf21md for Objective-C (legacy/stable)
- pdf22md for Swift (modern/future)
- Focus on fixing critical bugs before adding new features
- Ensure both implementations have feature parity