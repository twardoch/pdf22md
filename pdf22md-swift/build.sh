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

    if ! command -v swift &>/dev/null; then
        missing_tools+=("swift")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install Xcode Command Line Tools:"
        print_info "xcode-select --install"
        exit 1
    fi
}

# Build pdf22md-swift
build_swift() {
    print_info "Building pdf22md (Swift implementation)..."
    
    # Clean previous builds
    if [ -d ".build" ]; then
        rm -rf .build
        print_info "Cleaned previous build artifacts"
    fi
    
    # Try to detect and fix Swift toolchain issues
    print_info "Checking Swift toolchain..."
    
    # Check for SWBBuildService.framework issue
    local swift_build_output
    swift_build_output=$(swift build -c release 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_info "✓ pdf22md-swift built successfully"
        return 0
    elif echo "$swift_build_output" | grep -q "SWBBuildService.framework"; then
        print_error "Swift Package Manager framework missing: SWBBuildService.framework"
        print_warning "This is a known issue with Command Line Tools installation"
        print_info ""
        print_info "To fix this issue, try ONE of these solutions:"
        print_info ""
        print_info "Option 1: If you have Xcode installed"
        print_info "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        print_info ""
        print_info "Option 2: Reinstall Command Line Tools"
        print_info "  sudo rm -rf /Library/Developer/CommandLineTools"
        print_info "  xcode-select --install"
        print_info ""
        print_info "Option 3: Use the Objective-C implementation instead"
        print_info "  ./build.sh --objc-only"
        return 1
    else
        # Show the actual error
        print_error "Swift build failed with error:"
        echo "$swift_build_output" | tail -n 20
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
    if [ -f ".build/release/pdf22md" ]; then
        sudo install -m 755 .build/release/pdf22md "$install_dir/pdf22md-swift"
        print_info "✓ Installed pdf22md-swift"
    else
        print_error "Built binary not found at .build/release/pdf22md"
        return 1
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
    print_info "Running Swift tests..."
    if swift test; then
        print_info "✓ Swift tests passed"
        return 0
    else
        print_error "Swift tests failed"
        return 1
    fi
}

# Create local binary symlink for development
create_dev_link() {
    if [ -f ".build/release/pdf22md" ]; then
        ln -sf .build/release/pdf22md pdf22md
        print_info "✓ Created development symlink './pdf22md'"
    fi
}

# Main execution
main() {
    print_info "Starting pdf22md-swift build process..."

    # Check requirements
    check_requirements

    # Build component
    if ! build_swift; then
        exit 1
    fi

    # Create development symlink
    create_dev_link

    # Run tests if requested
    if [ "$1" = "--test" ] || [ "$2" = "--test" ]; then
        if ! run_tests; then
            print_warning "Tests failed, but build completed"
        fi
    fi

    # Install if requested
    if [ "$1" = "--install" ] || [ "$2" = "--install" ]; then
        install_binary
    fi

    print_info "Build complete!"
    print_info "Run './pdf22md --help' for usage information"
    print_info "Or run 'swift run pdf22md --help' to use Swift Package Manager directly"
}

main "$@"