# Task 6.1: Progress Reporting

## Problem

No feedback during long conversions. Users don't know if it's working.

## Acceptance Criteria

- [ ] Show progress bar for multi-page PDFs
- [ ] Display current page / total pages
- [ ] Show elapsed time and ETA
- [ ] Quiet mode suppresses progress
- [ ] Works with batch mode

## Implementation

### Progress Format
```
Processing: document.pdf
[████████████░░░░░░░░] 60% (30/50 pages) ETA: 12s
```

### Batch Progress
```
Batch: 3/10 files
Current: report.pdf [████████░░░░░░░░░░░░] 40% (8/20 pages)
```

## Verification

```bash
pdf22md -i large.pdf -o out.md  # Shows progress
pdf22md -i large.pdf -o out.md -q  # Silent
```

Expected: Real-time progress updates in terminal.
