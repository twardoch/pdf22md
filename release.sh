#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to get the latest semver tag
get_latest_tag() {
    git tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}

# Function to increment version
increment_version() {
    local version=$1
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3)
    
    # Increment minor version
    minor=$((minor + 1))
    patch=0
    
    echo "${major}.${minor}.${patch}"
}

# Parse command line arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --v)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--v VERSION]"
            echo "  --v VERSION   Specify version (e.g., 1.2.3)"
            echo "  -h, --help    Show this help message"
            echo ""
            echo "If no version is specified, the script will increment the minor version"
            echo "of the latest git tag, or use 1.0.0 if no tags exist."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Determine version
if [ -z "$VERSION" ]; then
    LATEST_TAG=$(get_latest_tag)
    if [ -z "$LATEST_TAG" ]; then
        VERSION="1.0.0"
        print_info "No previous tags found. Using version $VERSION"
    else
        # Remove 'v' prefix
        CURRENT_VERSION=${LATEST_TAG#v}
        VERSION=$(increment_version $CURRENT_VERSION)
        print_info "Latest tag: $LATEST_TAG"
        print_info "New version: $VERSION"
    fi
else
    # Validate version format
    if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        print_error "Invalid version format. Please use semantic versioning (e.g., 1.2.3)"
        exit 1
    fi
fi

TAG="v$VERSION"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Check if git is clean
if ! git diff-index --quiet HEAD --; then
    print_warning "You have uncommitted changes. Committing them now..."
    git add -A
    git commit -m "Release version $VERSION"
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    print_error "Tag $TAG already exists"
    exit 1
fi

print_info "Building pdf22md version $VERSION..."

# Clean and build with version
make clean
make VERSION="$VERSION"

# Test the binary
if ! ./pdf22md -v | grep -q "$VERSION"; then
    print_error "Version check failed"
    exit 1
fi

print_info "Build successful!"

# Create git tag
print_info "Creating git tag $TAG..."
git tag -a "$TAG" -m "Release version $VERSION"

# Push commits and tags
print_info "Pushing to remote..."
git push origin main
git push origin "$TAG"

print_info "✅ Release $VERSION completed successfully!"
print_info ""
print_info "The GitHub Actions workflow will now:"
print_info "  1. Build the universal binary for Intel and Apple Silicon"
print_info "  2. Create a .pkg installer"
print_info "  3. Create a GitHub release with the artifacts"
print_info ""
print_info "Check the Actions tab on GitHub to monitor the release process."