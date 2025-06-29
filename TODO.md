# pdf22md TODO List

## Immediate Priority (v1.6.0) - Code Consolidation & Core Fixes

### Architecture Consolidation
- [ ] Benchmark all three converter implementations (async/await, GCD, ultra-optimized)
- [ ] Create performance comparison report with different PDF types
- [ ] Consolidate to single optimized implementation
- [ ] Remove redundant converter classes
- [ ] Update CLI to remove --optimized and --ultra-optimized flags

### Existing Issues from Previous TODO
- [ ] Update `AssetExtractor.saveImage` to return path prefixed with assets directory
- [ ] Fix Markdown image paths to include correct assets folder prefix
- [ ] Add unit test validating image references in Markdown
- [ ] Add error handling for corrupted image streams
- [ ] Handle PDFs with no Resources dictionary gracefully

### Error Handling Enhancement
- [ ] Create comprehensive PDFConversionError enum with specific cases
- [ ] Add user-friendly error messages with recovery suggestions
- [ ] Implement proper error propagation in all components
- [ ] Add error logging with levels (debug, info, warning, error)

## Short Term (v1.7.0) - Testing & Reliability

### Test Infrastructure
- [ ] Set up XCTest framework properly
- [ ] Create unit tests for FontStatistics (heading detection)
- [ ] Create unit tests for AssetExtractor (image saving)
- [ ] Create unit tests for PDFPageProcessor (content extraction)
- [ ] Add integration tests with sample PDFs
- [ ] Implement CI test automation in GitHub Actions
- [ ] Add code coverage reporting (target: 80%+)

### Test Corpus
- [ ] Collect diverse PDF samples (text-only, image-heavy, vector graphics)
- [ ] Add encrypted PDF test cases
- [ ] Add corrupted PDF test cases
- [ ] Create expected output fixtures for regression testing

### Performance Testing
- [ ] Create benchmark suite for performance testing
- [ ] Add memory usage profiling
- [ ] Set up automated performance regression detection

## Medium Term (v1.8.0) - User Experience

### Progress Indicators
- [ ] Add ProgressReporter protocol
- [ ] Implement console progress bar for page processing
- [ ] Add estimated time remaining calculation
- [ ] Add verbose mode (-v/--verbose) with detailed logs
- [ ] Add quiet mode (-q/--quiet) for scripting

### Configuration System
- [ ] Design configuration file schema (YAML/JSON)
- [ ] Add configuration file loading (~/.pdf22mdrc)
- [ ] Implement command-line override system
- [ ] Add environment variable support (PDF22MD_*)
- [ ] Create configuration presets (fast, quality, minimal)

### CLI Enhancements
- [ ] Add batch processing mode for multiple PDFs
- [ ] Implement watch mode for automatic conversion
- [ ] Improve help text with examples
- [ ] Add version command with build info
- [ ] Add dry-run mode to preview operations

## Long Term (v2.0.0) - Professional Deployment

### Homebrew Distribution
- [ ] Create homebrew-tap repository
- [ ] Write Formula with dependencies
- [ ] Set up Formula auto-update on release
- [ ] Test installation on clean systems
- [ ] Document tap installation process

### macOS Distribution
- [ ] Obtain Apple Developer ID for code signing
- [ ] Implement code signing in build process
- [ ] Add notarization step for Gatekeeper
- [ ] Create universal binary (x86_64 + arm64)
- [ ] Design DMG background image
- [ ] Automate DMG creation with create-dmg

### Release Automation
- [ ] Enhance GitHub Actions for signed releases
- [ ] Add changelog generation from commits
- [ ] Implement semantic version bumping
- [ ] Create release notes template
- [ ] Add update checker in CLI

## Future Enhancements (v2.1.0+)

### Performance Optimizations
- [ ] Implement streaming markdown generation
- [ ] Add page-level caching for large PDFs
- [ ] Optimize memory usage with autorelease pools
- [ ] Add parallel asset extraction
- [ ] Implement image deduplication

### Advanced Features
- [ ] Add table detection and conversion
- [ ] Support for PDF forms extraction
- [ ] Implement OCR integration for scanned PDFs
- [ ] Add mathematical formula detection
- [ ] Support multiple markdown flavors (CommonMark, GFM)

### Vector Graphics Improvements
- [ ] Replace grid-based approach with content stream parsing
- [ ] Implement intelligent bounding box detection
- [ ] Add SVG export option for vector graphics
- [ ] Optimize rendering with caching

### API & Extensibility
- [ ] Create Swift Package library target
- [ ] Design plugin architecture
- [ ] Add programmatic API documentation
- [ ] Create example integrations
- [ ] Support custom heading detection algorithms

## Maintenance Tasks

### Documentation
- [ ] Update man page with new features
- [ ] Create comprehensive user guide
- [ ] Add troubleshooting section
- [ ] Document configuration options
- [ ] Create video tutorials

### Code Quality
- [ ] Run SwiftLint and fix all warnings
- [ ] Add SwiftFormat for consistent style
- [ ] Update code comments and documentation
- [ ] Remove deprecated code
- [ ] Optimize import statements

### Community
- [ ] Set up GitHub Discussions
- [ ] Create contribution guidelines
- [ ] Add issue templates
- [ ] Set up project board
- [ ] Create security policy

## Version Planning

### v1.6.0 - Consolidation Release
- Code consolidation
- Bug fixes
- Basic error handling

### v1.7.0 - Quality Release  
- Comprehensive testing
- Performance benchmarks
- Reliability improvements

### v1.8.0 - UX Release
- Progress indicators
- Configuration system
- CLI enhancements

### v2.0.0 - Professional Release
- Homebrew distribution
- Code signing
- Universal binary

### v2.1.0+ - Feature Releases
- Advanced features
- API development
- Community features