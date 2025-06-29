#!/bin/bash
# Build script for pdf22md (Swift version)

set -e # Exit on any error

npx repomix -i "docs" -o llms.txt .

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Check if we're in the right directory
if [ ! -d "pdf22md" ]; then
    print_error "This script must be run from the pdf22md root directory"
    exit 1
fi

# Parse command line arguments
CLEAN=false
INSTALL=false
BUILD_TYPE="release"

while [[ $# -gt 0 ]]; do
    case $1 in
    --clean)
        CLEAN=true
        shift
        ;;
    --install)
        INSTALL=true
        shift
        ;;
    --debug)
        BUILD_TYPE="debug"
        shift
        ;;
    -h | --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --clean          Clean build artifacts before building"
        echo "  --install        Install binaries to /usr/local/bin after building"
        echo "  --debug          Build in debug mode"
        echo "  -h, --help       Show this help message"
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_status "Cleaning build artifacts"
    cd pdf22md
    swift package clean >/dev/null 2>&1 || true
    rm -rf .build >/dev/null 2>&1 || true
    cd ..
    print_success "Cleaned Swift build artifacts"
fi

# Build Swift version
print_status "Building Swift version"
cd pdf22md

if [ "$BUILD_TYPE" = "debug" ]; then
    swift build
else
    swift build -c release
fi

if [ $? -eq 0 ]; then
    print_success "Swift build completed successfully"

    # Create a convenience symlink to the Swift binary
    if [ "$BUILD_TYPE" = "debug" ]; then
        SWIFT_BINARY=".build/debug/pdf22md"
    else
        SWIFT_BINARY=".build/release/pdf22md"
    fi

    if [ -f "$SWIFT_BINARY" ]; then
        ln -sf "$SWIFT_BINARY" pdf22md
        print_success "Binary created: pdf22md/pdf22md"
    fi
else
    print_error "Swift build failed"
    exit 1
fi

cd ..

# Install if requested
if [ "$INSTALL" = true ]; then
    print_status "Installing binary"

    if [ "$BUILD_TYPE" = "debug" ]; then
        SWIFT_BINARY="pdf22md/.build/debug/pdf22md"
    else
        SWIFT_BINARY="pdf22md/.build/release/pdf22md"
    fi

    if [ -f "$SWIFT_BINARY" ]; then
        sudo cp "$SWIFT_BINARY" /usr/local/bin/pdf22md
        print_success "Installed pdf22md to /usr/local/bin/"
    fi
fi

print_success "Build completed successfully!"

# Show summary
echo
print_status "Build Summary:"
if [ "$BUILD_TYPE" = "debug" ]; then
    echo "  • Swift binary: pdf22md/.build/debug/pdf22md"
else
    echo "  • Swift binary: pdf22md/.build/release/pdf22md"
fi
if [ -L "pdf22md/pdf22md" ]; then
    echo "  • Swift symlink: pdf22md/pdf22md"
fi
