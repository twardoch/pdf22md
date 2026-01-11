#!/usr/bin/env bash
# this_file: example.sh
# Batch PDF conversion test script
# Converts PDFs in testdata/pdf/ using different methods
# Results stored in testdata/<method>/ directories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF22MD="${SCRIPT_DIR}/pdf22md/.build/release/pdf22md"
PDF_DIR="${SCRIPT_DIR}/testdata/pdf"
TIMEOUT=${TIMEOUT:-120}
VERSION="1.6.1"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Converts PDFs in testdata/pdf/ using all conversion methods.
Results stored in testdata/{fast,standard,optimized,ultra}/

Options:
  -h, --help     Show this help
  -V, --version  Show version
  -q, --quiet    Suppress conversion output (show only summary)
  -t SECONDS     Timeout per file (default: 120)
  -m METHODS     Comma-separated methods (default: fast,standard,optimized,ultra)

Environment:
  TIMEOUT        Same as -t option

Examples:
  ./example.sh                      # Run all methods
  ./example.sh -q                   # Quiet mode
  ./example.sh -t 60 -m fast,ultra  # 60s timeout, only fast and ultra
EOF
    exit 0
}

QUIET=false
METHODS_STR="fast,standard,optimized,ultra"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -V|--version) echo "example.sh v${VERSION}"; exit 0 ;;
        -q|--quiet) QUIET=true; shift ;;
        -t) TIMEOUT="$2"; shift 2 ;;
        -m) METHODS_STR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

IFS=',' read -ra METHODS <<< "$METHODS_STR"

declare -A FLAGS=(
    ["fast"]="--fast"
    ["standard"]=""
    ["optimized"]="--optimized"
    ["ultra"]="--ultra-optimized"
)

# Check binary
if [[ ! -x "$PDF22MD" ]]; then
    echo "Error: pdf22md not found at $PDF22MD"
    echo "Run: cd pdf22md && swift build -c release"
    exit 1
fi

# Check PDF directory
if [[ ! -d "$PDF_DIR" ]]; then
    echo "Error: PDF directory not found: $PDF_DIR"
    exit 1
fi

convert_pdf() {
    local pdf="$1"
    local method="$2"
    local flags="${FLAGS[$method]:-}"
    local out_dir="${SCRIPT_DIR}/testdata/${method}"
    local assets_dir="${out_dir}/assets"
    local name
    name=$(basename "$pdf" .pdf)
    local md_file="${out_dir}/${name}.md"

    mkdir -p "$out_dir" "$assets_dir"

    local start_time
    start_time=$(date +%s)

    if $QUIET; then
        if timeout "$TIMEOUT" "$PDF22MD" -i "$pdf" -o "$md_file" -a "$assets_dir" -q $flags 2>/dev/null; then
            local elapsed=$(($(date +%s) - start_time))
            echo "  ${name}.pdf -> ${method}/ (${elapsed}s)"
        else
            echo "  ${name}.pdf -> ${method}/ FAILED"
        fi
    else
        echo "  ${name}.pdf -> ${method}/${name}.md"
        if timeout "$TIMEOUT" "$PDF22MD" -i "$pdf" -o "$md_file" -a "$assets_dir" $flags 2>&1 \
            | grep -vE "(attributedStringScaled|CoreText note|CoreGraphics PDF)" \
            | head -5 \
            | sed 's/^/    /'; then
            local elapsed=$(($(date +%s) - start_time))
            echo "    OK (${elapsed}s)"
        else
            echo "    FAILED or TIMEOUT (${TIMEOUT}s)"
        fi
    fi
}

echo "PDF22MD Batch Conversion Test v${VERSION}"
echo "Timeout: ${TIMEOUT}s per file"
echo ""

for method in "${METHODS[@]}"; do
    echo "=== Method: ${method} ==="
    for pdf in "$PDF_DIR"/*.pdf; do
        [[ -f "$pdf" ]] || continue
        convert_pdf "$pdf" "$method"
    done
    echo ""
done

echo "Summary:"
for method in "${METHODS[@]}"; do
    dir="${SCRIPT_DIR}/testdata/${method}"
    if [[ -d "$dir" ]]; then
        count=$(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "  ${method}: ${count} files, ${size}"
    else
        echo "  ${method}: (no output)"
    fi
done
