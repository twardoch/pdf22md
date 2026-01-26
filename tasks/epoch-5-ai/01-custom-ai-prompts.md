# Task 5.1: Custom AI Prompt Templates

## Problem

AI text correction uses hardcoded prompts. Users may want customization. Pending from v1.6.0.

## Acceptance Criteria

- [ ] Support custom prompt templates
- [ ] Template file location: `~/.config/pdf22md/prompts/`
- [ ] Built-in default templates
- [ ] Add `--ai-prompt <name>` flag
- [ ] Document template format

## Template System

### Template Location
```
~/.config/pdf22md/prompts/
├── default.txt
├── academic.txt
├── legal.txt
└── custom.txt
```

### Template Format
```
You are an OCR text correction assistant.

Input text may contain:
- OCR errors
- Formatting issues
- {{CUSTOM_INSTRUCTIONS}}

Please correct the following text:
---
{{TEXT}}
---
```

### CLI Usage
```bash
pdf22md -i doc.pdf -o out.md --ai --ai-prompt academic
```

## Verification

Test with different prompt templates and verify output quality.
