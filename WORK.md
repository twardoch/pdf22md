# Work Progress

## Current Session

### Completed: example.sh conversion test script

Created `example.sh` that converts all PDFs in `testdata/pdf/` using 4 methods:
- **fast**: PDF text only (no OCR)
- **standard**: Vision OCR (default)
- **optimized**: GCD-optimized engine
- **ultra**: Ultra-optimized NSString engine

Results stored in `testdata/{method}/` directories with assets.

**Test Results:**
- test.pdf: Works in all 4 modes
- jlmp.pdf: Works in optimized/ultra modes
- bloo/frut/gard.pdf: Work but need >60s timeout for full processing

**Script Features:**
- Configurable timeout via `TIMEOUT` env var (default 120s)
- Filters noisy debug output
- Shows summary of files generated
