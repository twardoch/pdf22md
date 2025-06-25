#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}[BUILD]${NC} $1"; }

# Track build results
build_results_objc=0
build_results_swift=0

# Check for required tools
check_requirements() {
    local missing_tools=()

    if ! command -v clang &>/dev/null; then
        missing_tools+=("clang")
    fi

    if ! command -v swift &>/dev/null; then
        missing_tools+=("swift")
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
    print_header "Building pdf22md-objc..."
    
    if [ ! -d "pdf22md-objc" ]; then
        print_error "pdf22md-objc directory not found"
        build_results_objc=1
        return 1
    fi
    
    # Build using unified Makefile
    if make clean && make; then
        print_info "✓ pdf22md-objc built successfully"
        build_results_objc=0
        
        # Run tests if requested
        if [ "$RUN_TESTS" = "true" ]; then
            if make test; then
                print_info "✓ Tests passed"
            else
                print_warning "Tests failed, but build completed"
            fi
        fi
        
        # Install if requested
        if [ "$INSTALL_BINARIES" = "true" ]; then
            if sudo make install; then
                print_info "✓ Installation completed"
            else
                print_error "Installation failed"
                build_results_objc=1
            fi
        fi
    else
        print_error "✗ pdf22md-objc build failed"
        build_results_objc=1
    fi
    return $build_results_objc
}

# Build pdf22md-swift
build_swift() {
    print_header "Building pdf22md-swift..."
    
    if [ ! -d "pdf22md-swift" ]; then
        print_error "pdf22md-swift directory not found"
        build_results_swift=1
        return 1
    fi
    
    # Check if Swift toolchain is functional before attempting build
    if ! swift --version >/dev/null 2>&1; then
        print_error "Swift toolchain appears to be corrupted or missing"
        print_warning "Skipping Swift build. Install/repair Xcode Command Line Tools:"
        print_info "  xcode-select --install"
        build_results_swift=1
        return 1
    fi
    
    # Check for Swift Package Manager functionality
    if ! swift package --version >/dev/null 2>&1; then
        print_error "Swift Package Manager is not functional"
        print_warning "This is often due to missing SWBBuildService.framework"
        print_info "Possible solutions:"
        print_info "  1. Run: xcode-select --install"
        print_info "  2. If you have Xcode installed: sudo xcode-select -s /Applications/Xcode.app"
        print_info "  3. Reinstall Command Line Tools completely:"
        print_info "     sudo rm -rf /Library/Developer/CommandLineTools"
        print_info "     xcode-select --install"
        build_results_swift=1
        return 1
    fi
    
    cd pdf22md-swift
    
    # Build with options
    local build_cmd="./build.sh"
    if [ "$RUN_TESTS" = "true" ]; then
        build_cmd="$build_cmd --test"
    fi
    if [ "$INSTALL_BINARIES" = "true" ]; then
        build_cmd="$build_cmd --install"
    fi
    
    if $build_cmd; then
        print_info "✓ pdf22md-swift built successfully"
        build_results_swift=0
    else
        print_error "✗ pdf22md-swift build failed"
        print_warning "Swift toolchain may be corrupted. Try:"
        print_info "  xcode-select --install"
        build_results_swift=1
    fi
    
    cd ..
    return $build_results_swift
}

# Create release archives
create_releases() {
    print_header "Creating release archives..."
    
    # Create Swift release
    if [ $build_results_swift -eq 0 ]; then
        cd pdf22md-swift
        if ./release.sh; then
            print_info "✓ Swift release archive created"
        else
            print_warning "Swift release archive creation failed"
        fi
        cd ..
    fi
    
    # Create Objective-C release (manual process since no release.sh)
    if [ $build_results_objc -eq 0 ]; then
        print_info "Objective-C binary available at: pdf22md-objc/pdf22md"
    fi
}

