# PDF to Markdown Converter - Project Plan

## 🚨 **PRIORITY 1: Implementation Renaming (pdf21md / pdf22md)**

### Overview
The project will maintain two implementations with distinct names:
- **pdf21md**: Objective-C implementation (formerly pdf22md-objc)
- **pdf22md**: Swift implementation (formerly pdf22md-swift)

### Renaming Strategy - CRITICAL FIRST STEPS

#### Phase 1: Directory Structure (DO FIRST)
1. ✅ Rename `pdf22md-objc/` directory to `pdf21md/`
2. Keep `pdf22md-swift/` directory as is (already correct)

#### Phase 2: Update Objective-C Implementation (pdf21md)
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

#### Phase 3: Update Swift Implementation (pdf22md)
1. **Package.swift**:
   - Change executable product name from `pdf22md-swift` to `pdf22md`
   - Update executable target name

2. **main.swift**:
   - Change `commandName` from `pdf22md-swift` to `pdf22md`

#### Phase 4: Update Build and Test Scripts
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

#### Phase 5: Update Documentation
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

## 🚨 **PRIORITY 2: Critical Bug Fix - No Markdown Output**

### Issue Summary
Both implementations currently:
- ✅ Successfully process PDF pages
- ✅ Extract and save images to assets folder (134 PNGs)
- ❌ **FAIL to generate the actual Markdown file**

### Root Cause Analysis
The conversion pipeline completes all steps except writing the final markdown file. Possible causes:
1. Text extraction returning empty results
2. Markdown generator producing empty string
3. File writing silently failing
4. Output path calculation errors

### Investigation Plan

#### Objective-C (pdf21md) Investigation
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

#### Swift (pdf22md) Investigation  
1. **Check PDFConverter**:
   - Verify text extraction logic exists
   - Log element extraction results
   - Validate markdown generation call

2. **Check MarkdownWriter**:
   - Ensure file writing is implemented
   - Add error handling for I/O operations
   - Validate output path

### Fix Implementation Steps
1. Add comprehensive logging throughout conversion pipeline
2. Implement missing markdown generation if not present
3. Add error handling and validation at each stage
4. Test with simple PDF to isolate issues
5. Ensure both implementations have feature parity

## Priority 3: Fix CMap Warnings

### Issue
"can't create CMap 'Adobe-Identity-UCS2'" warnings appear during processing

### Plan
1. Research PDF font encoding requirements
2. Check if warnings affect text extraction quality
3. Implement proper CMap handling or suppress if benign

## Priority 4: Minor Code Quality Fixes

### Swift Implementation
- Remove unused `fontName` variable in PDFPageProcessorOptimized.swift:70

## Implementation Roadmap

### Week 1: Critical Fixes
1. **Days 1-2**: Complete renaming of implementations
2. **Days 3-4**: Fix markdown output generation bug
3. **Day 5**: Test and validate fixes

### Week 2: Polish and Testing
1. Fix CMap warnings
2. Add comprehensive test coverage
3. Performance optimization
4. Documentation updates

### Week 3: Release Preparation
1. Create Homebrew formulas
2. Set up GitHub Actions CI/CD
3. Prepare release documentation
4. Community guidelines

## Success Criteria
1. ✅ `pdf21md` (Objective-C) compiles and runs correctly
2. ✅ `pdf22md` (Swift) compiles and runs correctly  
3. ✅ Both tools successfully generate Markdown files from PDFs
4. ✅ Image extraction works correctly
5. ✅ No critical warnings or errors
6. ✅ Documentation is accurate and complete
7. ✅ Ready for public release

## Key Decisions
- Maintain two implementations with distinct binary names
- pdf21md for Objective-C (legacy/stable)
- pdf22md for Swift (modern/future)
- Focus on fixing critical bugs before adding new features
- Ensure both implementations have feature parity