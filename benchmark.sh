#!/usr/bin/env bash
# this_file: benchmark.sh
# Benchmark all 4 pdf22md conversion methods
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF22MD="${SCRIPT_DIR}/pdf22md/.build/release/pdf22md"
TESTDATA="${SCRIPT_DIR}/testdata/pdf"
RESULTS_DIR="${SCRIPT_DIR}/testdata/benchmark"
ITERATIONS=3
QUIET=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [PDF_FILE]

Benchmark pdf22md conversion methods.

OPTIONS:
  -h, --help        Show this help
  -V, --version     Show version
  -i, --iterations  Number of iterations per method (default: $ITERATIONS)
  -q, --quiet       Suppress progress output
  -o, --output      Results directory (default: $RESULTS_DIR)

METHODS:
  standard     Default async/await implementation
  fast         PDF text only, skip Vision OCR (--fast)
  optimized    GCD-based implementation (--optimized)
  ultra        NSString ultra-optimized (--ultra-optimized)

EXAMPLES:
  $(basename "$0")                    # Benchmark all PDFs in testdata/pdf
  $(basename "$0") doc.pdf            # Benchmark specific file
  $(basename "$0") -i 5 -q            # 5 iterations, quiet mode
EOF
}

log() { [[ "$QUIET" == "true" ]] || echo "[benchmark] $*" >&2; }
error() { echo "[benchmark] ERROR: $*" >&2; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -V|--version) echo "benchmark.sh v$VERSION"; exit 0 ;;
        -i|--iterations) ITERATIONS="$2"; shift 2 ;;
        -q|--quiet) QUIET=true; shift ;;
        -o|--output) RESULTS_DIR="$2"; shift 2 ;;
        -*) error "Unknown option: $1" ;;
        *) PDF_FILE="$1"; shift ;;
    esac
done

# Check binary exists
[[ -x "$PDF22MD" ]] || error "pdf22md not found. Run: cd pdf22md && swift build -c release"

# Prepare results directory
mkdir -p "$RESULTS_DIR"

# Define methods and their flags
declare -A METHOD_FLAGS=(
    ["fast"]="--fast"
    ["standard"]=""
    ["optimized"]="--optimized"
    ["ultra"]="--ultra-optimized"
)

# Benchmark a single file with all methods
benchmark_file() {
    local pdf="$1"
    local basename=$(basename "$pdf" .pdf)
    local results_file="${RESULTS_DIR}/${basename}_benchmark.csv"

    log "Benchmarking: $basename"

    # CSV header
    echo "method,iteration,wall_time_s,exit_code,output_size_bytes" > "$results_file"

    for method in fast standard optimized ultra; do
        local flags="${METHOD_FLAGS[$method]}"
        local output_file="${RESULTS_DIR}/${basename}_${method}.md"

        for ((i=1; i<=ITERATIONS; i++)); do
            log "  $method (iteration $i/$ITERATIONS)..."

            # Time the conversion
            local start_time=$(python3 -c "import time; print(time.time())")

            # Run conversion with timeout
            local exit_code=0
            timeout 120 "$PDF22MD" -i "$pdf" -o "$output_file" $flags 2>/dev/null || exit_code=$?

            local end_time=$(python3 -c "import time; print(time.time())")
            local wall_time=$(python3 -c "print(f'{$end_time - $start_time:.3f}')")

            # Get output size
            local output_size=0
            [[ -f "$output_file" ]] && output_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo 0)

            echo "${method},${i},${wall_time},${exit_code},${output_size}" >> "$results_file"
        done
    done

    log "Results saved: $results_file"
}

# Summarize results
summarize() {
    local results_file="$1"

    echo ""
    echo "=== Benchmark Summary: $(basename "$results_file" _benchmark.csv) ==="
    echo ""
    printf "%-12s %10s %10s %12s\n" "Method" "Avg Time" "Min Time" "Output Size"
    printf "%-12s %10s %10s %12s\n" "------" "--------" "--------" "-----------"

    for method in fast standard optimized ultra; do
        local times=$(grep "^${method}," "$results_file" | cut -d',' -f3)
        local avg=$(echo "$times" | awk '{sum+=$1; count++} END {if(count>0) printf "%.3f", sum/count; else print "N/A"}')
        local min=$(echo "$times" | sort -n | head -1)
        local size=$(grep "^${method}," "$results_file" | tail -1 | cut -d',' -f5)

        printf "%-12s %9ss %9ss %11s B\n" "$method" "$avg" "${min:-N/A}" "${size:-0}"
    done
    echo ""
}

# Main
if [[ -n "${PDF_FILE:-}" ]]; then
    # Single file mode
    [[ -f "$PDF_FILE" ]] || error "File not found: $PDF_FILE"
    benchmark_file "$PDF_FILE"
    summarize "${RESULTS_DIR}/$(basename "$PDF_FILE" .pdf)_benchmark.csv"
else
    # Batch mode - all PDFs in testdata
    [[ -d "$TESTDATA" ]] || error "Test data directory not found: $TESTDATA"

    pdf_files=("$TESTDATA"/*.pdf)
    [[ -f "${pdf_files[0]}" ]] || error "No PDF files found in $TESTDATA"

    log "Found ${#pdf_files[@]} PDF file(s)"

    for pdf in "${pdf_files[@]}"; do
        benchmark_file "$pdf"
    done

    # Summarize all results
    echo ""
    echo "=========================================="
    echo "         BENCHMARK RESULTS SUMMARY"
    echo "=========================================="

    for results_file in "$RESULTS_DIR"/*_benchmark.csv; do
        [[ -f "$results_file" ]] && summarize "$results_file"
    done
fi

log "Benchmark complete. Results in: $RESULTS_DIR"
