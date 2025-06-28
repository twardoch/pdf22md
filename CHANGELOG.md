# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Proper XObject Image Extraction**: Implemented extraction of embedded images from PDF XObject streams
- **Conditional Asset Processing**: Only process images when `-a`/`--assets` flag is provided
- **Improved Asset Naming**: Assets now named as `basename-pagenumber-assetnumber.ext` with proper padding

### Changed
- **IMPLEMENTATION RENAMING**: 
  - Renamed Objective-C implementation from `pdf22md-objc` to `pdf21md` (directory and binary)
  - Renamed Swift implementation binary from `pdf22md` to `pdf22md`
  - Updated all class prefixes from `PDF22MD` to `PDF21MD` in Objective-C implementation
  - Updated all build scripts and documentation to reflect new naming
- **MAJOR CODEBASE RESTRUCTURING**: Complete reorganization into two self-contained implementations
- **Dual Implementation Architecture**: 
  - `pdf21md/`: Production-ready Objective-C implementation with full functionality
  - `pdf22md/`: Modern Swift library foundation with Swift Package Manager
- **Shared Component Integration**: Moved shared components to implementation-specific directories:
  - `pdf21md/shared-core/`: FileSystemUtils, Constants, ErrorFactory, ConcurrencyManager
  - `pdf21md/shared-algorithms/`: ImageFormatDetection
- **Build System Consolidation**: 
  - Created self-contained Makefile for Objective-C implementation
  - Simplified Swift Package Manager manifest for Swift implementation
  - Removed redundant root-level build scripts
- **Import Path Updates**: Fixed all import statements to reference new shared component locations
- **Documentation Overhaul**: 
  - Updated main README.md to showcase dual implementation approach
  - Created comprehensive README.md for each implementation
  - Updated project structure to reflect new organization

### Added
- **Self-Contained Implementations**: Both implementations now include their own:
  - Build systems (Makefile for ObjC, Package.swift for Swift)
  - Test resources and test suites
  - Documentation and usage examples
  - Shared components integrated locally
- **Production-Ready Objective-C**: Fully functional `pdf21md` executable with:
  - Complete PDF-to-Markdown conversion
  - Parallel processing with GCD
  - Smart image extraction and format detection
  - Command-line interface with proper argument parsing
- **Modern Swift Foundation**: Swift Package Manager library with:
  - Proper module structure for programmatic usage
  - Test framework foundation
  - Modern Swift patterns ready for implementation

### Removed
- **Eliminated Directory Redundancy**: 
  - Removed obsolete `swift/`, `shared/`, `build/`, `test/` directories
  - Consolidated all functionality into two main implementation folders
- **Cleaned Up Build Artifacts**:
  - Removed root-level Makefile, build.sh, pdf22md executable
  - Eliminated duplicate test resources and documentation
- **Streamlined Structure**: Removed intermediate directories and scattered files

### Fixed
- **Build System Issues**: 
  - Resolved module cache issues in Swift build.
  - Resolved duplicate main symbol errors in Objective-C build
  - Fixed import path references for shared components
  - Corrected Swift Package Manager manifest syntax errors
- **File System Organization**: 
  - Fixed relative path issues in shared component imports
  - Resolved compilation errors from directory restructuring
  - Ensured both implementations build and test successfully

### Added
- **PDF22MDFileSystemUtils**: Unified file system operations consolidating scattered NSFileManager patterns
- **PDF22MDConstants**: Centralized configuration constants eliminating magic numbers across 15+ files
- Enhanced error handling with new file system error codes (InvalidPath, DirectoryNotFound, PermissionDenied)
- Comprehensive codebase analysis using repomix (72,530 tokens, 52 files) for streamlining optimization
- Detailed PLAN.md for systematic code streamlining approach
- Updated TODO.md with final 3% streamlining tasks to reach 100% excellence
- Comprehensive streamlining plan (PLAN.md) for codebase optimization
- Unified build system using single Makefile and build.sh script
- Shared component library (shared/ directory) for common algorithms
- PDF22MDImageFormatDetection utility for optimal image format selection
- Unified test resource directory (shared/test-resources/) for all implementations
- **PDF22MDErrorFactory**: Unified error creation factory eliminating error handling duplication across 9+ files with specialized methods for configuration, file system, and processing errors
- **PDF22MDConcurrencyManager**: Standardized GCD patterns and queue management for consistent concurrency across implementations with shared queues and parallel processing utilities
- **Complete Modern Objective-C Implementation**: Full feature-parity rewrite in modern Objective-C with nullability annotations, lightweight generics, and proper designated initializers
- **Complete Swift Implementation**: Modern Swift implementation with async/await, actors, and Swift Package Manager support
- **Multi-Implementation Architecture**: Three implementations (C/ObjC, Modern ObjC, Swift) for different use cases and platform requirements
- **Advanced Error Handling**: Custom error domains and comprehensive error reporting across all implementations
- **Thread-Safe Asset Management**: Concurrent image processing with proper synchronization
- **Modern Build Infrastructure**: Support for both Makefile and Xcode/SPM build systems
- TROUBLESHOOTING.md documentation for common build and runtime issues
- Enhanced Swift toolchain detection in build scripts
- Better error messages for SWBBuildService.framework missing issue
- pdf22md-benchmark utility for performance testing
- Builder pattern for PDF22MDConversionOptions configuration
- Verbose logging options for PDF loading and conversion processes
- Timeout handling for conversion process to prevent hangs
- Comprehensive test data with sample PDFs and expected output
- Semantic versioning support based on git tags
- Version display option (-v, -V) in the command-line tool
- Release automation script (release.sh) for macOS
- GitHub Actions workflow for automated releases
- Package installer (.pkg) generation for macOS
- **Plan**: Detailed roadmap for robust raster-image extraction across Swift and Objective-C implementations appended to PLAN.md.
- **TODO**: Simplified checklist for the above work inserted into TODO.md.