# Show build summary
show_summary() {
    print_header "Build Summary"
    
    local total_success=0
    local total_builds=0
    
    if [ "$BUILD_OBJC" = "true" ]; then
        total_builds=$((total_builds + 1))
        if [ $build_results_objc -eq 0 ]; then
            print_info "✓ pdf22md-objc: SUCCESS"
            total_success=$((total_success + 1))
        else
            print_error "✗ pdf22md-objc: FAILED"
        fi
    fi
    
    if [ "$BUILD_SWIFT" = "true" ]; then
        total_builds=$((total_builds + 1))
        if [ $build_results_swift -eq 0 ]; then
            print_info "✓ pdf22md-swift: SUCCESS"
            total_success=$((total_success + 1))
        else
            print_error "✗ pdf22md-swift: FAILED"
        fi
    fi
    
    echo ""
    if [ $total_success -eq $total_builds ]; then
        print_info "🎉 All builds completed successfully! ($total_success/$total_builds)"
        
        if [ "$INSTALL_BINARIES" = "true" ]; then
            echo ""
            print_info "Installed binaries:"
            if [ $build_results_objc -eq 0 ]; then
                print_info "  - pdf22md (Objective-C implementation)"
            fi
            if [ $build_results_swift -eq 0 ]; then
                print_info "  - pdf22md-swift (Swift implementation)"
            fi
            print_info "Run 'man pdf22md' for usage information"
        else
            echo ""
            print_info "Built binaries:"
            if [ $build_results_objc -eq 0 ]; then
                print_info "  - pdf22md-objc/pdf22md"
            fi
            if [ $build_results_swift -eq 0 ]; then
                print_info "  - pdf22md-swift/.build/release/pdf22md"
            fi
        fi
    else
        print_error "Some builds failed ($total_success/$total_builds successful)"
        exit 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --test              Run tests after building"
    echo "  --install           Install binaries to /usr/local/bin"
    echo "  --release           Create release archives"
    echo "  --objc-only         Build only Objective-C implementation"
    echo "  --swift-only        Build only Swift implementation"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Build both implementations"
    echo "  $0 --test           # Build and test both implementations"
    echo "  $0 --install        # Build and install both implementations"
    echo "  $0 --test --install # Build, test, and install both implementations"
    echo "  $0 --objc-only      # Build only Objective-C implementation"
    echo "  $0 --release        # Build both and create release archives"
}

# Parse command line arguments
parse_args() {
    RUN_TESTS=false
    INSTALL_BINARIES=false
    CREATE_RELEASES=false
    BUILD_OBJC=true
    BUILD_SWIFT=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test)
                RUN_TESTS=true
                shift
                ;;
            --install)
                INSTALL_BINARIES=true
                shift
                ;;
            --release)
                CREATE_RELEASES=true
                shift
                ;;
            --objc-only)
                BUILD_OBJC=true
                BUILD_SWIFT=false
                shift
                ;;
            --swift-only)
                BUILD_OBJC=false
                BUILD_SWIFT=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"
    
    print_header "pdf22md - Multi-Implementation Build System"
    print_info "Building$([ "$BUILD_OBJC" = "true" ] && echo " Objective-C")$([ "$BUILD_SWIFT" = "true" ] && echo " Swift") implementation$([ "$BUILD_OBJC" = "true" ] && [ "$BUILD_SWIFT" = "true" ] && echo "s")"
    
    # Check requirements
    check_requirements
    
    # Build implementations
    if [ "$BUILD_OBJC" = "true" ]; then
        build_objc
    fi
    
    if [ "$BUILD_SWIFT" = "true" ]; then
        build_swift
        # If Swift fails and we're building both, suggest continuing with Objective-C only
        if [ $build_results_swift -ne 0 ] && [ "$BUILD_OBJC" = "true" ] && [ $build_results_objc -eq 0 ]; then
            print_warning "Swift build failed but Objective-C build succeeded"
            print_info "The Objective-C implementation is fully functional"
        fi
    fi
    
    # Create releases if requested
    if [ "$CREATE_RELEASES" = "true" ]; then
        create_releases
    fi
    
    # Show summary
    show_summary
}

main "$@"