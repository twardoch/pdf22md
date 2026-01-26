# Task 5.3: AI Text Chunking Strategy

## Problem

Large documents may exceed LLM context limits. Need intelligent chunking.

## Acceptance Criteria

- [ ] Detect context limit based on model
- [ ] Chunk text by pages or paragraphs
- [ ] Maintain coherence across chunks
- [ ] Reassemble corrected text properly
- [ ] Handle partial failures gracefully

## Chunking Algorithm

1. Calculate approximate token count
2. If within limit → single request
3. If exceeds → split by natural boundaries:
   - Page breaks (preferred)
   - Paragraph breaks
   - Sentence breaks (last resort)
4. Process chunks with overlap for context
5. Deduplicate overlapping corrections

## Configuration

```swift
struct ChunkingConfig {
    let maxTokens: Int = 8000
    let overlapTokens: Int = 200
    let preferPageBoundaries: Bool = true
}
```

## Verification

Process 100+ page document and verify no content loss or duplication.
