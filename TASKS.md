# pdf22md v2.0 Roadmap

> **Goal**: Minimal viable product 2.0 — reliable, elegant, performant PDF to Markdown conversion.

## Status Overview

| Epoch | Focus | Status |
|-------|-------|--------|
| 1 | Foundation & Test Infrastructure | 🔴 Not Started |
| 2 | Code Refactoring & Splitting | 🔴 Not Started |
| 3 | Performance & Parallelization | 🔴 Not Started |
| 4 | OCR & Vision Improvements | 🔴 Not Started |
| 5 | AI Integration Enhancement | 🔴 Not Started |
| 6 | CLI & UX Improvements | 🔴 Not Started |
| 7 | Error Handling & Robustness | 🔴 Not Started |
| 8 | Documentation & Examples | 🔴 Not Started |
| 9 | Future Considerations | ⏸️ Deferred |

---

## Epoch 1: Foundation & Test Infrastructure

**Priority**: CRITICAL — Must complete before other epochs.

| Task | Description | Link |
|------|-------------|------|
| 1.1 | Fix XCTest module error | [01-fix-test-infrastructure.md](tasks/epoch-1-foundation/01-fix-test-infrastructure.md) |
| 1.2 | Add unit tests for core types | [02-add-basic-unit-tests.md](tasks/epoch-1-foundation/02-add-basic-unit-tests.md) |
| 1.3 | Add integration tests with sample PDFs | [03-add-integration-tests.md](tasks/epoch-1-foundation/03-add-integration-tests.md) |
| 1.4 | Setup GitHub Actions CI | [04-setup-ci-pipeline.md](tasks/epoch-1-foundation/04-setup-ci-pipeline.md) |

---

## Epoch 2: Code Refactoring & Splitting

**Priority**: HIGH — Technical debt reduction, enables maintainability.

| Task | Description | Link |
|------|-------------|------|
| 2.1 | Split PDFMarkdownConverter.swift (393 lines) | [01-split-pdf-markdown-converter.md](tasks/epoch-2-refactoring/01-split-pdf-markdown-converter.md) |
| 2.2 | Split PDFPageProcessor.swift (317 lines) | [02-split-pdf-page-processor.md](tasks/epoch-2-refactoring/02-split-pdf-page-processor.md) |
| 2.3 | Split main.swift CLI (321 lines) | [03-split-main-cli.md](tasks/epoch-2-refactoring/03-split-main-cli.md) |
| 2.4 | Consolidate converter variants | [04-consolidate-converter-variants.md](tasks/epoch-2-refactoring/04-consolidate-converter-variants.md) |

---

## Epoch 3: Performance & Parallelization

**Priority**: MEDIUM — Measurable improvements for large documents.

| Task | Description | Link |
|------|-------------|------|
| 3.1 | Create benchmark framework | [01-benchmark-framework.md](tasks/epoch-3-performance/01-benchmark-framework.md) |
| 3.2 | Optimize image extraction | [02-optimize-image-extraction.md](tasks/epoch-3-performance/02-optimize-image-extraction.md) |
| 3.3 | Memory optimization for large PDFs | [03-memory-optimization.md](tasks/epoch-3-performance/03-memory-optimization.md) |

---

## Epoch 4: OCR & Vision Improvements

**Priority**: HIGH — Core feature enhancement.

| Task | Description | Link |
|------|-------------|------|
| 4.1 | OCR result caching | [01-ocr-result-caching.md](tasks/epoch-4-ocr/01-ocr-result-caching.md) |
| 4.2 | OCR accuracy tuning (languages, levels) | [02-ocr-accuracy-tuning.md](tasks/epoch-4-ocr/02-ocr-accuracy-tuning.md) |
| 4.3 | OCR image preprocessing | [03-ocr-preprocessing.md](tasks/epoch-4-ocr/03-ocr-preprocessing.md) |

---

## Epoch 5: AI Integration Enhancement

**Priority**: MEDIUM — User-requested features.

| Task | Description | Link |
|------|-------------|------|
| 5.1 | Custom AI prompt templates | [01-custom-ai-prompts.md](tasks/epoch-5-ai/01-custom-ai-prompts.md) |
| 5.2 | Local LLM support (Ollama, llama.cpp) | [02-local-llm-support.md](tasks/epoch-5-ai/02-local-llm-support.md) |
| 5.3 | AI text chunking for large documents | [03-ai-chunking-strategy.md](tasks/epoch-5-ai/03-ai-chunking-strategy.md) |

---

## Epoch 6: CLI & UX Improvements

**Priority**: MEDIUM — Better user experience.

| Task | Description | Link |
|------|-------------|------|
| 6.1 | Progress reporting with ETA | [01-progress-reporting.md](tasks/epoch-6-cli/01-progress-reporting.md) |
| 6.2 | Multiple output formats (HTML, plain, JSON) | [02-output-format-options.md](tasks/epoch-6-cli/02-output-format-options.md) |
| 6.3 | Configuration file support | [03-config-file-support.md](tasks/epoch-6-cli/03-config-file-support.md) |

---

## Epoch 7: Error Handling & Robustness

**Priority**: HIGH — Production reliability.

| Task | Description | Link |
|------|-------------|------|
| 7.1 | Error handling audit | [01-error-handling-audit.md](tasks/epoch-7-robustness/01-error-handling-audit.md) |
| 7.2 | Graceful degradation for optional features | [02-graceful-degradation.md](tasks/epoch-7-robustness/02-graceful-degradation.md) |
| 7.3 | Input validation improvements | [03-input-validation.md](tasks/epoch-7-robustness/03-input-validation.md) |

---

## Epoch 8: Documentation & Examples

**Priority**: MEDIUM — User adoption.

| Task | Description | Link |
|------|-------------|------|
| 8.1 | Comprehensive README update | [01-comprehensive-readme.md](tasks/epoch-8-docs/01-comprehensive-readme.md) |
| 8.2 | API documentation (DocC) | [02-api-documentation.md](tasks/epoch-8-docs/02-api-documentation.md) |
| 8.3 | Example scripts for common workflows | [03-example-scripts.md](tasks/epoch-8-docs/03-example-scripts.md) |

---

## Epoch 9: Future Considerations

**Priority**: LOW — Post-MVP, based on user demand.

| Task | Description | Link |
|------|-------------|------|
| 9.1 | Web interface | [01-web-interface.md](tasks/epoch-9-future/01-web-interface.md) |
| 9.2 | Table detection | [02-table-detection.md](tasks/epoch-9-future/02-table-detection.md) |
| 9.3 | Linux support | [03-linux-support.md](tasks/epoch-9-future/03-linux-support.md) |

---

## Dependencies

```
Epoch 1 (Foundation)
    ↓
Epoch 2 (Refactoring) ← Requires passing tests
    ↓
┌───┴───┬───────┬───────┐
↓       ↓       ↓       ↓
Epoch 3 Epoch 4 Epoch 5 Epoch 7
(Perf)  (OCR)   (AI)    (Robust)
└───┬───┴───────┴───────┘
    ↓
Epoch 6 (CLI) ← Depends on stable features
    ↓
Epoch 8 (Docs) ← Depends on stable API
    ↓
Epoch 9 (Future) ← Post-MVP
```

---

## Completed (v1.6.x)

See [CHANGELOG.md](CHANGELOG.md) for completed work:
- ✅ Vision OCR integration
- ✅ AI text correction (OpenAI, Apple Intelligence)
- ✅ Batch processing mode
- ✅ Password-protected PDF support
- ✅ Three converter engines (async, GCD, ultra-optimized)
- ✅ example.sh functional test script
