# Task 2.3: Split main.swift CLI

## Problem

`main.swift` is 321 lines. Mixes argument parsing with processing logic.

## Acceptance Criteria

- [ ] Extract `ProcessingOptionsBuilder` struct
- [ ] Extract batch processing logic to separate function
- [ ] `main.swift` reduced to <150 lines
- [ ] CLI behavior unchanged
- [ ] All tests pass

## Extraction Plan

### ProcessingOptionsBuilder.swift (~80 lines)
- Build `ProcessingOptions` from CLI args
- Validation logic
- Default handling

### BatchProcessor.swift (~100 lines)
- Batch mode file discovery
- Parallel job coordination
- Progress reporting

### main.swift (~150 lines)
- ArgumentParser command definition
- Entry point routing
- Single file vs batch dispatch

## Verification

```bash
swift build -c release
./pdf22md/.build/release/pdf22md --help
./example.sh -q
```

Expected: Help output unchanged, all processing modes work.
