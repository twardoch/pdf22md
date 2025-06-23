# TODO

## ✅ Phase 1a: Asset extraction (Done)

```
./pdf22md -i ./test/digitallegacies-twardoch2018.pdf -o ./test/output.md -a ./test/out
```

Segmentation fault fixed. The tool now extracts all embedded images (PNG/JPG chosen automatically) and rasterizes vector graphics into appropriately named files (`image_001.png`, `image_002.jpg`, ...).

## Phase 2: Distribution

- [ ] Create Homebrew formula and tap for easy installation (`brew install twardoch/pdf22md/pdf22md`)
- [ ] Test Homebrew installation process on clean macOS system
- [ ] Add Homebrew installation verification to CI/CD

## Phase 3: Documentation Improvements

- [ ] Add usage examples for different PDF types to README.md
- [ ] Create man page for the tool (`man pdf22md`)
- [ ] Document known limitations and workarounds
- [ ] Add troubleshooting section to README.md

## Core Features

- [ ] Preserve PDF bookmarks/outline structure and extracting metadata (author, title, creation date) into YAML frontmatter
- [ ] Improve heading detection algorithm
- [ ] Better handling of tables and lists
- [ ] Support for PDF forms and annotations

### Code Quality

- [ ] Add unit tests for core functionality
- [ ] Implement proper error handling with descriptive messages
- [ ] Add code comments and documentation
- [ ] Create man page for the tool
- [ ] Add performance benchmarks

### Advanced Distribution

- [ ] Set up automated nightly builds
- [ ] Add support for Linux (using GNUstep)
- [ ] Create Docker image for cross-platform usage
- [ ] Add Windows support via WSL or native compilation

### Advanced Documentation

- [ ] Add detailed API documentation for developers
- [ ] Write technical blog post about the implementation
- [ ] Create video tutorials for common use cases
- [ ] Add performance benchmarking documentation
