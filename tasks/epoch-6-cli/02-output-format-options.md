# Task 6.2: Output Format Options

## Problem

Only Markdown output supported. Some users may want other formats.

## Acceptance Criteria

- [ ] Add `--format` flag with options
- [ ] Support: markdown (default), html, plain
- [ ] HTML output with proper structure
- [ ] Plain text strips all formatting
- [ ] JSON output for programmatic use

## Implementation

### CLI Flag
```
--format <format>   Output format: markdown, html, plain, json
```

### Output Generators
- `MarkdownGenerator` (existing)
- `HTMLGenerator` (new)
- `PlainTextGenerator` (new)
- `JSONGenerator` (new)

### HTML Structure
```html
<!DOCTYPE html>
<html>
<head><title>{filename}</title></head>
<body>
  <h1>Title</h1>
  <p>Content...</p>
  <img src="image.png" />
</body>
</html>
```

## Verification

```bash
pdf22md -i doc.pdf -o out.html --format html
pdf22md -i doc.pdf -o out.txt --format plain
pdf22md -i doc.pdf -o out.json --format json
```
