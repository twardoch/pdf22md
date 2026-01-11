# Semver Implementation for pdf22md

This document describes the semversioning, testing, and CI/CD implementation for pdf22md.

## Overview

The implementation includes:

1. Git-tag-based semversioning with automatic version injection
2. Comprehensive test suite covering all major functionality
3. Local build and release scripts for development workflow
4. GitHub Actions CI/CD pipeline for automated testing and releases
5. Multiplatform binary builds (x86_64, arm64, universal)
6. Automated release creation with proper artifacts

## Files Added/Modified

### Version Management
- `pdf22md/Sources/PDF22MD/Version.swift` - Version information structure
- `pdf22md/Sources/PDF22MD/Version.swift.template` - Template for version injection
- `scripts/inject-version.sh` - Injects version information at build time
- `pdf22md/Sources/PDF22MDCli/main.swift` - Uses dynamic version

### Testing
- `pdf22md/Tests/PDF22MDTests/PDF22MDTests.swift` - Test suite
- `pdf22md/Package.swift` - Includes test resources
- `scripts/test.sh` - Local test execution

### Build and Release
- `scripts/release.sh` - Release preparation
- `Makefile` - Uses version injection
- `build.sh` - Uses version injection

### CI/CD
- `.github/workflows/ci.yml` - Continuous integration
- `.github/workflows/release.yml` - Release workflow for git tags

## Version Management Strategy

### Git Tags
- Semantic versioning: `v1.0.0`, `v1.2.3`
- Version extracted from git tags automatically
- Dirty state detection: `v1.0.0-dirty`

### Version Injection
The `scripts/inject-version.sh` script:
1. Extracts version from `git describe --tags`
2. Gets current commit hash
3. Generates build timestamp
4. Injects values into `Version.swift`

### Version Display
Application shows version via:
- `--version` flag
- `Version.current` - semver string
- `Version.fullVersion` - includes short commit hash
- `Version.commit` - full commit hash
- `Version.buildDate` - ISO timestamp

## Test Suite

### Test Coverage
- Version Tests - Verify version injection
- Font Statistics Tests - Heading level detection
- PDF Element Tests - Text and image handling
- Asset Extractor Tests - Image extraction and format selection
- PDF Processing Tests - Page processing with real PDFs
- Integration Tests - Full conversion pipeline
- Performance Tests - Conversion speed benchmarks
- Error Handling Tests - Invalid input handling
- Edge Case Tests - Empty PDFs, custom DPI, etc.

### Test Resources
- Test PDFs in `pdf22md/Tests/PDF22MDTests/test-resources/`
- Expected outputs for comparison
- Benchmark data

### Local Testing
```bash
# Run all tests
scripts/test.sh

# Verbose output
scripts/test.sh --verbose

# Debug build
scripts/test.sh --debug

# Coverage report
scripts/test.sh --coverage
```

## Build System

### Local Development
```bash
# Build release
make build

# Build debug
make debug

# Run tests
make test

# Create packages
make dist

# Clean artifacts
make clean
```

### Release Process
```bash
# Prepare release (tests + builds)
scripts/release.sh

# Create archive
scripts/release.sh --archive

# Skip tests
scripts/release.sh --skip-tests
```

## CI/CD Pipeline

### Continuous Integration (.github/workflows/ci.yml)
Runs on push to main/develop and pull requests:
1. Test - Run test suite
2. Lint - SwiftLint checks
3. Build - x86_64 and arm64 builds
4. Security - Basic scanning
5. Package - Distribution packages (main branch only)

### Release Pipeline (.github/workflows/release.yml)
Runs on git tag push (v*):
1. Test - Pre-release tests
2. Build - Release binaries for both architectures
3. Package - Universal binary and distribution packages
4. Release - GitHub release with artifacts

### Artifacts
- Binaries: `pdf22md-v1.0.0-macos-x86_64`, `pdf22md-v1.0.0-macos-arm64`, `pdf22md-v1.0.0-universal`
- Packages: `pdf22md-v1.0.0.dmg`, `pdf22md-v1.0.0.pkg`
- Archive: `pdf22md-v1.0.0.tar.gz`
- Checksums: SHA256 for all binaries
- Install Script: `install.sh`

## Multiplatform Support

### Architectures
- x86_64 - Intel Macs
- arm64 - Apple Silicon Macs
- universal - Combined binary

### Build Process
Release process creates separate binaries, then combines them with `lipo`.

### Distribution
- DMG - Disk image with installer
- PKG - macOS installer
- TAR.GZ - Archive with binaries and docs

## Usage

### Creating a Release
1. Update `CHANGELOG.md`
2. Commit changes
3. Create and push git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. GitHub Actions will:
   - Run tests
   - Build binaries
   - Create packages
   - Publish release

### Installation
1. Homebrew: `brew install twardoch/tap/pdf22md`
2. GitHub Releases: Download and run `install.sh`
3. Manual: Copy binary to `/usr/local/bin/pdf22md`

## Security

- SHA256 checksums included
- Pinned GitHub Actions versions
- No embedded secrets
- Code scanning for sensitive data

## Performance

- Release optimization (`-c release`)
- Universal binary architecture optimization
- Swift dependency caching in CI
- Parallel architecture builds

## Future Enhancements

- Linux and Windows support via cross-compilation
- Automatic changelog generation
- macOS code signing
- macOS notarization
- CI performance benchmarking

## Troubleshooting

### Common Issues
1. Swift not found - Install Xcode Command Line Tools
2. Permission denied - Use `sudo` for installation
3. Version not updating - Check `scripts/inject-version.sh` permissions

### Debug Commands
```bash
# Check version injection
scripts/inject-version.sh

# Verify build
make build

# Test specific functionality
scripts/test.sh --verbose

# Check artifacts
ls -la dist/
```

This system handles versioning, testing, building, and distribution of pdf22md across multiple platforms automatically.