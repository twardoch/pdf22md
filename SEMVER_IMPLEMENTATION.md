# Semver Implementation for pdf22md

This document describes the comprehensive semversioning, testing, and CI/CD implementation for pdf22md.

## Overview

The implementation includes:

1. **Git-tag-based semversioning** with automatic version injection
2. **Comprehensive test suite** covering all major functionality
3. **Local build and release scripts** for development workflow
4. **GitHub Actions CI/CD pipeline** for automated testing and releases
5. **Multiplatform binary builds** (x86_64, arm64, universal)
6. **Automated release creation** with proper artifacts

## Files Added/Modified

### Version Management
- `pdf22md/Sources/PDF22MD/Version.swift` - New version information structure
- `pdf22md/Sources/PDF22MD/Version.swift.template` - Template for version injection
- `scripts/inject-version.sh` - Script to inject version information at build time
- `pdf22md/Sources/PDF22MDCli/main.swift` - Updated to use dynamic version

### Testing
- `pdf22md/Tests/PDF22MDTests/PDF22MDTests.swift` - Comprehensive test suite
- `pdf22md/Package.swift` - Updated to include test resources
- `scripts/test.sh` - Local test execution script

### Build and Release
- `scripts/release.sh` - Local release preparation script
- `Makefile` - Updated to use version injection
- `build.sh` - Updated to use version injection

### CI/CD
- `.github/workflows/ci.yml` - Continuous integration workflow
- `.github/workflows/release.yml` - Release workflow for git tags

## Version Management Strategy

### Git Tags
- Uses semantic versioning: `v1.0.0`, `v1.2.3`, etc.
- Version is automatically extracted from git tags
- Supports dirty state detection (`v1.0.0-dirty`)

### Version Injection
The `scripts/inject-version.sh` script:
1. Extracts version from `git describe --tags`
2. Gets current commit hash
3. Generates build timestamp
4. Injects these values into `Version.swift`

### Version Display
The application shows version information via:
- `--version` command line flag
- `Version.current` - semver string
- `Version.fullVersion` - includes short commit hash
- `Version.commit` - full commit hash
- `Version.buildDate` - ISO timestamp

## Test Suite

### Test Coverage
- **Version Tests** - Verify version information is properly injected
- **Font Statistics Tests** - Test heading level detection
- **PDF Element Tests** - Test text and image element handling
- **Asset Extractor Tests** - Test image extraction and format selection
- **PDF Processing Tests** - Test page processing with real PDFs
- **Integration Tests** - Full conversion pipeline testing
- **Performance Tests** - Benchmark conversion speed
- **Error Handling Tests** - Test invalid input handling
- **Edge Case Tests** - Test empty PDFs, custom DPI, etc.

### Test Resources
- Test PDFs located in `pdf22md/Tests/PDF22MDTests/test-resources/`
- Expected outputs for comparison
- Benchmark data for performance testing

### Local Testing
```bash
# Run all tests
scripts/test.sh

# Run with verbose output
scripts/test.sh --verbose

# Run debug build tests
scripts/test.sh --debug

# Generate coverage report
scripts/test.sh --coverage
```

## Build System

### Local Development
```bash
# Build release version
make build

# Build debug version
make debug

# Run tests
make test

# Create distribution packages
make dist

# Clean build artifacts
make clean
```

### Release Process
```bash
# Prepare release (runs tests, builds all platforms)
scripts/release.sh

# Create archive
scripts/release.sh --archive

# Skip tests (for faster iteration)
scripts/release.sh --skip-tests
```

## CI/CD Pipeline

### Continuous Integration (.github/workflows/ci.yml)
Runs on push to main/develop and pull requests:
1. **Test** - Run comprehensive test suite
2. **Lint** - SwiftLint code quality checks
3. **Build** - Build for x86_64 and arm64
4. **Security** - Basic security scanning
5. **Package** - Create distribution packages (main branch only)

### Release Pipeline (.github/workflows/release.yml)
Runs on git tag push (v*):
1. **Test** - Run tests before release
2. **Build** - Build release binaries for both architectures
3. **Package** - Create universal binary and distribution packages
4. **Release** - Create GitHub release with all artifacts

### Artifacts Created
- **Binaries**: `pdf22md-v1.0.0-macos-x86_64`, `pdf22md-v1.0.0-macos-arm64`, `pdf22md-v1.0.0-universal`
- **Packages**: `pdf22md-v1.0.0.dmg`, `pdf22md-v1.0.0.pkg`
- **Archive**: `pdf22md-v1.0.0.tar.gz`
- **Checksums**: SHA256 for all binaries
- **Install Script**: `install.sh` for manual installation

## Multiplatform Support

### Architectures
- **x86_64** - Intel Macs
- **arm64** - Apple Silicon Macs
- **universal** - Both architectures in one binary

### Build Process
The release process creates separate binaries for each architecture, then combines them into a universal binary using `lipo`.

### Distribution
- **DMG** - Disk image with installer package
- **PKG** - macOS installer package
- **TAR.GZ** - Archive with all binaries and documentation

## Usage

### Creating a Release
1. Update `CHANGELOG.md` with release notes
2. Commit changes
3. Create and push git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. GitHub Actions will automatically:
   - Run tests
   - Build multiplatform binaries
   - Create release packages
   - Publish GitHub release

### Installation Options
1. **Homebrew** (recommended): `brew install twardoch/tap/pdf22md`
2. **GitHub Releases**: Download binary and run `install.sh`
3. **Manual**: Copy binary to `/usr/local/bin/pdf22md`

## Security Considerations

- All binaries include SHA256 checksums
- GitHub Actions use pinned action versions
- No secrets are embedded in binaries
- Code is scanned for sensitive information

## Performance Optimization

- Builds use release optimization (`-c release`)
- Universal binaries optimize for both architectures
- Caching of Swift dependencies in CI
- Parallel builds for different architectures

## Future Enhancements

- Add support for more platforms (Linux, Windows via cross-compilation)
- Implement automatic changelog generation
- Add code signing for macOS binaries
- Implement notarization for macOS distribution
- Add performance benchmarking in CI

## Troubleshooting

### Common Issues
1. **Swift not found**: Ensure Xcode Command Line Tools are installed
2. **Permission denied**: Run with `sudo` for installation
3. **Version not updating**: Ensure `scripts/inject-version.sh` is executable

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

This implementation provides a production-ready semversioning and release system that automatically handles versioning, testing, building, and distribution of pdf22md across multiple platforms.