# Work Progress

## v1.6.0 Release Ready

All core features complete. Ready to push with `git push origin main`.

## Benchmark Results (example.sh -q)

| Method | Speed | Size | Notes |
|--------|-------|------|-------|
| ultra | 0-1s | 80K | Fastest, NSString-based |
| optimized | 0-1s | 7.1M | GCD-based, with images |
| standard | 3-400s | 20M | Full Vision OCR |
| fast | 0s | 20M | PDF text only |

Test PDFs: bloo.pdf, frut.pdf, gard.pdf, jlmp.pdf, scan.pdf, test.pdf
