# Task 4.1: OCR Result Caching

## Problem

Vision OCR is slow. Re-processing the same PDF wastes time. Pending from v1.6.0.

## Acceptance Criteria

- [ ] Cache OCR results to disk
- [ ] Cache key based on PDF content hash + page number
- [ ] Configurable cache location
- [ ] Cache invalidation on PDF change
- [ ] Optional `--no-cache` flag

## Cache Design

```
~/.cache/pdf22md/
└── ocr/
    └── {pdf_sha256}/
        ├── page_001.txt
        ├── page_002.txt
        └── metadata.json
```

### metadata.json
```json
{
  "pdf_hash": "abc123...",
  "created": "2025-01-26T12:00:00Z",
  "pdf_path": "/path/to/original.pdf",
  "pages": 10
}
```

## Verification

```bash
# First run (slow)
time pdf22md -i scanned.pdf -o out.md

# Second run (fast, cached)
time pdf22md -i scanned.pdf -o out.md
```

Expected: Second run 10x faster (skips OCR).
