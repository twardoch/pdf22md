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

# Configuration
APP_NAME="pdf22md-swift"
BUILD_DIR=".build/release"
ARCHIVE_DIR="archive"

# Get version from git or default
get_version() {
    local version=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
    echo "$version"
}

# Build release version
build_release() {
    print_info "Building release version..."
    
    # Clean and build
    swift build -c release
    
    if [ $? -eq 0 ]; then
        print_info "✓ Release build completed successfully"
        return 0
    else
        print_error "Release build failed"
        return 1
    fi
}

# Run tests before release
run_tests() {
    print_info "Running test suite..."
    
    if swift test; then
        print_info "✓ All tests passed"
        return 0
    else
        print_error "Tests failed"
        return 1
    fi
}

# Create archive
create_archive() {
    local version=$(get_version)
    local archive_name="${APP_NAME}-${version}-macos"
    
    print_info "Creating archive: ${archive_name}"
    
    # Create archive directory
    mkdir -p "$ARCHIVE_DIR"
    
    # Create temporary directory for archive contents
    local temp_dir=$(mktemp -d)
    local archive_path="$temp_dir/$archive_name"
    
    mkdir -p "$archive_path"
    
    # Copy binary
    if [ -f "$BUILD_DIR/pdf22md" ]; then
        cp "$BUILD_DIR/pdf22md" "$archive_path/"
        print_info "✓ Copied binary"
    else
        print_error "Binary not found at $BUILD_DIR/pdf22md"
        return 1
    fi
    
    # Copy documentation
    if [ -f "README.md" ]; then
        cp "README.md" "$archive_path/"
    fi
    
    if [ -f "docs/pdf22md.1" ]; then
        mkdir -p "$archive_path/man"
        cp "docs/pdf22md.1" "$archive_path/man/"
        print_info "✓ Copied documentation"
    fi
    
    # Create tarball
    cd "$temp_dir"
    tar -czf "${archive_name}.tar.gz" "$archive_name"
    
    # Move to archive directory
    mv "${archive_name}.tar.gz" "$OLDPWD/$ARCHIVE_DIR/"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_info "✓ Archive created: $ARCHIVE_DIR/${archive_name}.tar.gz"
    
    # Show archive contents
    print_info "Archive contents:"
    tar -tzf "$ARCHIVE_DIR/${archive_name}.tar.gz" | sed 's/^/  /'
}

# Main execution
main() {
    local version=$(get_version)
    
    print_info "Starting release process for $APP_NAME version $version"
    
    # Build release
    if ! build_release; then
        exit 1
    fi
    
    # Run tests
    if ! run_tests; then
        print_error "Tests failed, aborting release"
        exit 1
    fi
    
    # Create archive
    if ! create_archive; then
        print_error "Archive creation failed"
        exit 1
    fi
    
    print_info "🎉 Release complete!"
    print_info "Version: $version"
    print_info "Archive: $ARCHIVE_DIR/${APP_NAME}-${version}-macos.tar.gz"
    print_info ""
    print_info "To install locally:"
    print_info "  tar -xzf $ARCHIVE_DIR/${APP_NAME}-${version}-macos.tar.gz"
    print_info "  sudo cp ${APP_NAME}-${version}-macos/pdf22md /usr/local/bin/pdf22md-swift"
}

main "$@"