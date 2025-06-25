# pdf22md - Modern Objective-C Implementation

A high-performance PDF to Markdown converter built with modern Objective-C patterns and best practices.

## Features

- **Modern Objective-C**: Uses nullability annotations, lightweight generics, and designated initializers
- **Thread-Safe**: Concurrent page processing with GCD and proper synchronization
- **Memory Efficient**: Automatic reference counting with strategic use of autorelease pools
- **Error Handling**: Comprehensive error reporting with custom error domain
- **Progress Tracking**: NSProgress integration for monitoring conversion status
- **Modular Architecture**: Clean separation of concerns with protocols and services

## Architecture

```
pdf22md-objc/
├── src/
│   ├── Core/                    # Core conversion logic
│   │   ├── PDF22MDConverter     # Main coordinator
│   │   ├── PDF22MDPageProcessor # Page content extraction
│   │   ├── PDF22MDFontAnalyzer  # Heading detection
│   │   └── PDF22MDError         # Error handling
│   ├── Models/                  # Data models
│   │   ├── PDF22MDContentElement # Protocol definition
│   │   ├── PDF22MDTextElement   # Text content
│   │   └── PDF22MDImageElement  # Image content
│   ├── Services/                # Business logic services
│   │   ├── PDF22MDAssetManager  # Image extraction/saving
│   │   └── PDF22MDMarkdownGenerator # Markdown generation
│   └── CLI/                     # Command-line interface
│       └── main.m
```

## Building

### Using the Build Script (Recommended)
```bash
# Build the project
./build.sh

# Build and run tests
./build.sh --test

# Build and install to /usr/local/bin
./build.sh --install

# Build, test, and install
./build.sh --test --install
```

### Using Make Directly
```bash
# Build with make
make

# Build with custom version
make VERSION=1.2.3

# Clean build artifacts
make clean

# Install to /usr/local/bin
sudo make install
```

## Usage

```bash
# Convert a PDF file
./pdf22md -i document.pdf -o document.md

# Extract images to assets folder
./pdf22md -i report.pdf -o report.md -a ./assets

# Customize DPI for vector graphics
./pdf22md -i presentation.pdf -o presentation.md -a ./images -d 300

# Use with pipes
cat document.pdf | ./pdf22md > document.md
```

## Key Implementation Details

### Thread Safety
- Uses dispatch queues for concurrent page processing
- Thread-safe collections with `@synchronized` blocks
- Atomic property access for shared state

### Memory Management
- ARC-enabled with proper ownership semantics
- Strategic `@autoreleasepool` blocks in loops
- Manual Core Graphics memory management where needed

### Error Handling
```objc
typedef NS_ERROR_ENUM(PDF22MDErrorDomain, PDF22MDError) {
    PDF22MDErrorInvalidPDF = 1000,
    PDF22MDErrorAssetCreationFailed,
    PDF22MDErrorProcessingFailed,
    // ...
};
```

### Progress Reporting
```objc
builder.progressHandler = ^(NSInteger currentPage, NSInteger totalPages) {
    NSLog(@"Processing page %ld of %ld", currentPage, totalPages);
};
```

## Modern Objective-C Features Used

1. **Nullability Annotations**
   - `NS_ASSUME_NONNULL_BEGIN/END`
   - `nullable` and `nonnull` qualifiers

2. **Lightweight Generics**
   - `NSArray<id<PDF22MDContentElement>> *`
   - `NSDictionary<NSString *, NSNumber *> *`

3. **Designated Initializers**
   - `NS_DESIGNATED_INITIALIZER`
   - `NS_UNAVAILABLE` for unsupported initializers

4. **Property Attributes**
   - Proper use of `copy`, `strong`, `weak`, `readonly`

5. **Modern Enumerations**
   - `NS_ENUM` and `NS_ERROR_ENUM` macros

## Testing

```bash
# Run basic tests
make test

# Test with sample PDFs
./pdf22md -i ../test/sample.pdf -o output.md -a ./test-assets
```

## Performance

- Utilizes all available CPU cores via GCD
- Concurrent image extraction and saving
- Memory-efficient streaming for large PDFs
- Optimized font analysis with caching

## Requirements

- macOS 10.15 or later
- Xcode Command Line Tools
- ARC enabled

## License

MIT License - see LICENSE file in the root directory