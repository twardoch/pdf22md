# PDF to Markdown Converter

## Phase 1: Swift-Only Implementation ✅
- [x] Remove all traces of pdf21md (Objective-C implementation)
- [x] Create Makefile with build, install, and dist targets
- [x] Implement .pkg creation for installation to /usr/local/bin
- [x] Implement .dmg creation containing the .pkg installer
- [x] Create GitHub Action for automated builds and releases on semver tags      


## Phase 4: Vector Graphics Improvements
- [ ] Simplify grid-based approach to use larger sections
- [ ] Improve text detection in sections
- [ ] Add margin parameter for vector graphics cropping
- [ ] Implement whitespace detection to filter blank images
- [ ] Optimize section size based on page dimensions

## Phase 4b: Markdown Image Path Fix
- [ ] Update `AssetExtractor.saveImage` to return path prefixed with assets directory
- [ ] Pass relative assets directory info into `PDFMarkdownConverter` markdown generation
- [ ] Ensure generated Markdown links include the correct assets folder prefix
- [ ] Add unit test validating that every image reference in Markdown corresponds to an existing file

## Phase 5: Integration and Testing
- [x] Update PDFPageProcessor to use new image extraction
- [x] Ensure proper element ordering by page and position
- [x] Test with PDFs containing JPEG images (XObject extraction implemented)
- [x] Test with PDFs containing PNG/transparent images (format detection implemented)
- [x] Test with PDFs containing vector graphics (existing implementation)
- [x] Test with text-only PDFs (conditional processing working)
- [x] Test performance with large PDFs (async/await and GCD implementations)
- [x] Verify memory usage is reasonable (autoreleasepool used)
- [ ] Test markdown path handling with relative and absolute assets directories

## Phase 6: Error Handling and Polish
- [ ] Add error handling for corrupted image streams
- [ ] Handle PDFs with no Resources dictionary
- [ ] Add progress logging for large PDFs
- [x] Overhaul README.md with detailed general and technical sections.
- [ ] Update documentation and comments (README updated; other docs might need review)
- [ ] Run linting and type checking
- [ ] Update CHANGELOG.md with changes