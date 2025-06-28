#!/bin/bash
# Test both Objective-C and Swift implementations in parallel
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
MD_FILE_OC="$PDF_DIR/$PDF_NAME-oc.md"
MD_FILE_SW="$PDF_DIR/$PDF_NAME-sw.md"
ASSETS_DIR_OC="$PDF_DIR/$PDF_NAME-oc"
ASSETS_DIR_SW="$PDF_DIR/$PDF_NAME-sw"

# Build both versions first
echo "Building both implementations..."
./build.sh

echo ""
echo "Running both converters in parallel on $PDF..."
echo "Objective-C output: $MD_FILE_OC"
echo "Swift output: $MD_FILE_SW"
echo ""

# Run both versions in parallel
(
    echo "[OC] Starting Objective-C converter..."
    CG_PDF_VERBOSE=True time ./pdf21md/pdf21md \
        -i "$PDF" \
        -o "$MD_FILE_OC" \
        -a "$ASSETS_DIR_OC"
    echo "[OC] Complete!"
) &
OC_PID=$!

(
    echo "[SW] Starting Swift converter..."
    CG_PDF_VERBOSE=True time ./pdf22md/.build/release/pdf22md \
        -i "$PDF" \
        -o "$MD_FILE_SW" \
        -a "$ASSETS_DIR_SW"
    echo "[SW] Complete!"
) &
SW_PID=$!

# Wait for both to complete
echo "Waiting for both converters to finish..."
wait $OC_PID
wait $SW_PID

echo ""
echo "Both conversions complete!"
echo ""
echo "Results:"
echo "--------"
echo "Objective-C:"
echo "  Markdown: $MD_FILE_OC"
if [ -d "$ASSETS_DIR_OC" ]; then
    OC_ASSET_COUNT=$(find "$ASSETS_DIR_OC" -type f | wc -l | tr -d ' ')
    echo "  Assets: $OC_ASSET_COUNT files in $ASSETS_DIR_OC/"
fi

echo ""
echo "Swift:"
echo "  Markdown: $MD_FILE_SW"
if [ -d "$ASSETS_DIR_SW" ]; then
    SW_ASSET_COUNT=$(find "$ASSETS_DIR_SW" -type f | wc -l | tr -d ' ')
    echo "  Assets: $SW_ASSET_COUNT files in $ASSETS_DIR_SW/"
fi
