# Task 4.3: OCR Image Preprocessing

## Problem

Poor quality scans may produce bad OCR results. Preprocessing can improve accuracy.

## Acceptance Criteria

- [ ] Implement optional image preprocessing pipeline
- [ ] Deskew detection and correction
- [ ] Contrast enhancement for faded text
- [ ] Noise reduction for grainy scans
- [ ] Add `--ocr-preprocess` flag

## Preprocessing Steps

1. **Grayscale conversion**: Simplify for OCR
2. **Binarization**: Adaptive thresholding
3. **Deskew**: Detect and correct rotation
4. **Denoise**: Remove speckles
5. **Contrast**: Normalize histogram

## Implementation

Use Core Image filters:
- `CIColorControls` for contrast
- `CIAffineTransform` for deskew
- `CINoiseReduction` for denoising

## Verification

Compare OCR accuracy on same document with/without preprocessing.
