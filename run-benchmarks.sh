#!/bin/bash

set -e

echo "==================================="
echo "PDF22MD Performance Benchmark Suite"
echo "==================================="
echo

# Build both implementations
echo "Building Objective-C implementation..."
make clean && make
echo

echo "Building Swift implementation..."
cd swift
swift build -c release
cd ..
echo

# Create test PDFs if they don't exist
mkdir -p test
if [ ! -f "test/small.pdf" ]; then
    echo "Creating test PDFs..."
    # You'll need to add actual test PDFs here
    echo "Please add test PDFs to the test/ directory:"
    echo "  - small.pdf (1-10 pages)"
    echo "  - medium.pdf (50-100 pages)"
    echo "  - large.pdf (200+ pages)"
    echo "  - images.pdf (image-heavy document)"
    exit 1
fi

# Run detailed benchmarks
echo "Running detailed benchmarks..."
echo

# Function to measure execution time and memory
benchmark_impl() {
    local impl=$1
    local pdf=$2
    local name=$3
    
    echo "Testing $impl with $name PDF..."
    
    # Measure time and memory
    if [ "$impl" = "objc" ]; then
        /usr/bin/time -l ./pdf22md -i "$pdf" -o /tmp/bench-output.md -a /tmp/bench-assets 2>&1 | \
        grep -E "real|maximum resident set size" | \
        awk '/real/ {print "Time: " $1} /maximum resident/ {print "Memory: " $1/1048576 " MB"}'
    else
        /usr/bin/time -l ./swift/.build/release/pdf22md-swift -i "$pdf" -o /tmp/bench-output.md -a /tmp/bench-assets 2>&1 | \
        grep -E "real|maximum resident set size" | \
        awk '/real/ {print "Time: " $1} /maximum resident/ {print "Memory: " $1/1048576 " MB"}'
    fi
    
    # Count output
    if [ -f /tmp/bench-output.md ]; then
        echo "Output size: $(wc -c < /tmp/bench-output.md) bytes"
        echo "Line count: $(wc -l < /tmp/bench-output.md) lines"
    fi
    
    # Clean up
    rm -rf /tmp/bench-output.md /tmp/bench-assets
    echo
}

# Test each PDF with both implementations
for pdf in test/*.pdf; do
    if [ -f "$pdf" ]; then
        name=$(basename "$pdf" .pdf)
        echo "=== $name.pdf ==="
        benchmark_impl "objc" "$pdf" "$name"
        benchmark_impl "swift" "$pdf" "$name"
        echo
    fi
done

# Run concurrent processing test
echo "=== Concurrent Processing Test ==="
echo "Processing multiple PDFs simultaneously..."

# ObjC concurrent test
echo "Objective-C (using parallel):"
time find test -name "*.pdf" -print0 | \
    xargs -0 -P 4 -I {} ./pdf22md -i {} -o /tmp/objc-{}.md

echo
echo "Swift (native concurrency):"
time find test -name "*.pdf" -print0 | \
    xargs -0 -P 4 -I {} ./swift/.build/release/pdf22md-swift -i {} -o /tmp/swift-{}.md

# Clean up
rm -f /tmp/objc-*.md /tmp/swift-*.md

echo
echo "=== Summary ==="
echo "Benchmark complete. Key metrics to compare:"
echo "1. Processing time (real time)"
echo "2. Memory usage (maximum resident set size)"
echo "3. Output accuracy (file sizes should match)"
echo "4. Concurrent processing efficiency"

# If swift-benchmark is installed, run detailed benchmarks
if command -v swift-benchmark &> /dev/null; then
    echo
    echo "Running detailed Swift benchmarks..."
    cd benchmarks
    swift run -c release
fi