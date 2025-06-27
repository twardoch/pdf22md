# PDF to Markdown Converter - Implementation Tasks

## Phase 1: Conditional Asset Processing
- [x] Update PDFMarkdownConverter to pass assets path to PDFPageProcessor
- [x] Modify PDFPageProcessor.processPage() to skip image extraction when assetsPath is nil
- [x] Update AssetExtractor init to only create directory when assetsPath is provided
- [x] Update PDFMarkdownConverterOptimized to pass assetsPath
- [x] Update PDFPageProcessorOptimized to conditionally extract images
- [x] Update PDFMarkdownConverterUltraOptimized to pass assetsPath
- [ ] Test that no image processing occurs when -a flag is not provided

## Phase 2: Asset Naming Updates
- [x] Add pdfBasename parameter to AssetExtractor initializer
- [x] Update AssetExtractor.saveImage to use new naming format: `basename-pagenum-assetnum.ext`
- [x] Implement 3-digit zero-padding for page numbers
- [x] Implement 2-digit zero-padding for asset numbers per page
- [x] Reset asset counter for each page (using pageImageCounts dictionary)
- [x] Update PDFMarkdownConverter to extract basename from PDF URL
- [x] Pass basename and page index to AssetExtractor
- [x] Update PDFMarkdownConverterOptimized to use new AssetExtractor API

## Phase 3: XObject Image Extraction
- [x] Create new extractXObjectImages method in CGPDFImageExtractor
- [x] Implement CGPDFPage dictionary navigation (Page → Resources → XObject)
- [x] Add CGPDFDictionaryApplyBlock to iterate XObject entries
- [x] Filter for streams with Subtype "Image"
- [x] Extract image data using CGPDFStreamCopyData
- [x] Handle JPEG encoded format (save directly)
- [x] Handle JPEG2000 format (save with .jp2 extension)
- [x] Handle raw bitmap data (create CGImage with color space info)
- [x] Add image bounds calculation from stream dictionary
- [x] Replace annotation-based extraction with XObject extraction

## Phase 4: Vector Graphics Improvements
- [ ] Simplify grid-based approach to use larger sections
- [ ] Improve text detection in sections
- [ ] Add margin parameter for vector graphics cropping
- [ ] Implement whitespace detection to filter blank images
- [ ] Optimize section size based on page dimensions

## Phase 5: Integration and Testing
- [ ] Update PDFPageProcessor to use new image extraction
- [ ] Ensure proper element ordering by page and position
- [ ] Test with PDFs containing JPEG images
- [ ] Test with PDFs containing PNG/transparent images
- [ ] Test with PDFs containing vector graphics
- [ ] Test with text-only PDFs
- [ ] Test performance with large PDFs
- [ ] Verify memory usage is reasonable

## Phase 6: Error Handling and Polish
- [ ] Add error handling for corrupted image streams
- [ ] Handle PDFs with no Resources dictionary
- [ ] Add progress logging for large PDFs
- [ ] Update documentation and comments
- [ ] Run linting and type checking
- [ ] Update CHANGELOG.md with changes