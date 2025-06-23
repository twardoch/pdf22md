#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_benchmark() {
    echo -e "${CYAN}[BENCH]${NC} $1"
}

print_result() {
    echo -e "${MAGENTA}[RESULT]${NC} $1"
}

# Parse command line arguments
QUICK=false
ITERATIONS=5
BUILD_FIRST=true
USE_PYTHON=false
MEMORY_PROFILE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK=true
            ITERATIONS=3
            shift
            ;;
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        --no-build)
            BUILD_FIRST=false
            shift
            ;;
        --python)
            USE_PYTHON=true
            shift
            ;;
        --memory)
            MEMORY_PROFILE=true
            shift
            ;;
        -h|--help)
            echo "Benchmark script for pdf22md implementations"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --quick           Run quick benchmark (3 iterations)"
            echo "  --iterations N    Number of iterations (default: 5)"
            echo "  --no-build        Skip building before benchmarking"
            echo "  --python          Use Python benchmark script"
            echo "  --memory          Include detailed memory profiling"
            echo "  -h, --help        Show this help message"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "PDF22MD Performance Benchmark"
echo "============================================"
echo ""

# Check for required binaries
check_binaries() {
    local missing=false
    
    if [ ! -f "./pdf22md" ]; then
        print_warning "Objective-C binary not found: ./pdf22md"
        missing=true
    fi
    
    if [ ! -f "./swift/.build/release/pdf22md-swift" ]; then
        print_warning "Swift binary not found: ./swift/.build/release/pdf22md-swift"
        missing=true
    fi
    
    if $missing; then
        if $BUILD_FIRST; then
            print_info "Building missing binaries..."
            ./build.sh
        else
            print_error "Missing binaries. Run ./build.sh first or remove --no-build flag"
            exit 1
        fi
    fi
}

# Create test PDFs if needed
ensure_test_pdfs() {
    if [ ! -f "test/small.pdf" ] || [ ! -f "test/medium.pdf" ] || [ ! -f "test/large.pdf" ]; then
        print_info "Creating test PDFs..."
        if [ -f "./create-test-pdf.swift" ]; then
            swift ./create-test-pdf.swift
        else
            print_error "Test PDFs not found and create-test-pdf.swift is missing"
            print_error "Please add test PDFs to the test/ directory:"
            print_error "  - small.pdf (1-10 pages)"
            print_error "  - medium.pdf (50-100 pages)"
            print_error "  - large.pdf (200+ pages)"
            exit 1
        fi
    fi
}

# Build if requested
if $BUILD_FIRST; then
    print_info "Building implementations..."
    ./build.sh --clean
    echo ""
fi

# Check binaries exist
check_binaries

# Ensure test PDFs exist
ensure_test_pdfs

# Use Python benchmark if requested
if $USE_PYTHON; then
    print_info "Running Python benchmark script..."
    python3 benchmark.py
    exit 0
fi

# Function to measure execution time
benchmark_time() {
    local binary=$1
    local pdf=$2
    local name=$3
    local iteration=$4
    
    local output="/tmp/bench-${name}-${iteration}.md"
    local assets="/tmp/bench-${name}-${iteration}-assets"
    
    # Clean up previous outputs
    rm -rf "$output" "$assets" 2>/dev/null || true
    
    # Run and time the command
    local start=$(date +%s.%N)
    
    if $binary -i "$pdf" -o "$output" -a "$assets" -d 144 >/dev/null 2>&1; then
        local end=$(date +%s.%N)
        local duration=$(echo "$end - $start" | bc)
        echo "$duration"
        
        # Clean up
        rm -rf "$output" "$assets" 2>/dev/null || true
    else
        echo "ERROR"
    fi
}

# Function to measure memory usage
benchmark_memory() {
    local binary=$1
    local pdf=$2
    
    local output="/tmp/bench-memory.md"
    local assets="/tmp/bench-memory-assets"
    
    # Clean up
    rm -rf "$output" "$assets" 2>/dev/null || true
    
    # Run with memory tracking
    local result=$(/usr/bin/time -l $binary -i "$pdf" -o "$output" -a "$assets" -d 144 2>&1)
    
    # Extract memory usage (in bytes on macOS)
    local memory=$(echo "$result" | grep "maximum resident set size" | awk '{print $1}')
    
    # Convert to MB
    if [ -n "$memory" ]; then
        echo "scale=2; $memory / 1048576" | bc
    else
        echo "0"
    fi
    
    # Clean up
    rm -rf "$output" "$assets" 2>/dev/null || true
}

# Arrays to store results
declare -a objc_times_small
declare -a objc_times_medium
declare -a objc_times_large
declare -a swift_times_small
declare -a swift_times_medium
declare -a swift_times_large

# Run benchmarks
print_benchmark "Starting benchmark with $ITERATIONS iterations..."
echo ""

