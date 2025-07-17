#!/bin/bash
# this_file: scripts/inject-version.sh
# Script to inject version information into Swift build

set -e

# Get version from git
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Injecting version: $VERSION"
echo "Git commit: $COMMIT"
echo "Build date: $BUILD_DATE"

# Create temporary version file
VERSION_FILE="pdf22md/Sources/PDF22MD/Version.swift"
VERSION_TEMPLATE="pdf22md/Sources/PDF22MD/Version.swift.template"

# Create template if it doesn't exist
if [ ! -f "$VERSION_TEMPLATE" ]; then
    cp "$VERSION_FILE" "$VERSION_TEMPLATE"
fi

# Replace placeholders in the version file
sed -e "s/VERSION_STRING/$VERSION/g" \
    -e "s/GIT_COMMIT_HASH/$COMMIT/g" \
    -e "s/BUILD_TIMESTAMP/$BUILD_DATE/g" \
    "$VERSION_TEMPLATE" > "$VERSION_FILE"

echo "Version injection complete"