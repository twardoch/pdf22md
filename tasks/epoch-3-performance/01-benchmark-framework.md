# Task 3.1: Create Benchmark Framework

## Problem

No systematic way to measure and compare performance across converter variants.

## Acceptance Criteria

- [ ] Benchmark script that measures all 4 methods
- [ ] Measures: total time, per-page time, memory usage
- [ ] Uses standardized test PDFs
- [ ] Outputs comparison table
- [ ] Runs as part of CI (optional gate)

## Implementation

### benchmark.sh
```bash
#!/bin/bash
# Benchmark all converter methods
for method in fast standard optimized ultra-optimized; do
    time pdf22md -i large.pdf -o /dev/null --$method
done
```

### Metrics to Capture
- Wall clock time
- CPU time (user + system)
- Peak memory usage
- Pages per second

## Verification

```bash
./benchmark.sh testdata/large.pdf
```

Expected: Table showing relative performance of each method.
