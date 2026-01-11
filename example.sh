#!/usr/bin/env bash
# this_file: example.sh
# Converts all PDFs in testdata/pdf/ using different methods
# Results stored in testdata/<method>/ directories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF22MD="${SCRIPT_DIR}/pdf22md/.build/release/pdf22md"
PDF_DIR="${SCRIPT_DIR}/testdata/pdf"
TIMEOUT=${TIMEOUT:-120}  # Default 2 min per file

# Check binary exists
if [[ ! -x "$PDF22MD" ]]; then
    echo "Error: pdf22md binary not found at $PDF22MD"
    echo "Run 'cd pdf22md && swift build -c release' first"
    exit 1
fi

# Check PDF directory exists
if [[ ! -d "$PDF_DIR" ]]; then
    echo "Error: PDF directory not found at $PDF_DIR"
    exit 1
fi

# Define conversion methods (ordered for predictable execution)
METHODS=("fast" "standard" "optimized" "ultra")
declare -A FLAGS=(
    ["fast"]="--fast"
    ["standard"]=""
    ["optimized"]="--optimized"
    ["ultra"]="--ultra-optimized"
)

convert_pdf() {
    local pdf="$1"
    local method="$2"
    local flags="${FLAGS[$method]}"
    local out_dir="${SCRIPT_DIR}/testdata/${method}"
    local assets_dir="${out_dir}/assets"
    local basename
    basename=$(basename "$pdf" .pdf)
    local md_file="${out_dir}/${basename}.md"

    mkdir -p "$out_dir" "$assets_dir"

    echo "  ${basename}.pdf -> ${method}/${basename}.md"
    if timeout "$TIMEOUT" "$PDF22MD" -i "$pdf" -o "$md_file" -a "$assets_dir" $flags 2>&1 | grep -v "attributedStringScaled" | head -20; then
        echo "    OK"
    else
        echo "    FAILED or TIMEOUT (${TIMEOUT}s)"
    fi
}

# Process each method
for method in "${METHODS[@]}"; do
    echo "=== Converting with method: ${method} ==="
    for pdf in "$PDF_DIR"/*.pdf; do
        [[ -f "$pdf" ]] || continue
        convert_pdf "$pdf" "$method"
    done
    echo ""
done

echo "Done. Results in testdata/{fast,standard,optimized,ultra}/"
echo ""
echo "Summary:"
for method in "${METHODS[@]}"; do
    count=$(find "${SCRIPT_DIR}/testdata/${method}" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "  ${method}: ${count} files"
done