### Changed
- Restructured project with separate directories for each implementation (pdf21md, pdf22md)
- Moved test files and resources to implementation-specific directories
- Updated object file compilation commands in build scripts

### Improved
- Build scripts now provide clearer guidance when Swift toolchain is corrupted
- Swift build failures are handled more gracefully with specific remediation steps
- Build process for pdf21md to resolve duplicate symbol errors
- Error reporting now includes process IDs for easier debugging
- Conversion feedback with detailed status messages during operations

### Fixed
- Duplicate symbol errors in pdf21md build process
- Build script compatibility issues with object file handling
- PDF processing hang issue with timeout implementation
- Memory leaks in asset management
- **Swift Markdown Output**: Ensured the Swift converter now creates parent directories before writing and reliably writes the generated Markdown file instead of silently failing when the directory is missing.
- **Code Quality**: Removed unused `fontName` variable in `PDFPageProcessorOptimized` to silence compiler warnings.

### Removed
- Legacy archived-old-implementation directory (2,000+ lines of obsolete code)
- Duplicate build scripts (pdf21md/build.sh, release.sh, run-tests.sh)
- Duplicate README files and documentation
- Duplicate PARALLEL_PROCESSING.md files across implementations
- Resolved issue files (102, 201) after fixing Swift toolchain problems
- Obsolete pdf22md-benchmark binary file from version control
- **210+ duplicate test images** across 3 implementations (58MB saved)
- **Duplicate PDF test files** across implementations
- **Duplicate man pages** from implementation directories
- **Duplicate Swift build scripts** (pdf22md/build.sh, release.sh)

### Streamlined
- **File system operations**: Consolidated NSFileManager patterns from 4+ files into PDF22MDFileSystemUtils (~150 lines eliminated)
- **Configuration constants**: Centralized all magic numbers (144.0 DPI, 2.0 threshold, etc.) from 15+ files into PDF22MDConstants
- **Asset management**: Updated PDF22MDAssetManager to use shared file utilities and constants
- **Validation logic**: Unified path validation and directory operations across implementations
- Consolidated build system into single authoritative Makefile and build.sh
- Unified documentation in single root README.md
- Removed code duplication between root and implementation directories
- Extracted image format detection algorithm into shared utility (~100 lines deduplicated)
- Build system automatically compiles shared components with proper dependencies
- **Error handling patterns**: Replaced manual NSError creation with standardized factory methods across all validation and processing code (40-60% reduction in error handling boilerplate)
- **Concurrency patterns**: Unified GCD usage with shared queue management and standardized parallel processing patterns (eliminated duplicate queue creation across 4+ files)
- **Shared component architecture**: Established professional foundation with Core/ directory containing ErrorFactory, ConcurrencyManager, FileSystemUtils, and Constants
- **Test resource consolidation**: Single shared/test-resources/ directory (58MB space saved)
- **Documentation consolidation**: Single man page source (docs/pdf22md.1)
- **Build script unification**: No implementation-specific build scripts
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
- **Build Script Compatibility**: Fixed bash incompatibility in build.sh by replacing `declare -A` associative arrays with simple variables for broader shell compatibility
- **Swift Build Resilience**: Enhanced build.sh with Swift toolchain health checks and graceful fallback handling when Swift toolchain is corrupted
- **Comprehensive Testing Infrastructure**: Implemented complete test framework with unit tests, integration tests, and working test runner for MVP 1.0 readiness
  - Created PDF22MDConverterTests.m for core conversion logic validation
  - Created PDF22MDAssetManagerTests.m for image extraction and management testing
  - Created PDF22MDFontAnalyzerTests.m for heading detection algorithm validation
  - Created EndToEndConversionTests.m for complete pipeline testing
  - Created SimpleConverterTest.m working test executable proving framework functionality
- **Enhanced Error Handling System**: Expanded error definitions with user-friendly messages and actionable suggestions
  - Added 8 specific error codes including encrypted PDF, memory pressure, and processing timeout
  - Implemented PDF22MDErrorHelper with comprehensive user-friendly error messages
  - Added actionable recovery suggestions for all error conditions (e.g., "Try opening in another PDF viewer to verify it's not corrupted")
  - Fixed API compatibility issues in error method naming

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

### Changed
- **Swift Raster Extraction (Phase 1)**: Added `CGPDFImageExtractor` and integrated it into both page processors; now ignores tiny annotation icons and discards blank/white images to prevent false assets.