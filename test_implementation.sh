#!/bin/bash

echo "Testing pdf22md implementation..."

# Create test output directory
mkdir -p test_output

# Test 1: Without assets (text only)
echo "Test 1: Text extraction without assets..."
./pdf22md/pdf22md -i pdf22md/test-resources/pdfs/README.pdf -o test_output/test1.md

# Test 2: With assets  
echo "Test 2: Text and image extraction with assets..."
./pdf22md/pdf22md -i pdf22md/test-resources/pdfs/README.pdf -o test_output/test2.md -a test_output/assets2

# Test 3: Check asset naming
echo "Test 3: Checking asset naming convention..."
./pdf22md/pdf22md -i pdf22md/test-resources/pdfs/digitallegacies-twardoch2018.pdf -o test_output/test3.md -a test_output/assets3

echo "Tests completed. Check test_output directory for results."
echo ""
echo "Expected behavior:"
echo "- test1.md should contain only text (no image references)"
echo "- test2.md should contain text and image references"
echo "- assets2/ should contain images named README-XXX-YY.ext"
echo "- assets3/ should contain images named digitallegacies-twardoch2018-XXX-YY.ext"