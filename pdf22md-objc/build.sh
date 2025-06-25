#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for required tools
check_requirements() {
    local missing_tools=()

    if ! command -v clang &>/dev/null; then
        missing_tools+=("clang")
    fi

    if ! command -v make &>/dev/null; then
        missing_tools+=("make")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install Xcode Command Line Tools:"
        print_info "xcode-select --install"
        exit 1
    fi
}

# Build pdf22md-objc
build_objc() {
    print_info "Building pdf22md (Objective-C implementation)..."
    make clean
    if make; then
        print_info "✓ pdf22md-objc built successfully"
        return 0
    else
        print_error "Failed to build pdf22md-objc"
        return 1
    fi
}

# Install binary
install_binary() {
    local install_dir="/usr/local/bin"
    print_info "Installing binary to $install_dir..."

    # Create install directory if it doesn't exist
    sudo mkdir -p "$install_dir"

    # Install pdf22md
    if [ -f "pdf22md" ]; then
        sudo install -m 755 pdf22md "$install_dir/pdf22md"
        print_info "✓ Installed pdf22md"
    fi

    # Install man pages
    if [ -f "docs/pdf22md.1" ]; then
        sudo mkdir -p /usr/local/share/man/man1
        sudo install -m 644 docs/pdf22md.1 /usr/local/share/man/man1/
        print_info "✓ Installed man pages"
    fi
}

# Run tests
run_tests() {
    print_info "Running tests..."
    if [ -f "run-tests.sh" ]; then
        ./run-tests.sh
    else
        print_warning "No test script found"
    fi
}

# Main execution
main() {
    print_info "Starting pdf22md-objc build process..."

    # Check requirements
    check_requirements

    # Build component
    build_objc

    # Run tests if requested
    if [ "$1" = "--test" ]; then
        run_tests
    fi

    # Install if requested
    if [ "$1" = "--install" ] || [ "$2" = "--install" ]; then
        install_binary
    fi

    print_info "Build complete!"
    print_info "Run './pdf22md --help' for usage information"
}

main "$@"