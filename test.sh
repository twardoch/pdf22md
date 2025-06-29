#!/bin/bash
# Test pdf22md Swift implementation
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
MD_FILE="$PDF_DIR/$PDF_NAME.md"
ASSETS_DIR="$PDF_DIR/$PDF_NAME-assets"

# Build Swift version first
echo "Building pdf22md..."
./build.sh

echo ""
echo "Running pdf22md converter on $PDF..."
echo "Output: $MD_FILE"
echo ""

# Run Swift version
echo "Starting pdf22md converter..."
CG_PDF_VERBOSE=True time ./pdf22md/.build/release/pdf22md \
    -i "$PDF" \
    -o "$MD_FILE" \
    -a "$ASSETS_DIR"
echo "Complete!"

echo ""
echo "Conversion complete!"
echo ""
echo "Results:"
echo "--------"
echo "  Markdown: $MD_FILE"
if [ -d "$ASSETS_DIR" ]; then
    ASSET_COUNT=$(find "$ASSETS_DIR" -type f | wc -l | tr -d ' ')
    echo "  Assets: $ASSET_COUNT files in $ASSETS_DIR/"
fi
