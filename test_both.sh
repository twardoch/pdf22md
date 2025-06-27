#!/bin/bash
# Test both Objective-C and Swift implementations
# Change to script directory

set -e

if [ $# -ne 1 ]; then
    PDF="testdata/test.pdf"
else
    PDF=$(realpath $1)
fi

cd "$(dirname "$0")"

PDF_DIR=$(dirname $PDF)
PDF_NAME=$(basename $PDF .pdf)
MD_DIR_OC="$PDF_DIR/$PDF_NAME-oc"
MD_DIR_SW="$PDF_DIR/$PDF_NAME-sw"

# Build both versions first
./build.sh

# Run Objective-C version
echo "oc"
CG_PDF_VERBOSE=True time ./pdf21md/pdf21md \
    -i "$PDF" \
    -o "$MD_DIR_OC.md" \
    -a "$MD_DIR_OC"

# Run Swift version
echo "sw"
CG_PDF_VERBOSE=True time ./pdf22md/.build/release/pdf22md -i "$PDF" -o "$MD_DIR_SW.md" -a "$MD_DIR_SW"
