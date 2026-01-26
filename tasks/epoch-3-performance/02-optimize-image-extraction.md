# Task 3.2: Optimize Image Extraction

## Problem

Image extraction may be slow for PDFs with many images. Potential for parallelization.

## Acceptance Criteria

- [ ] Profile image extraction performance
- [ ] Identify bottlenecks (I/O vs CPU)
- [ ] Parallelize image processing if beneficial
- [ ] Reduce memory footprint for large images
- [ ] No quality degradation

## Potential Optimizations

1. **Parallel XObject extraction**: Process multiple images concurrently
2. **Lazy loading**: Don't decode until needed
3. **Streaming writes**: Write to disk progressively
4. **Memory pooling**: Reuse CGContext buffers

## Verification

```bash
./benchmark.sh testdata/image_heavy.pdf
```

Expected: Image extraction 2x faster for image-heavy PDFs.
