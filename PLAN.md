# PDF to Markdown Converter - Swift Implementation Rewrite Plan

## Current State Analysis

The current Swift implementation has the following structure:
- **PDFMarkdownConverter**: Main orchestrator using async/await for concurrent processing
- **PDFPageProcessor**: Processes individual pages to extract text and images
- **AssetExtractor**: Handles saving images in PNG/JPEG format
- **CGPDFImageExtractor**: Currently only extracts annotations, not actual embedded images

### Key Issues with Current Implementation

1. **Image Extraction**: The current CGPDFImageExtractor only looks at annotations, not actual embedded images in PDF XObject streams
2. **Asset Naming**: Current naming is generic (`image_001.png`) instead of including PDF basename and page number
3. **Vector Graphics**: Current implementation divides pages into grid sections, which is inefficient and may miss actual vector graphics
4. **Conditional Processing**: The current implementation always attempts to extract images even when no assets folder is specified

## Implementation Plan

### Phase 1: Core Infrastructure Updates

#### 1.1 Update AssetExtractor
- Modify asset naming scheme to use: `<pdf-basename>-<page-number>-<asset-number>.<ext>`
- Page numbers should be 3-digit zero-padded (e.g., `001`, `002`)
- Asset numbers on each page should be 2-digit zero-padded (e.g., `01`, `02`)
- Pass PDF basename and page index to the AssetExtractor

#### 1.2 Conditional Asset Processing
- Only create assets directory if `-a`/`--assets` is provided
- Skip all image extraction and processing when assets path is not provided
- Update PDFPageProcessor to conditionally extract images based on assets path

### Phase 2: Proper Image Extraction from PDF

#### 2.1 Implement Real PDF XObject Image Extraction
Based on the tutorial in `Report_PDF_Parsing.md`, we need to:
- Access the page's CGPDFPage reference from PDFPage
- Navigate the PDF structure: Page → Resources → XObject dictionary
- Iterate through XObject entries and filter for Subtype "Image"
- Extract image data using CGPDFStreamCopyData
- Handle different image formats (JPEG, JPEG2000, raw bitmap data)

#### 2.2 Create New Image Extractor
Replace the current annotation-based approach with proper XObject extraction:
```swift
// New approach structure:
1. Get CGPDFPage from PDFPage.pageRef
2. Get page dictionary → Resources → XObject
3. Iterate XObject entries with CGPDFDictionaryApplyBlock
4. Check if entry is stream with Subtype "Image"
5. Extract image data and format
6. Convert to CGImage if needed
```

### Phase 3: Vector Graphics Detection and Extraction

#### 3.1 Simplified Vector Graphics Detection
For the initial implementation, use a pragmatic approach:
- Identify page regions that have minimal or no text content
- Check for the presence of path operations in those regions
- Render regions that likely contain diagrams, charts, or illustrations
- This avoids the complexity of full content stream parsing

#### 3.2 Smart Cropping and Rendering
- Start with larger regions and refine based on content detection
- Add reasonable margins (10-15 points) around detected graphics
- Use the specified DPI for rasterization
- Skip regions that are too small (< 50x50 points) or mostly whitespace

### Phase 4: Integration and Optimization

#### 4.1 Update PDFPageProcessor
- Pass assets path to determine if image extraction is needed
- Integrate new XObject-based image extractor
- Improve vector graphics detection algorithm
- Ensure proper ordering of extracted assets

#### 4.2 Update PDFMarkdownConverter
- Pass PDF basename to AssetExtractor
- Ensure markdown image references use correct relative paths
- Handle cases where assets folder is not provided (skip image references)

#### 4.3 Correct Markdown Image Path Handling
- Ensure the path returned by `AssetExtractor.saveImage` includes the relative assets folder prefix so that the generated Markdown points to the **actual** asset location (e.g. `assets/report-001-01.png` instead of just `report-001-01.png`).
- Pass the *relative* assets directory (derived from the `-a/--assets` argument) into the Markdown generator so the converter can build correct paths regardless of where the output Markdown file resides.
- Add unit tests that verify the generated Markdown contains valid image links when:
  * the assets directory is a sibling of the Markdown file (common case: `./assets`)
  * the assets directory is an absolute path elsewhere on disk
- Fail gracefully (log a warning) if the computed relative path cannot be determined, falling back to the absolute path so links still work.

### Phase 5: Testing and Refinement

#### 5.1 Test Cases
- PDFs with embedded JPEG images
- PDFs with PNG images (with transparency)
- PDFs with vector graphics (charts, diagrams)
- PDFs with mixed content
- PDFs without any images
- Running without `-a` flag (text-only extraction)

#### 5.2 Performance Optimization
- Ensure concurrent processing still works correctly
- Optimize memory usage for large images
- Add progress indicators for large PDFs

## Technical Implementation Details

### XObject Image Extraction Algorithm

The key steps for extracting embedded images from PDF:

1. Access the CGPDFPage from PDFPage.pageRef
2. Navigate through Page → Resources → XObject dictionary
3. Iterate XObject entries and identify Image subtypes
4. Extract image data with appropriate format handling
5. Convert to CGImage for further processing

Key considerations:
- Handle JPEG encoded data (can be saved directly)
- Handle JPEG2000 data (save with appropriate extension)
- For raw bitmap data, need to read width, height, color space from stream dictionary
- Create CGImage from raw data using CGDataProvider and color space information

### Vector Graphics Detection Strategy

For the initial implementation:
1. Divide page into reasonable sections (not too small)
2. Check text content in each section
3. Sections with minimal text are candidates for vector graphics
4. Render candidate sections at specified DPI
5. Filter out blank/whitespace images

Future enhancement could include:
- Parsing content streams for path operators
- More sophisticated graphics detection
- Better bounding box calculation

## Success Criteria

1. **Correct Image Extraction**: All embedded raster images are extracted from PDFs
2. **Proper Naming**: Assets follow the naming convention `basename-pagenumber-assetnumber.ext`
3. **Conditional Processing**: No image processing occurs when `-a` is not provided
4. **Vector Graphics**: Vector graphics are detected and rasterized at specified DPI
5. **Markdown Links**: All image references in the generated Markdown resolve to existing files in the assets folder (verified by tests)
6. **Performance**: Maintains concurrent processing capabilities
7. **Compatibility**: Works with various PDF types and image formats

## Risk Mitigation

1. **Complex PDFs**: Some PDFs may have unusual structures - add robust error handling
2. **Memory Usage**: Large images could consume significant memory - process one at a time
3. **Format Support**: Handle various image encodings (JPEG, JPEG2000, raw bitmaps)
4. **Coordinate Systems**: PDF coordinates may need transformation for proper bounds calculation

## Implementation Priority

Based on the requirements and complexity:

1. **First Priority**: Fix conditional asset processing (only process images when `-a` is provided)
2. **Second Priority**: Update asset naming to include PDF basename and page numbers
3. **Third Priority**: Implement proper XObject image extraction
4. **Fourth Priority**: Improve vector graphics detection

This order ensures we meet the basic requirements first before tackling more complex improvements.

## Next Steps

1. Create detailed TODO.md with specific implementation tasks
2. Start with conditional processing fixes
3. Update AssetExtractor with new naming scheme
4. Implement XObject-based image extraction
5. Test with various PDF samples
6. Optimize and refine based on testing results