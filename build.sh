#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_task() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse command line arguments
BUILD_OBJC=true
BUILD_SWIFT=true
CLEAN=false
INSTALL=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --objc-only)
            BUILD_SWIFT=false
            shift
            ;;
        --swift-only)
            BUILD_OBJC=false
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Build script for pdf22md (Objective-C and Swift implementations)"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --objc-only      Build only the Objective-C version"
            echo "  --swift-only     Build only the Swift version"
            echo "  --clean          Clean build artifacts before building"
            echo "  --install        Install the Objective-C version to /usr/local/bin"
            echo "  --version VER    Set version number for the build"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "By default, both implementations are built."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "PDF22MD Build Script"
echo "============================================"
echo ""

# Check for required tools
if ! command_exists clang; then
    print_error "clang not found. Please install Xcode Command Line Tools."
    exit 1
fi

if $BUILD_SWIFT && ! command_exists swift; then
    print_error "swift not found. Please install Xcode Command Line Tools."
    exit 1
fi

# Set version if provided
if [ -n "$VERSION" ]; then
    export VERSION
    print_info "Building with version: $VERSION"
fi

# Clean if requested
if $CLEAN; then
    print_task "Cleaning build artifacts..."
    
    if $BUILD_OBJC; then
        make clean >/dev/null 2>&1 || true
    fi
    
    if $BUILD_SWIFT; then
        (cd swift && swift package clean >/dev/null 2>&1) || true
    fi
    
    print_info "Clean complete"
    echo ""
fi

# Build Objective-C version
if $BUILD_OBJC; then
    print_task "Building Objective-C implementation..."
    
    if make; then
        print_info "Objective-C build successful"
        
        # Verify the binary
        if [ -f ./pdf22md ]; then
            VERSION_OUTPUT=$(./pdf22md -v 2>&1 || true)
            print_info "Built binary: ./pdf22md"
            if [ -n "$VERSION" ]; then
                print_info "Version: $VERSION_OUTPUT"
            fi
        else
            print_error "Binary not found after build"
            exit 1
        fi
    else
        print_error "Objective-C build failed"
        exit 1
    fi
    echo ""
fi

# Build Swift version
if $BUILD_SWIFT; then
    print_task "Building Swift implementation (Release mode)..."
    
    cd swift
    if swift build -c release; then
        print_info "Swift build successful"
        
        # Verify the binary
        if [ -f .build/release/pdf22md-swift ]; then
            print_info "Built binary: swift/.build/release/pdf22md-swift"
        else
            print_error "Swift binary not found after build"
            exit 1
        fi
    else
        print_error "Swift build failed"
        exit 1
    fi
    cd ..
    echo ""
fi

# Install if requested
if $INSTALL && $BUILD_OBJC; then
    print_task "Installing Objective-C version to /usr/local/bin..."
    
    if [ -w /usr/local/bin ]; then
        cp ./pdf22md /usr/local/bin/
        print_info "Installed successfully"
    else
        print_warning "Need sudo access to install to /usr/local/bin"
        sudo cp ./pdf22md /usr/local/bin/
        print_info "Installed successfully with sudo"
    fi
    echo ""
fi

# Summary
echo "============================================"
echo "Build Summary"
echo "============================================"

if $BUILD_OBJC; then
    echo "✅ Objective-C: ./pdf22md"
fi

if $BUILD_SWIFT; then
    echo "✅ Swift: ./swift/.build/release/pdf22md-swift"
fi

if $INSTALL && $BUILD_OBJC; then
    echo "✅ Installed: /usr/local/bin/pdf22md"
fi

echo ""
echo "To run benchmarks: ./bench.sh"
echo "To run tests: ./pdf22md -i test/sample.pdf -o output.md -a assets/"

# Create test PDFs if they don't exist
if [ ! -f "test/small.pdf" ] || [ ! -f "test/medium.pdf" ] || [ ! -f "test/large.pdf" ]; then
    print_warning "Test PDFs not found. Run ./create-test-pdf.swift to generate them."
fi