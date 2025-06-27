#!/usr/bin/env bash
# test_new.sh – quick sanity tests for both Swift (pdf22md) and Objective-C (pdf21md) implementations
#
# 1. Converts a small PDF that contains only text and expects:
#    • markdown file produced
#    • NO assets directory (or it is empty)
# 2. Converts a larger PDF with photos and expects:
#    • markdown file produced
#    • assets directory exists and contains at least one file
#
# Each conversion is aborted after 60 seconds to avoid accidental hangs.
# The script exits non-zero on the first failed assertion.
#
# Usage: ./test_new.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_BIN="$ROOT_DIR/pdf22md/.build/release/pdf22md"
OBJC_BIN="$ROOT_DIR/pdf21md/pdf21md"

# Verify binaries exist
for BIN in "$SWIFT_BIN" "$OBJC_BIN"; do
    if [[ ! -x "$BIN" ]]; then
        echo "❌ Binary not found or not executable: $BIN" >&2
        exit 1
    fi
done

small_pdf="$ROOT_DIR/testdata/test2.pdf"
large_pdf="$ROOT_DIR/testdata/test.pdf"

# Helper to run a command with a 60-second timeout (uses `timeout` if available,
# otherwise falls back to background job + kill).
run_with_timeout() {
    local cmd="$1"
    local seconds=60
    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" bash -c "$cmd"
    else
        # Fallback for macOS without coreutils timeout
        bash -c "($cmd) & pid=$!; (sleep $seconds && kill -9 $pid 2>/dev/null) & wait $pid"
    fi
}

# Clean helper
clean_outputs() {
    local md_file="$1"
    shift
    local assets_dir="$1"
    rm -f "$md_file"
    rm -rf "$assets_dir"
}

assert_file_nonempty() {
    local file="$1"
    if [[ ! -s "$file" ]]; then
        echo "❌ Expected non-empty file: $file" >&2
        exit 1
    fi
}

assert_dir_missing_or_empty() {
    local dir="$1"
    if [[ -d "$dir" && -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
        echo "❌ Expected no assets in $dir" >&2
        exit 1
    fi
}

assert_dir_has_files() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "❌ Expected assets directory $dir to exist" >&2
        exit 1
    fi
    if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        echo "❌ Expected assets in $dir but directory is empty" >&2
        exit 1
    fi
}

echo "🟣 Running Swift converter tests…"

echo "• Small PDF (text-only)"
small_md_sw="$ROOT_DIR/testdata/test2.md"
small_assets_sw="$ROOT_DIR/testdata/test2_assets"
clean_outputs "$small_md_sw" "$small_assets_sw"
run_with_timeout "$SWIFT_BIN -i $small_pdf -o $small_md_sw -a $small_assets_sw"
assert_file_nonempty "$small_md_sw"
assert_dir_missing_or_empty "$small_assets_sw"

echo "• Large PDF (with photos)"
large_md_sw="$ROOT_DIR/testdata/test.md"
large_assets_sw="$ROOT_DIR/testdata/test_assets"
clean_outputs "$large_md_sw" "$large_assets_sw"
run_with_timeout "$SWIFT_BIN --optimized -i $large_pdf -o $large_md_sw -a $large_assets_sw"
assert_file_nonempty "$large_md_sw"
assert_dir_has_files "$large_assets_sw"

echo "🟢 Swift converter tests passed\n"

echo "🟣 Running Objective-C converter tests…"

echo "• Small PDF (text-only)"
small_md_oc="$ROOT_DIR/testdata/test2_oc.md"
small_assets_oc="$ROOT_DIR/testdata/test2_oc_assets"
clean_outputs "$small_md_oc" "$small_assets_oc"
run_with_timeout "$OBJC_BIN -i $small_pdf -o $small_md_oc -a $small_assets_oc"
assert_file_nonempty "$small_md_oc"
assert_dir_missing_or_empty "$small_assets_oc"

echo "• Large PDF (with photos)"
large_md_oc="$ROOT_DIR/testdata/test_oc.md"
large_assets_oc="$ROOT_DIR/testdata/test_oc_assets"
clean_outputs "$large_md_oc" "$large_assets_oc"
run_with_timeout "$OBJC_BIN -i $large_pdf -o $large_md_oc -a $large_assets_oc"
assert_file_nonempty "$large_md_oc"
assert_dir_has_files "$large_assets_oc"

echo "🟢 Objective-C converter tests passed\n"

echo "✅ All tests succeeded!"
