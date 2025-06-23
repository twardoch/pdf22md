# TODO

## ✅ Completed

### Phase 1: Core Functionality
- [x] Asset extraction - Fixed segmentation fault, extracts all embedded images (PNG/JPG chosen automatically) and rasterizes vector graphics

### Build & Benchmark Infrastructure
- [x] Created build.sh script with options for building both implementations
- [x] Created bench.sh script for running performance benchmarks
- [x] Updated documentation for build and benchmark processes

## 🚀 Immediate Priority

### Phase 2: Distribution & Release
- [ ] Create Homebrew formula and tap for easy installation (`brew install twardoch/pdf22md/pdf22md`)
- [ ] Test Homebrew installation process on clean macOS system
- [ ] Add Homebrew installation verification to CI/CD
- [ ] Create release automation script
- [ ] Set up GitHub Actions for automated releases

### Phase 3: Core Feature Enhancements
- [ ] Preserve PDF bookmarks/outline structure and extract metadata (author, title, creation date) into YAML frontmatter
- [ ] Improve heading detection algorithm with better font size analysis
- [ ] Better handling of tables (detect table structures and convert to Markdown tables)
- [ ] Better handling of lists (detect bullet points and numbered lists)
- [ ] Support for PDF forms and annotations extraction
- [ ] Handle multi-column layouts intelligently

## 🎯 Swift Performance Optimization

### Analysis Summary (Based on Benchmarks)
The Swift implementation is 3.7x-35x slower than Objective-C, with the gap widening for larger PDFs. Memory usage is 3.7x-5.6x higher. The GCD-optimized version shows minimal improvement (~3% faster than async/await).

### Root Causes Identified
1. **Swift/ObjC Bridge Overhead**: Frequent calls to Core Graphics C APIs incur bridging costs
2. **String Processing**: Swift String is significantly slower than NSString for text manipulation
3. **Memory Management**: ARC overhead in Swift vs optimized manual retain/release in ObjC
4. **Collection Types**: Swift Array has more overhead than C arrays used in ObjC
5. **Concurrency Model**: Both async/await and GCD in Swift have more overhead than raw GCD in ObjC

### High-Impact Optimizations (Priority 1)
- [ ] Create C wrapper functions for Core Graphics calls to minimize bridge overhead
- [ ] Use NSString and NSMutableString instead of Swift String throughout
- [ ] Implement memory pooling for PDFElement objects
- [ ] Use UnsafeBufferPointer for element collections
- [ ] Pre-allocate all collections with expected capacity
- [ ] Cache CGFont objects to avoid repeated lookups

### Medium-Impact Optimizations (Priority 2)  
- [ ] Use @_cdecl to expose Swift functions directly to C
- [ ] Implement custom memory allocator for small objects
- [ ] Batch Core Graphics operations to reduce API calls
- [ ] Use simd operations for coordinate calculations
- [ ] Implement zero-copy string slicing
- [ ] Add compiler optimization flags (-Ounchecked, -whole-module-optimization)

### Low-Impact Optimizations (Priority 3)
- [ ] Mark all possible functions as @inlinable and @inline(__always)
- [ ] Use ContiguousArray instead of Array where possible
- [ ] Implement lazy evaluation for markdown generation
- [ ] Use DispatchIO for file operations
- [ ] Profile with Instruments and optimize hot paths
- [ ] Consider using Swift's unsafe APIs for critical sections

### Experimental Approaches
- [ ] Write PDF processing core in C and call from Swift
- [ ] Use Metal Performance Shaders for parallel processing
- [ ] Explore SIMD instructions for text processing
- [ ] Investigate custom Swift runtime flags
- [ ] Try alternative PDF parsing libraries (not PDFKit)
- [ ] Implement streaming processing to reduce memory usage

## 📋 Development Tasks

