# Task 6.3: Configuration File Support

## Problem

Repeating same flags is tedious. Users want persistent defaults.

## Acceptance Criteria

- [ ] Support config file at `~/.config/pdf22md/config.toml`
- [ ] CLI flags override config values
- [ ] Document all config options
- [ ] Add `--config <path>` for custom location

## Config Format

```toml
# ~/.config/pdf22md/config.toml

[output]
dpi = 150
format = "markdown"

[processing]
engine = "optimized"
jobs = 4

[ai]
enabled = false
endpoint = "https://api.openai.com/v1"
model = "gpt-4o-mini"

[ocr]
languages = ["en"]
level = "accurate"
cache = true
```

## Priority Order

1. CLI flags (highest)
2. Environment variables
3. Config file
4. Built-in defaults (lowest)

## Verification

```bash
# Create config
mkdir -p ~/.config/pdf22md
echo '[output]\ndpi = 200' > ~/.config/pdf22md/config.toml

# Use defaults
pdf22md -i doc.pdf -o out.md  # Uses DPI 200

# Override
pdf22md -i doc.pdf -o out.md -d 72  # Uses DPI 72
```
