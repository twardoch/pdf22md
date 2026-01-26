# Task 5.2: Local LLM Support

## Problem

OpenAI requires internet and API costs. Local LLMs offer privacy and free usage.

## Acceptance Criteria

- [ ] Support Ollama API endpoint
- [ ] Support llama.cpp server endpoint
- [ ] Add `--ai-endpoint <url>` flag
- [ ] Auto-detect endpoint type
- [ ] Document setup instructions

## Implementation

### New CLI Flags
```
--ai-endpoint <url>   Custom AI endpoint (default: OpenAI)
--ai-model <name>     Model name for local LLM
```

### Endpoint Detection
- OpenAI: `api.openai.com` → use OpenAI client
- Ollama: `localhost:11434` → use Ollama format
- llama.cpp: `localhost:8080` → use OpenAI-compatible format

## Verification

```bash
# With Ollama
ollama serve &
pdf22md -i doc.pdf -o out.md --ai --ai-endpoint http://localhost:11434 --ai-model llama2

# With llama.cpp
./server -m model.gguf &
pdf22md -i doc.pdf -o out.md --ai --ai-endpoint http://localhost:8080
```

Expected: AI correction works with local models.
