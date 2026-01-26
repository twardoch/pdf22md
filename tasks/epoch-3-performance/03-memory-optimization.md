# Task 3.3: Memory Optimization

## Problem

Processing large PDFs may consume excessive memory, especially with high DPI rasterization.

## Acceptance Criteria

- [ ] Profile memory usage for large PDFs (100+ pages)
- [ ] Identify memory hotspots
- [ ] Implement streaming/chunked processing
- [ ] Peak memory reduced by 50%+
- [ ] No OOM for 500+ page PDFs

## Strategies

1. **Page-by-page streaming**: Process and write one page at a time
2. **Image downsampling**: Reduce memory for intermediate images
3. **Autoreleasepool**: Proper memory management in loops
4. **Weak references**: Where applicable in caches

## Verification

```bash
# Monitor memory while processing large PDF
leaks --atExit -- ./pdf22md -i huge.pdf -o out.md
```

Expected: Stable memory usage regardless of PDF size.
