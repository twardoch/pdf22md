# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Complete Modern Objective-C Implementation**: Full feature-parity rewrite in modern Objective-C with nullability annotations, lightweight generics, and proper designated initializers
- **Complete Swift Implementation**: Modern Swift implementation with async/await, actors, and Swift Package Manager support
- **Multi-Implementation Architecture**: Three implementations (C/ObjC, Modern ObjC, Swift) for different use cases and platform requirements
- **Advanced Error Handling**: Custom error domains and comprehensive error reporting across all implementations
- **Thread-Safe Asset Management**: Concurrent image processing with proper synchronization
- **Modern Build Infrastructure**: Support for both Makefile and Xcode/SPM build systems
- Semantic versioning support based on git tags
- Version display option (-v, -V) in the command-line tool
- Release automation script (release.sh) for macOS
- GitHub Actions workflow for automated releases
- Package installer (.pkg) generation for macOS
- Universal binary support (Intel and Apple Silicon)
- Man page generation in release packages
- MIT License file for open-source compliance
- GitHub issue templates for bug reports and feature requests
- Comprehensive .gitignore file with proper exclusions
- Build directory structure to separate source from build artifacts
- CHANGELOG.md to track version history
- Professional project documentation standards

### Changed
- **Architectural Modernization**: Complete rewrite of core components using modern Objective-C and Swift patterns
- **Enhanced Font Analysis**: Improved heading detection algorithm with configurable thresholds
- **Robust Asset Processing**: Smart image format selection with transparency detection and quality optimization
- **Memory Management**: Enhanced memory efficiency with proper autorelease pool usage and actor-based resource management (Swift)
- Makefile now supports VERSION variable for build-time versioning
- Makefile now uses a dedicated `build/` directory for object files
- .gitignore updated to properly exclude build artifacts and editor files
- GitHub Actions workflow fixed to use correct binary name
- Project structure reorganized following professional standards

### Fixed
- **Critical Build Issues**: Resolved all compilation errors in modern Objective-C implementation including:
  - Fixed designated initializer chain issues
  - Resolved private instance variable access violations  
  - Fixed NSValue CGRect compatibility issues using NSData approach
  - Corrected deprecated UTType constant usage
  - Fixed method signature mismatches and unused variable warnings
- **Memory Safety**: All CGImageRef memory leaks resolved with proper resource management
- **Concurrency Issues**: Thread-safe operations with proper GCD usage and Swift actor patterns
- Build artifacts (.o files) no longer pollute the repository root
- GitHub Actions workflow now correctly references the pdf22md binary
- Make variable in .gitignore replaced with actual filename
- Removed all DEBUG logging statements from production code
- Fixed CLI deadlock caused by main-queue dispatch in `PDFMarkdownConverter`; completions now called directly
- Fixed hanging issue on certain malformed PDFs by replacing low-level CGPDFScanner-based extraction with PDFKit high-level API (see `PDFPageProcessor`)
- Removed unused CGPDFScanner operator callback functions and PDFScannerState struct that were part of the deprecated implementation
- Fixed segmentation fault during asset extraction (Phase 1a): removed premature CGImageRelease calls in `PDFPageProcessor` that deallocated images still in use

### Removed
- Object files from repository root (moved to build directory)

## [1.0.0] - 2024-01-01

### Added
- Initial release of pdf22md
- PDF to Markdown conversion with parallel processing
- Intelligent heading detection based on font size analysis
- Asset extraction with smart image format selection (JPEG/PNG)
- Support for both file and stdin/stdout I/O
- Customizable DPI for vector graphics rasterization
- Grand Central Dispatch (GCD) for multi-core performance
- Comprehensive documentation