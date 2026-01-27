# pdf22md v2.0 Roadmap

> **Goal**: Minimal viable product 2.0 — reliable, elegant, performant PDF to Markdown conversion.

## Status Overview

| Epoch | Focus | Status |
|-------|-------|--------|
| 1 | Foundation & Test Infrastructure | 🟡 Partial (CI done, xcode-select pending) |
| 2 | Code Refactoring & Splitting | 🟢 Complete |
| 3 | Performance & Parallelization | 🟡 Partial (benchmark done) |
| 4 | OCR & Vision Improvements | 🟢 Complete |
| 5 | AI Integration Enhancement | 🟢 Complete (V3 multi-pass) |
| 6 | CLI & UX Improvements | 🟡 Partial |
| 7 | Error Handling & Robustness | 🟡 Partial |
| 8 | Documentation & Examples | 🟡 Partial |
| 9 | Future Considerations | ⏸️ Deferred |

---

## Epoch 1: Foundation & Test Infrastructure

**Priority**: CRITICAL — Must complete before other epochs.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 1.1 | Fix XCTest module error | ⚠️ Manual | [01-fix-test-infrastructure.md](tasks/epoch-1-foundation/01-fix-test-infrastructure.md) |
| 1.2 | Add unit tests for core types | ✅ Done | [02-add-basic-unit-tests.md](tasks/epoch-1-foundation/02-add-basic-unit-tests.md) |
| 1.3 | Add integration tests with sample PDFs | 🔴 Pending | [03-add-integration-tests.md](tasks/epoch-1-foundation/03-add-integration-tests.md) |
| 1.4 | Setup GitHub Actions CI | ✅ Done | [04-setup-ci-pipeline.md](tasks/epoch-1-foundation/04-setup-ci-pipeline.md) |

**Note**: Task 1.1 requires manual intervention: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

---

## Epoch 2: Code Refactoring & Splitting

**Priority**: HIGH — Technical debt reduction, enables maintainability.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 2.1 | Split PDFMarkdownConverter.swift (393→199 lines) | ✅ Done | [01-split-pdf-markdown-converter.md](tasks/epoch-2-refactoring/01-split-pdf-markdown-converter.md) |
| 2.2 | Split PDFPageProcessor.swift (317→150 lines) | ✅ Done | [02-split-pdf-page-processor.md](tasks/epoch-2-refactoring/02-split-pdf-page-processor.md) |
| 2.3 | Split main.swift CLI (321 lines) | ⏸️ Deferred | [03-split-main-cli.md](tasks/epoch-2-refactoring/03-split-main-cli.md) |
| 2.4 | Consolidate converter variants | ✅ Done | [04-consolidate-converter-variants.md](tasks/epoch-2-refactoring/04-consolidate-converter-variants.md) |

**Note**: Task 2.3 deferred - async closure typing issues. Extracted FontAnalyzer, MarkdownGenerator, TextExtractor, VectorGraphicsExtractor. Removed OptimizedConverter and UltraOptimizedConverter variants.

---

## Epoch 3: Performance & Parallelization

**Priority**: MEDIUM — Measurable improvements for large documents.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 3.1 | Create benchmark framework | ✅ Done | [01-benchmark-framework.md](tasks/epoch-3-performance/01-benchmark-framework.md) |
| 3.2 | Optimize image extraction | 🔴 Pending | [02-optimize-image-extraction.md](tasks/epoch-3-performance/02-optimize-image-extraction.md) |
| 3.3 | Memory optimization for large PDFs | 🔴 Pending | [03-memory-optimization.md](tasks/epoch-3-performance/03-memory-optimization.md) |

**Note**: example.sh benchmark script created. VectorGraphicsExtractor O(n²) grid scanning is top performance issue.

---

## Epoch 4: OCR & Vision Improvements

**Priority**: HIGH — Core feature enhancement.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 4.1 | OCR result caching | ✅ Done | [01-ocr-result-caching.md](tasks/epoch-4-ocr/01-ocr-result-caching.md) |
| 4.2 | OCR accuracy tuning (languages, levels) | ✅ Done | [02-ocr-accuracy-tuning.md](tasks/epoch-4-ocr/02-ocr-accuracy-tuning.md) |
| 4.3 | OCR image preprocessing | 🔴 Pending | [03-ocr-preprocessing.md](tasks/epoch-4-ocr/03-ocr-preprocessing.md) |

