# Plan for Professional Repository Reorganization

This plan will transform the current flat structure into a professional, maintainable, and distributable open-source project.

### Step 1: New Directory Structure

The source code will be moved into a `src` directory to separate it from project-level configuration, documentation, and build files.

```text
pdf22md/
├── .github/                      # GitHub-specific files
│   ├── workflows/
│   │   └── build-release.yml     # GitHub Action for CI and releases
│   └── ISSUE_TEMPLATE/
│       └── bug_report.md         # Template for bug reports
├── src/                          # All Objective-C source files
│   ├── AssetExtractor.h
│   ├── AssetExtractor.m
│   ├── ContentElement.h
│   ├── ContentElement.m
│   ├── main.m
│   ├── PDFMarkdownConverter.h
│   ├── PDFMarkdownConverter.m
│   ├── PDFPageProcessor.h
│   └── PDFPageProcessor.m
├── docs/                         # Additional documentation
│   └── PARALLEL_PROCESSING.md
├── .gitignore                    # Comprehensive gitignore for macOS/Obj-C
├── LICENSE                       # An open-source license (e.g., MIT)
├── Makefile                      # Updated to handle the new structure
└── README.md                     # The documentation from above
```

**Action Items:**

1.  Create `src` and `docs` directories.
2.  Move all `.h` and `.m` files into `src/`.
3.  Move `PARALLEL_PROCESSING.md` into `docs/`.
4.  Update the `Makefile` to reference files in `src/`.

### Step 2: Update the Makefile

The `Makefile` must be modified to find the source files in `src/` and to respect a `PREFIX` variable for portable installation, which is crucial for Homebrew.

**`Makefile` Modifications:**

```makefile
CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework CoreServices
TARGET = pdf22md

# Define source directory
SRC_DIR = src
SOURCES = $(wildcard $(SRC_DIR)/*.m)
OBJECTS = $(SOURCES:.m=.o)

# Default prefix for installation
PREFIX ?= /usr/local

all: $(TARGET)

$(TARGET): $(OBJECTS)
    $(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(OBJECTS)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.m
    $(CC) $(CFLAGS) -c $< -o $@

clean:
    rm -f $(OBJECTS) $(TARGET)

install: $(TARGET)
    install -d $(DESTDIR)$(PREFIX)/bin
    install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/

uninstall:
    rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)

.PHONY: all clean install uninstall
```

### Step 3: Create a Comprehensive `.gitignore`

The current ignore files are minimal. A professional project needs a robust `.gitignore` for macOS and Objective-C development.

**`.gitignore` Contents:**

```gitignore
# Build products
build/
*.o
$(TARGET) # The executable file itself

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear on external disk
.Spotlight-V100
.Trashes

# Editor-specific
.vscode/
*.swp
.idea/
.cursorindexingignore
.specstory/
```

### Step 4: Add GitHub Actions for CI & Release Automation

Create a GitHub Actions workflow to automatically build the tool on every push and create a release binary when a Git tag is pushed.

**File: `.github/workflows/build-release.yml`**

```yaml
name: Build and Release

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  release:
    types: [ created ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Build the tool
      run: make

    - name: Run a basic check
      run: ./${{ env.TARGET_NAME }} -h

  create-release:
    if: github.event_name == 'release'
    runs-on: macos-latest
    needs: build

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Build the binary
      run: make

    - name: Create Tarball Archive
      run: |
        tar -czvf pdf22md-macos-x86_64.tar.gz pdf22md

    - name: Upload Release Asset
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ github.event.release.upload_url }}
        asset_path: ./pdf22md-macos-x86_64.tar.gz
        asset_name: pdf22md-macos-x86_64.tar.gz
        asset_content_type: application/gzip
```
