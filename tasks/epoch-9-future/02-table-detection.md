# Task 9.2: Table Detection (Future)

## Problem

Tables in PDFs are converted as plain text. Markdown tables would be better.

## Scope

This is a **future consideration**, not MVP 2.0 scope.

## Challenges

- Table detection is complex
- No native support in PDFKit
- Multiple table formats exist
- May require ML models

## Potential Approaches

1. **Heuristic detection**: Grid lines, column alignment
2. **Vision-based**: Use VNDetectRectanglesRequest
3. **ML-based**: Train/use table detection model
4. **Third-party**: Integrate existing table extraction library

## Output Format

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
```

## Notes

Research existing solutions before implementing.
