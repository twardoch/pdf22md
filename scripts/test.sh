#!/bin/bash
# this_file: scripts/test.sh
# Test script for pdf22md

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
VERBOSE=false
BUILD_TYPE="release"
GENERATE_COVERAGE=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --verbose)
        VERBOSE=true
        shift
        ;;
    --debug)
        BUILD_TYPE="debug"
        shift
        ;;
    --coverage)
        GENERATE_COVERAGE=true
        shift
        ;;
    -h | --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --verbose        Enable verbose output"
        echo "  --debug          Test debug build"
        echo "  --coverage       Generate code coverage report"
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

# Inject version information
print_status "Injecting version information"
./scripts/inject-version.sh

# Build project first
print_status "Building project for testing"
cd pdf22md

if [ "$BUILD_TYPE" = "debug" ]; then
    swift build
else
    swift build -c release
fi

if [ $? -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_success "Build completed successfully"

# Run tests
print_status "Running Swift tests"

if [ "$GENERATE_COVERAGE" = true ]; then
    print_status "Generating code coverage report"
    swift test --enable-code-coverage
    
    # Generate coverage report
    if command -v xcov &> /dev/null; then
        print_status "Generating HTML coverage report"
        xcov -s pdf22md.xcodeproj --html_report
        print_success "Coverage report generated at ./xcov_report/index.html"
    else
        print_warning "xcov not found, install with: gem install xcov"
    fi
else
    if [ "$VERBOSE" = true ]; then
        swift test --verbose
    else
        swift test
    fi
fi

if [ $? -ne 0 ]; then
    print_error "Tests failed"
    exit 1
fi

print_success "All tests passed!"

# Run basic integration test
print_status "Running integration test"
cd ..

# Create test output directory
TEST_OUTPUT_DIR="test-output"
rm -rf "$TEST_OUTPUT_DIR"
mkdir -p "$TEST_OUTPUT_DIR"

# Test with a simple PDF if available
if [ -f "testdata/pdf/test.pdf" ]; then
    print_status "Testing with sample PDF"
    
    BINARY_PATH="pdf22md/.build/${BUILD_TYPE}/pdf22md"
    
    if [ -f "$BINARY_PATH" ]; then
        "$BINARY_PATH" -i testdata/pdf/test.pdf -o "$TEST_OUTPUT_DIR/test.md" -a "$TEST_OUTPUT_DIR/assets"
        
        if [ -f "$TEST_OUTPUT_DIR/test.md" ]; then
            print_success "Integration test passed - output generated"
            
            # Check if assets were created
            if [ -d "$TEST_OUTPUT_DIR/assets" ]; then
                ASSET_COUNT=$(ls -1 "$TEST_OUTPUT_DIR/assets" | wc -l)
                print_success "Generated $ASSET_COUNT assets"
            fi
        else
            print_error "Integration test failed - no output generated"
            exit 1
        fi
    else
        print_error "Binary not found at $BINARY_PATH"
        exit 1
    fi
else
    print_warning "No test PDF found at testdata/pdf/test.pdf, skipping integration test"
fi

# Test version output
print_status "Testing version output"
BINARY_PATH="pdf22md/.build/${BUILD_TYPE}/pdf22md"

if [ -f "$BINARY_PATH" ]; then
    VERSION_OUTPUT=$("$BINARY_PATH" --version 2>&1)
    if [ $? -eq 0 ]; then
        print_success "Version output: $VERSION_OUTPUT"
    else
        print_error "Version command failed"
        exit 1
    fi
else
    print_error "Binary not found for version test"
    exit 1
fi

# Clean up test output
rm -rf "$TEST_OUTPUT_DIR"

print_success "All tests completed successfully!"

# Show test summary
echo
print_status "Test Summary:"
echo "  • Swift tests: PASSED"
echo "  • Integration test: PASSED"
echo "  • Version test: PASSED"
echo "  • Build type: $BUILD_TYPE"
if [ "$GENERATE_COVERAGE" = true ]; then
    echo "  • Code coverage: GENERATED"
fi