# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete Swift implementation alongside existing Objective-C version
- Swift Package Manager integration with executable target
- Comprehensive performance benchmarking suite comparing both implementations
- Python benchmark script with detailed performance metrics and memory usage tracking
- Test PDF generation script for creating consistent benchmark datasets
- Swift implementation features:
  - Async/await support for concurrent page processing
  - Native Swift concurrency with TaskGroup
  - Type-safe PDF element protocol hierarchy
  - Modern Swift error handling
- Benchmark results showing performance characteristics of both implementations
- `build.sh` script for building both implementations with options:
  - `--objc-only` / `--swift-only` for selective builds
  - `--clean` for clean builds
  - `--install` for installing to /usr/local/bin
  - `--version` for setting build version
- `bench.sh` script for running performance benchmarks:
  - `--quick` for rapid 3-iteration benchmarks
  - `--iterations N` for custom iteration counts
  - `--memory` for detailed memory profiling
  - `--python` to use Python benchmark suite

### Changed
- Makefile updated to support building both implementations with `all-implementations` target
- Added `swift-build`, `swift-clean`, and `swift-test` targets to Makefile
- Enhanced benchmark scripts to measure:
  - Processing time per PDF size
  - Memory usage patterns
  - Concurrent processing efficiency
  - Output quality comparison

### Performance
- Benchmark results (as of initial Swift port):
  - Objective-C implementation is 2.7x-34x faster depending on PDF size
  - Swift implementation uses 3.7x-5.6x more memory
  - Both implementations produce identical output content
  - Performance gap increases with larger PDFs
- Added Swift optimization attempts:
  - GCD-based implementation (3% improvement over async/await)
  - Ultra-optimized version using NSString and pre-allocation
  - Compiler optimization flags (-O, -whole-module-optimization)
  - Memory pooling and ContiguousArray usage
- Created comprehensive benchmark suite (`benchmark-all.py`) testing all versions

### Documentation
- Added Swift implementation architecture details
- Documented benchmark methodology and results
- Updated build instructions for both implementations
- Added build and benchmark script documentation

## [1.2.0] - Previous Release

### Added
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
- Makefile now supports VERSION variable for build-time versioning
- Makefile now uses a dedicated `build/` directory for object files
- .gitignore updated to properly exclude build artifacts and editor files
- GitHub Actions workflow fixed to use correct binary name
- Project structure reorganized following professional standards

### Fixed
- Build artifacts (.o files) no longer pollute the repository root
- GitHub Actions workflow now correctly references the pdf22md binary
- Make variable in .gitignore replaced with actual filename
- Removed all DEBUG logging statements from production code.
- Fixed CLI deadlock caused by main-queue dispatch in `PDFMarkdownConverter`; completions now called directly.
- Fixed hanging issue on certain malformed PDFs by replacing low-level CGPDFScanner-based extraction with PDFKit high-level API (see `PDFPageProcessor`).
- Removed unused CGPDFScanner operator callback functions and PDFScannerState struct that were part of the deprecated implementation.
- Fixed segmentation fault during asset extraction (Phase 1a): removed premature CGImageRelease calls in `PDFPageProcessor` that deallocated images still in use.

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