### Code Quality & Testing
- [ ] Add unit tests for both ObjC and Swift implementations
- [ ] Create integration tests comparing output between versions
- [ ] Implement proper error handling with descriptive messages
- [ ] Add inline code documentation
- [ ] Set up continuous integration (GitHub Actions)
- [ ] Add code coverage reporting for both implementations
- [ ] Implement logging with configurable verbosity levels

### Documentation
- [ ] Add usage examples for different PDF types to README.md
- [ ] Create man page for the tool (`man pdf22md`)
- [ ] Document known limitations and workarounds
- [ ] Add troubleshooting section to README.md
- [ ] Create CONTRIBUTING.md for open source contributors
- [ ] Add API documentation for developers
- [ ] Document build process for different platforms

### Performance Optimizations
- [ ] Profile memory usage and optimize for large PDFs
- [ ] Optimize concurrent processing for better CPU utilization
- [ ] Implement streaming mode for extremely large PDFs
- [ ] Add progress reporting for long operations
- [ ] Cache font analysis results across pages

## ✅ Phase 4: Swift Port (COMPLETED)

### Overview
The Swift port has been completed and both implementations are now available. Performance benchmarking shows the Objective-C version remains significantly faster.

### Completed Items
- [x] Created Swift directory structure with Package.swift
- [x] Implemented PDFElement protocol hierarchy (TextElement, ImageElement)
- [x] Ported PDFPageProcessor with async/await concurrency
- [x] Ported PDFMarkdownConverter with TaskGroup for parallel processing
- [x] Implemented AssetExtractor with smart PNG/JPEG selection
- [x] Created CLI using Swift Argument Parser
- [x] Built comprehensive benchmarking suite (Python and shell scripts)
- [x] Generated test PDFs with varying complexity

### Performance Results
- Small PDFs (5 pages): ObjC 3.7x faster
- Medium PDFs (50 pages): ObjC 20x faster 
- Large PDFs (200 pages): ObjC 35x faster
- Memory usage: Swift uses 3.7-5.6x more memory

The performance gap is primarily due to:
1. Swift's overhead when calling Core Graphics C APIs
2. String processing differences between Swift and NSString
3. ARC overhead in Swift vs manual memory management in ObjC
4. Swift async/await overhead vs raw GCD

## 🌍 Future Enhancements

### Cross-Platform Support
- [ ] Add support for Linux (using GNUstep)
- [ ] Create Docker image for cross-platform usage
- [ ] Add Windows support via WSL or native compilation
- [ ] Set up automated nightly builds for all platforms

### Advanced Features
- [ ] Add OCR support for scanned PDFs (using Vision framework)
- [ ] Support for password-protected PDFs
- [ ] Add batch processing mode for multiple PDFs
- [ ] Create GUI version using SwiftUI
- [ ] Add plugin system for custom transformations
- [ ] Support for PDF/A archival format
- [ ] Add support for extracting embedded files from PDFs

### Community & Documentation
- [ ] Write technical blog post about the implementation
- [ ] Create video tutorials for common use cases
- [ ] Add performance benchmarking documentation
- [ ] Set up community forum or Discord
- [ ] Create example gallery with various PDF types

### Swift-Specific Future Considerations
- [ ] Consider pure Swift PDF parsing library to remove Core Graphics dependency
- [ ] Explore SwiftUI for potential GUI version
- [ ] Investigate Swift for TensorFlow for ML-based layout detection
- [ ] Plan gradual deprecation of ObjC version based on Swift performance
- [ ] Explore Swift on Server for cloud-based conversion service

## 🐛 Known Issues & Bugs
- [ ] Investigate memory spike with very large images
- [ ] Handle edge case: PDFs with no text content
- [ ] Fix Unicode normalization issues in some languages
- [ ] Improve handling of rotated text
- [ ] Better error messages for corrupted PDFs

## 📝 Notes
- Test command: `./pdf22md -i ./test/digitallegacies-twardoch2018.pdf -o ./test/output.md -a ./test/out`
- Always test with various PDF types before releasing
- Performance baseline: Current version processes ~100 pages/second on M1 Mac