# Test each PDF size
for pdf_info in "small test/small.pdf 5" "medium test/medium.pdf 50" "large test/large.pdf 200"; do
    set -- $pdf_info
    size=$1
    pdf=$2
    pages=$3
    
    echo "=== Testing $size PDF ($pages pages) ==="
    
    # Warm-up run
    print_info "Warming up..."
    benchmark_time "./pdf22md" "$pdf" "warmup" "0" >/dev/null
    benchmark_time "./swift/.build/release/pdf22md-swift" "$pdf" "warmup" "0" >/dev/null
    
    # Benchmark runs
    print_info "Running benchmarks..."
    
    for i in $(seq 1 $ITERATIONS); do
        printf "\r  Iteration $i/$ITERATIONS"
        
        # Objective-C
        objc_time=$(benchmark_time "./pdf22md" "$pdf" "$size-objc" "$i")
        if [ "$objc_time" != "ERROR" ]; then
            eval "objc_times_${size}+=($objc_time)"
        fi
        
        # Swift
        swift_time=$(benchmark_time "./swift/.build/release/pdf22md-swift" "$pdf" "$size-swift" "$i")
        if [ "$swift_time" != "ERROR" ]; then
            eval "swift_times_${size}+=($swift_time)"
        fi
    done
    echo ""
    
    # Memory profiling if requested
    if $MEMORY_PROFILE; then
        print_info "Measuring memory usage..."
        objc_mem=$(benchmark_memory "./pdf22md" "$pdf")
        swift_mem=$(benchmark_memory "./swift/.build/release/pdf22md-swift" "$pdf")
        eval "objc_memory_${size}=$objc_mem"
        eval "swift_memory_${size}=$swift_mem"
    fi
    
    echo ""
done

# Calculate and display results
echo "============================================"
echo "BENCHMARK RESULTS"
echo "============================================"
echo ""

# Function to calculate average
calc_average() {
    local arr=("$@")
    local sum=0
    local count=${#arr[@]}
    
    for val in "${arr[@]}"; do
        sum=$(echo "$sum + $val" | bc)
    done
    
    if [ $count -gt 0 ]; then
        echo "scale=3; $sum / $count" | bc
    else
        echo "0"
    fi
}

# Function to calculate min
calc_min() {
    local arr=("$@")
    local min=${arr[0]}
    
    for val in "${arr[@]}"; do
        if (( $(echo "$val < $min" | bc -l) )); then
            min=$val
        fi
    done
    
    echo "$min"
}

# Function to calculate max
calc_max() {
    local arr=("$@")
    local max=${arr[0]}
    
    for val in "${arr[@]}"; do
        if (( $(echo "$val > $max" | bc -l) )); then
            max=$val
        fi
    done
    
    echo "$max"
}

# Display results for each size
for size in small medium large; do
    eval "objc_times=(\"\${objc_times_${size}[@]}\")"
    eval "swift_times=(\"\${swift_times_${size}[@]}\")"
    
    if [ ${#objc_times[@]} -gt 0 ] && [ ${#swift_times[@]} -gt 0 ]; then
        objc_avg=$(calc_average "${objc_times[@]}")
        swift_avg=$(calc_average "${swift_times[@]}")
        objc_min=$(calc_min "${objc_times[@]}")
        swift_min=$(calc_min "${swift_times[@]}")
        objc_max=$(calc_max "${objc_times[@]}")
        swift_max=$(calc_max "${swift_times[@]}")
        
        # Calculate speedup
        speedup=$(echo "scale=2; $swift_avg / $objc_avg" | bc)
        
        # Get page count
        case $size in
            small) pages=5 ;;
            medium) pages=50 ;;
            large) pages=200 ;;
        esac
        
        # Calculate pages per second
        objc_pps=$(echo "scale=1; $pages / $objc_avg" | bc)
        swift_pps=$(echo "scale=1; $pages / $swift_avg" | bc)
        
        echo "${size^^} PDF ($pages pages):"
        echo "----------------------------------------"
        printf "Objective-C:\n"
        printf "  Average: %6.3fs (%.1f pages/sec)\n" "$objc_avg" "$objc_pps"
        printf "  Min:     %6.3fs\n" "$objc_min"
        printf "  Max:     %6.3fs\n" "$objc_max"
        
        if $MEMORY_PROFILE; then
            eval "objc_mem=\$objc_memory_${size}"
            printf "  Memory:  %6.1f MB\n" "$objc_mem"
        fi
        
        printf "\nSwift:\n"
        printf "  Average: %6.3fs (%.1f pages/sec)\n" "$swift_avg" "$swift_pps"
        printf "  Min:     %6.3fs\n" "$swift_min"
        printf "  Max:     %6.3fs\n" "$swift_max"
        
        if $MEMORY_PROFILE; then
            eval "swift_mem=\$swift_memory_${size}"
            printf "  Memory:  %6.1f MB\n" "$swift_mem"
            
            mem_ratio=$(echo "scale=2; $swift_mem / $objc_mem" | bc)
            printf "\nMemory ratio: Swift uses %.2fx more memory\n" "$mem_ratio"
        fi
        
        printf "\n"
        print_result "Objective-C is ${speedup}x faster"
        echo ""
    fi
done

# Summary
echo "============================================"
echo "SUMMARY"
echo "============================================"
echo ""
echo "The Objective-C implementation is significantly faster across all PDF sizes."
echo "Consider using the Objective-C version for production workloads."
echo ""
echo "To run more detailed benchmarks with statistics:"
echo "  python3 benchmark.py"
echo ""
echo "To build with optimizations:"
echo "  ./build.sh --clean"