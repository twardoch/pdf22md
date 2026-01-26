# Task 2.4: Consolidate Converter Variants

## Problem

Three converter files with duplicated logic:
- `PDFMarkdownConverter.swift` (async/await)
- `PDFMarkdownConverterOptimized.swift` (GCD)
- `PDFMarkdownConverterUltraOptimized.swift` (NSString)

## Acceptance Criteria

- [ ] Identify shared logic between converters
- [ ] Extract common code to base protocol/struct
- [ ] Reduce duplication by 50%+
- [ ] Keep performance characteristics of each variant
- [ ] All tests pass

## Strategy

Option A: Protocol-based polymorphism
- `PDFConverterProtocol` with common interface
- Variant-specific implementations

Option B: Strategy pattern
- Common converter with pluggable execution strategy
- `ExecutionStrategy` enum: `.async`, `.gcd`, `.ultraOptimized`

Option C: Keep separate but share utilities
- Extract shared utilities to `ConverterUtils.swift`
- Minimize code in each variant

## Verification

```bash
./example.sh  # Tests all 4 methods
```

Expected: All methods produce identical output, performance preserved.
