# Task 1.3: Add Integration Tests

## Problem

No automated tests for end-to-end PDF conversion workflow.

## Acceptance Criteria

- [ ] Test with simple text-only PDF
- [ ] Test with PDF containing images
- [ ] Test with empty/minimal PDF
- [ ] Tests use sample files from testdata/

## Test Cases

1. Convert text PDF → verify markdown output contains expected content
2. Convert image PDF → verify image references in markdown
3. Convert empty PDF → verify graceful handling
4. Convert multi-page PDF → verify page ordering

## Sample Data

Use existing files in `testdata/` directory:
- `pdf_textonly.pdf`
- `pdf_images.pdf`
- Any other available test PDFs

## Verification

```bash
swift test --filter Integration
```

Expected: Integration tests pass with sample PDFs.
