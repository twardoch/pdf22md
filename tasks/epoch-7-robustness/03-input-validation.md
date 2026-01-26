# Task 7.3: Input Validation

## Problem

Invalid inputs may cause crashes or unexpected behavior.

## Acceptance Criteria

- [ ] Validate PDF file before processing
- [ ] Validate output path is writable
- [ ] Validate DPI range (1-1200)
- [ ] Validate job count (1-256)
- [ ] Clear error messages for invalid inputs

## Validation Checks

### File Validation
- Exists
- Is readable
- Is valid PDF (magic bytes: `%PDF-`)
- Page count > 0

### Path Validation
- Parent directory exists (or can be created)
- Not a directory
- Writable (test write + delete)

### Parameter Validation
```swift
guard (1...1200).contains(dpi) else {
    throw ValidationError("DPI must be between 1 and 1200")
}

guard (1...256).contains(jobs) else {
    throw ValidationError("Jobs must be between 1 and 256")
}
```

## Verification

Test with invalid inputs and verify clear error messages.
