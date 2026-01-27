# pdf22md Roadmap

> See [CHANGELOG.md](CHANGELOG.md) for completed work and [TODO.md](TODO.md) for actionable items.

## Current Version: v1.7.0

### Completed Features

- Vision OCR integration with result caching
- AI text correction V3 (multi-pass with validation)
- Batch processing with parallel jobs
- Password-protected PDF support
- Progress bar with ETA
- Dry-run mode for previewing conversions
- Consolidated single converter architecture

### Next Focus Areas

1. **Performance** - VectorGraphicsExtractor optimization, memory profiling
2. **Output Formats** - HTML, plain text, JSON output options
3. **Local AI** - Ollama/llama.cpp support for offline processing
4. **Configuration** - TOML config file support

### Future Considerations

- Web interface (post-MVP, based on demand)
- Table detection algorithms
- Linux support (requires alternative to Vision framework)
