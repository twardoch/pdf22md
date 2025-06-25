# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Major Project Restructuring**: Consolidated build system and moved shared components to implementation-specific directories
- Moved shared core components (FileSystemUtils, Constants, ErrorFactory, ConcurrencyManager, ImageFormatDetection) to pdf22md-objc/shared-core/
- Updated imports in source files to reference new shared-core location
- Created implementation-specific build systems:
  - pdf22md-objc/Makefile for Objective-C implementation
  - pdf22md-swift continues using Swift Package Manager
- Simplified root README.md to focus on high-level project overview
- Created comprehensive README.md files for each implementation with detailed documentation

### Removed
- Root-level Makefile and build.sh scripts (functionality moved to pdf22md-objc/)
- Duplicate test resources that were mistakenly re-added to pdf22md-swift/
- Redundant documentation from implementation directories

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

### Changed
- Restructured project with separate directories for each implementation (pdf22md-objc, pdf22md-swift)
- Moved test files and resources to implementation-specific directories
- Updated object file compilation commands in build scripts

### Improved
- Build scripts now provide clearer guidance when Swift toolchain is corrupted
- Swift build failures are handled more gracefully with specific remediation steps
- Build process for pdf22md-objc to resolve duplicate symbol errors
- Error reporting now includes process IDs for easier debugging
- Conversion feedback with detailed status messages during operations

### Fixed
- Duplicate symbol errors in pdf22md-objc build process
- Build script compatibility issues with object file handling
- PDF processing hang issue with timeout implementation
- Memory leaks in asset management

### Removed
- Legacy archived-old-implementation directory (2,000+ lines of obsolete code)
- Duplicate build scripts (pdf22md-objc/build.sh, release.sh, run-tests.sh)
- Duplicate README files and documentation
- Duplicate PARALLEL_PROCESSING.md files across implementations
- Resolved issue files (102, 201) after fixing Swift toolchain problems
- Obsolete pdf22md-benchmark binary file from version control
- **210+ duplicate test images** across 3 implementations (58MB saved)
- **Duplicate PDF test files** across implementations
- **Duplicate man pages** from implementation directories
- **Duplicate Swift build scripts** (pdf22md-swift/build.sh, release.sh)

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