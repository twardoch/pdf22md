#!/bin/bash

# pdf22md Test Runner
# Compiles and runs unit tests for the pdf22md project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 pdf22md Test Suite${NC}"
echo "=================================="

# Create build directory for tests
TEST_BUILD_DIR="build/tests"
mkdir -p "$TEST_BUILD_DIR"

# Compile flags
CFLAGS="-Wall -Wextra -O2 -fobjc-arc"
FRAMEWORKS="-framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework XCTest"
INCLUDES="-I./src"

echo -e "${YELLOW}📦 Compiling test framework...${NC}"

# Function to compile and run a test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .m)
    local executable="$TEST_BUILD_DIR/$test_name"
    
    echo -e "  ${YELLOW}Building${NC} $test_name..."
    
    # Compile the test
    if clang $CFLAGS $FRAMEWORKS $INCLUDES \
        "$test_file" \
        src/Core/*.m \
        src/Models/*.m \
        src/Services/*.m \
        -o "$executable" 2>/dev/null; then
        
        echo -e "  ${GREEN}✓${NC} Compiled $test_name"
        
        # Run the test
        echo -e "  ${YELLOW}Running${NC} $test_name..."
        if "$executable" 2>/dev/null; then
            echo -e "  ${GREEN}✓ PASSED${NC} $test_name"
            return 0
        else
            echo -e "  ${RED}✗ FAILED${NC} $test_name"
            return 1
        fi
    else
        echo -e "  ${RED}✗ COMPILE FAILED${NC} $test_name"
        return 1
    fi
}

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "\n${YELLOW}🔬 Running Unit Tests...${NC}"

# Run unit tests
for test_file in Tests/Unit/*.m; do
    if [ -f "$test_file" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "$test_file"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        echo
    fi
done

echo -e "${YELLOW}🔬 Running Integration Tests...${NC}"

# Run integration tests
for test_file in Tests/Integration/*.m; do
    if [ -f "$test_file" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if run_test "$test_file"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        echo
    fi
done

# Summary
echo "=================================="
echo -e "${YELLOW}📊 Test Summary${NC}"
echo "Total Tests:  $TOTAL_TESTS"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
else
    echo -e "Failed:       ${GREEN}0${NC}"
    echo -e "\n${GREEN}✅ All tests passed!${NC}"
    exit 0
fi