**Note**: Cache at `~/.cache/pdf22md/ocr/`, `--no-cache` and `--languages` flags implemented.

---

## Epoch 5: AI Integration Enhancement

**Priority**: MEDIUM — User-requested features.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 5.1 | Custom AI prompt templates | ✅ Done | [01-custom-ai-prompts.md](tasks/epoch-5-ai/01-custom-ai-prompts.md) |
| 5.2 | Local LLM support (Ollama, llama.cpp) | 🔴 Pending | [02-local-llm-support.md](tasks/epoch-5-ai/02-local-llm-support.md) |
| 5.3 | AI text chunking for large documents | ✅ Done | [03-ai-chunking-strategy.md](tasks/epoch-5-ai/03-ai-chunking-strategy.md) |

**Note**: V3 multi-pass AI implemented with TextValidator (0.85 cosine threshold), ParagraphChunker (≤3500 chars), 3-pass pipeline (dehyphenation → OCR correction → cleanup). Word retention improved from 78% (V2) to 93% (V3).

---

## Epoch 6: CLI & UX Improvements

**Priority**: MEDIUM — Better user experience.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 6.1 | Progress reporting with ETA | 🟡 Partial | [01-progress-reporting.md](tasks/epoch-6-cli/01-progress-reporting.md) |
| 6.2 | Multiple output formats (HTML, plain, JSON) | 🔴 Pending | [02-output-format-options.md](tasks/epoch-6-cli/02-output-format-options.md) |
| 6.3 | Configuration file support | 🔴 Pending | [03-config-file-support.md](tasks/epoch-6-cli/03-config-file-support.md) |

**Note**: Basic progress via `-v`, batch mode progress (file X of Y). No ETA, no percentage.

---

## Epoch 7: Error Handling & Robustness

**Priority**: HIGH — Production reliability.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 7.1 | Error handling audit | 🔴 Pending | [01-error-handling-audit.md](tasks/epoch-7-robustness/01-error-handling-audit.md) |
| 7.2 | Graceful degradation for optional features | ✅ Done | [02-graceful-degradation.md](tasks/epoch-7-robustness/02-graceful-degradation.md) |
| 7.3 | Input validation improvements | 🟡 Partial | [03-input-validation.md](tasks/epoch-7-robustness/03-input-validation.md) |

**Note**: AI multi-provider failover, validation fallback implemented. DPI and job count validation done.

---

## Epoch 8: Documentation & Examples

**Priority**: MEDIUM — User adoption.

| Task | Description | Status | Link |
|------|-------------|--------|------|
| 8.1 | Comprehensive README update | ✅ Done | [01-comprehensive-readme.md](tasks/epoch-8-docs/01-comprehensive-readme.md) |
| 8.2 | API documentation (DocC) | 🔴 Pending | [02-api-documentation.md](tasks/epoch-8-docs/02-api-documentation.md) |
| 8.3 | Example scripts for common workflows | 🟡 Partial | [03-example-scripts.md](tasks/epoch-8-docs/03-example-scripts.md) |

**Note**: README has all CLI flags, troubleshooting, performance tips. example.sh exists for testing.

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

## Completed (v1.6.x → v1.7.0)

See [CHANGELOG.md](CHANGELOG.md) for completed work:
- ✅ Vision OCR integration with caching
- ✅ AI text correction V1, V2, V3 (OpenAI, Apple Intelligence)
- ✅ V3 Multi-pass AI: TextValidator, ParagraphChunker, PassPrompts, MultiPassProcessor
- ✅ Batch processing mode with parallel jobs
- ✅ Password-protected PDF support
- ✅ Consolidated single converter (removed Optimized/UltraOptimized variants)
- ✅ example.sh functional test script
- ✅ GitHub Actions CI workflow
- ✅ CLI consolidation (removed --optimized, --ultra-optimized flags)
- ✅ Code refactoring: FontAnalyzer, MarkdownGenerator, TextExtractor, VectorGraphicsExtractor
