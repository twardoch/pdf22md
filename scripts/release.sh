#!/bin/bash
# this_file: scripts/release.sh
# Release script for pdf22md

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Parse command line arguments
SKIP_TESTS=false
SKIP_BUILD=false
CREATE_ARCHIVE=false
PLATFORMS=("macos-x86_64" "macos-arm64")

while [[ $# -gt 0 ]]; do
    case $1 in
    --skip-tests)
        SKIP_TESTS=true
        shift
        ;;
    --skip-build)
        SKIP_BUILD=true
        shift
        ;;
    --archive)
        CREATE_ARCHIVE=true
        shift
        ;;
    --platforms)
        IFS=',' read -ra PLATFORMS <<< "$2"
        shift 2
        ;;
    -h | --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --skip-tests     Skip running tests"
        echo "  --skip-build     Skip building project"
        echo "  --archive        Create release archive"
        echo "  --platforms      Comma-separated list of platforms (default: macos-x86_64,macos-arm64)"
        echo "  -h, --help       Show this help message"
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Check if we're in the right directory
if [ ! -d "pdf22md" ]; then
    print_error "This script must be run from the pdf22md root directory"
    exit 1
fi

# Get version from git
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
print_status "Preparing release for version: $VERSION"

# Check if working directory is clean
if [[ "$VERSION" == *"dirty"* ]]; then
    print_warning "Working directory is dirty, consider committing changes first"
fi

# Run tests first
if [ "$SKIP_TESTS" = false ]; then
    print_status "Running tests before release"
    ./scripts/test.sh
    print_success "Tests passed"
fi

# Inject version information
print_status "Injecting version information"
./scripts/inject-version.sh

# Build for all platforms
if [ "$SKIP_BUILD" = false ]; then
    print_status "Building for all platforms"
    
    # Create release directory
    RELEASE_DIR="dist/release-$VERSION"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    # Build for each platform
    for platform in "${PLATFORMS[@]}"; do
        print_status "Building for $platform"
        
        cd pdf22md
        
        case $platform in
        "macos-x86_64")
            swift build -c release --arch x86_64
            cp .build/release/pdf22md "../$RELEASE_DIR/pdf22md-$VERSION-macos-x86_64"
            ;;
        "macos-arm64")
            swift build -c release --arch arm64
            cp .build/release/pdf22md "../$RELEASE_DIR/pdf22md-$VERSION-macos-arm64"
            ;;
        *)
            print_error "Unsupported platform: $platform"
            exit 1
            ;;
        esac
        
        cd ..
        print_success "Built for $platform"
    done
    
    # Create universal binary
    print_status "Creating universal binary"
    
    if [ -f "$RELEASE_DIR/pdf22md-$VERSION-macos-x86_64" ] && [ -f "$RELEASE_DIR/pdf22md-$VERSION-macos-arm64" ]; then
        lipo -create \
            "$RELEASE_DIR/pdf22md-$VERSION-macos-x86_64" \
            "$RELEASE_DIR/pdf22md-$VERSION-macos-arm64" \
            -output "$RELEASE_DIR/pdf22md-$VERSION-universal"
        
        print_success "Universal binary created"
    else
        print_warning "Could not create universal binary - missing architecture builds"
    fi
    
    # Copy additional files
    print_status "Adding release documentation"
    cp README.md "$RELEASE_DIR/"
    cp LICENSE "$RELEASE_DIR/"
    cp CHANGELOG.md "$RELEASE_DIR/" 2>/dev/null || true
    
    # Create install script
    cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash
# Installation script for pdf22md

set -e

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BINARY="pdf22md-*-macos-x86_64"
        ;;
    arm64)
        BINARY="pdf22md-*-macos-arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        echo "Trying universal binary..."
        BINARY="pdf22md-*-universal"
        ;;
esac

# Find the binary
BINARY_PATH=$(ls $BINARY 2>/dev/null | head -1)

if [ -z "$BINARY_PATH" ]; then
    echo "Error: No suitable binary found for architecture $ARCH"
    exit 1
fi

# Install to /usr/local/bin
echo "Installing $BINARY_PATH to /usr/local/bin/pdf22md"
sudo cp "$BINARY_PATH" /usr/local/bin/pdf22md
sudo chmod +x /usr/local/bin/pdf22md

echo "Installation complete!"
echo "You can now use pdf22md from anywhere: pdf22md --help"
EOF
    
    chmod +x "$RELEASE_DIR/install.sh"
    
    # Create checksums
    print_status "Generating checksums"
    cd "$RELEASE_DIR"
    
    for file in pdf22md-*; do
        if [ -f "$file" ] && [[ "$file" != *.sha256 ]]; then
            shasum -a 256 "$file" > "$file.sha256"
        fi
    done
    
    cd ../..
    
    print_success "Release binaries created in $RELEASE_DIR"
fi

# Create archive if requested
if [ "$CREATE_ARCHIVE" = true ]; then
    print_status "Creating release archive"
    
    ARCHIVE_NAME="pdf22md-$VERSION.tar.gz"
    cd dist
    tar -czf "$ARCHIVE_NAME" "release-$VERSION"
    cd ..
    
    print_success "Release archive created: dist/$ARCHIVE_NAME"
fi

# Create distribution packages
print_status "Creating distribution packages"
make dist

print_success "Release preparation complete!"

# Show release summary
echo
print_status "Release Summary:"
echo "  • Version: $VERSION"
echo "  • Platforms: ${PLATFORMS[*]}"
echo "  • Release directory: $RELEASE_DIR"

if [ "$CREATE_ARCHIVE" = true ]; then
    echo "  • Archive: dist/pdf22md-$VERSION.tar.gz"
fi

echo "  • DMG package: dist/pdf22md-$VERSION.dmg"
echo "  • PKG installer: dist/pdf22md-$VERSION.pkg"

echo
print_status "Next steps:"
echo "  1. Test the release binaries"
echo "  2. Create a git tag: git tag v$VERSION"
echo "  3. Push the tag: git push origin v$VERSION"
echo "  4. Create GitHub release with the generated files"