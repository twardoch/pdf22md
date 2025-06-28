#!/bin/bash
# Test Objective-C implementation (pdf21md)
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
MD_FILE="$PDF_DIR/$PDF_NAME-oc.md"
ASSETS_DIR="$PDF_DIR/$PDF_NAME-oc"

# Build Objective-C version
echo "Building Objective-C implementation..."
cd pdf21md && make clean && make && cd ..

# Run Objective-C version
echo "Running Objective-C converter on $PDF..."
echo "Output: $MD_FILE"
echo "Assets: $ASSETS_DIR/"
echo ""

CG_PDF_VERBOSE=True time ./pdf21md/pdf21md \
    -i "$PDF" \
    -o "$MD_FILE" \
    -a "$ASSETS_DIR"

echo ""
echo "Objective-C conversion complete!"
echo "Markdown: $MD_FILE"
if [ -d "$ASSETS_DIR" ]; then
    ASSET_COUNT=$(find "$ASSETS_DIR" -type f | wc -l | tr -d ' ')
    echo "Assets: $ASSET_COUNT files in $ASSETS_DIR/"
fi