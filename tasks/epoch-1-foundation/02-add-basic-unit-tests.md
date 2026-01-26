# Task 1.2: Add Basic Unit Tests

## Problem

Limited test coverage. Need tests for core data structures and utilities.

## Acceptance Criteria

- [ ] Tests for `PDFElement` types (TextElement, ImageElement)
- [ ] Tests for `ProcessingOptions` creation and defaults
- [ ] Tests for `FontStatistics` calculations
- [ ] Tests for error types and cases

## Scope

Focus on unit tests for pure functions and data structures. Skip integration tests requiring actual PDF files for now.

## Test Cases

1. `TextElement` creation with various font sizes
2. `ProcessingOptions` default values verification
3. `FontStatistics` heading detection algorithm
4. Error case construction and descriptions

## Verification

```bash
swift test --filter PDF22MDTests
```

Expected: All new unit tests pass.
