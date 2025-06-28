#!/bin/bash
# Test Swift implementation (pdf22md)
set -e

# Change to script directory
cd "$(dirname "$0")"

# Default to test.pdf if no argument provided
if [ $# -ne 1 ]; then
    PDF="testdata/test.pdf"
else
    PDF=$(realpath "$1")
fi

PDF_DIR=$(dirname "$PDF")
PDF_NAME=$(basename "$PDF" .pdf)
MD_FILE="$PDF_DIR/$PDF_NAME-sw.md"
ASSETS_DIR="$PDF_DIR/$PDF_NAME-sw"

# Build Swift version
echo "Building Swift implementation..."
cd pdf22md && swift build -c release && cd ..

# Run Swift version
echo "Running Swift converter on $PDF..."
echo "Output: $MD_FILE"
echo "Assets: $ASSETS_DIR/"
echo ""

time ./pdf22md/.build/release/pdf22md \
    -i "$PDF" \
    -o "$MD_FILE" \
    -a "$ASSETS_DIR"

echo ""
echo "Swift conversion complete!"
echo "Markdown: $MD_FILE"
if [ -d "$ASSETS_DIR" ]; then
    ASSET_COUNT=$(find "$ASSETS_DIR" -type f | wc -l | tr -d ' ')
    echo "Assets: $ASSET_COUNT files in $ASSETS_DIR/"
fi
