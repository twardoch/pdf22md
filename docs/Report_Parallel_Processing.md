# Parallel Processing in `pdf22md`

This document describes how `pdf22md` uses parallel processing to convert multi-page PDFs to Markdown more quickly.

## 1. Objective

Process multiple PDF pages at the same time and save extracted images in parallel to reduce overall conversion time.

## 2. Technology: Grand Central Dispatch (GCD)

Like `pdfupng`, we used Apple’s **Grand Central Dispatch (GCD)** framework with `dispatch_apply` for concurrent execution.

## 3. Implementation Details

### 3.1. Parallel Page Conversion

Changes were made to the `convertWithAssetsFolderPath:rasterizedDPI:completion:` method in `PDFMarkdownConverter.m`.

#### Replacing the Sequential Loop

Originally, pages were handled one after another:

```objc
for (NSInteger pageIndex = 0; pageIndex < pageCount; pageIndex++) {
    PDFPage *page = [self.pdfDocument pageAtIndex:pageIndex];
    // ... process page ...
}
```

Now, GCD handles them concurrently:

```objc
dispatch_apply(pageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t pageIndex) {
    @autoreleasepool {
        PDFPage *page = [self.pdfDocument pageAtIndex:pageIndex];
        // ... process page ...
    }
});
```

### 3.2. Thread Safety

To avoid race conditions, shared data is no longer modified directly during parallel operations.

1. **Per-Page Storage**: Each page writes to its own temporary arrays:

```objc
NSMutableArray<NSMutableArray<id<ContentElement>> *> *pageElementsArray = [NSMutableArray arrayWithCapacity:pageCount];
NSMutableArray<NSMutableDictionary *> *pageFontStatsArray = [NSMutableArray arrayWithCapacity:pageCount];
```

2. **Error Flag Sync**: A shared failure flag is accessed using `@synchronized`:

```objc
__block BOOL processingFailed = NO;
NSObject *lock = [[NSObject alloc] init];

// Inside parallel block
@synchronized(lock) {
    if (processingFailed) return;
}
```

3. **Sequential Merge**: After all pages finish, results are combined:

```objc
for (NSInteger i = 0; i < pageCount; i++) {
    [self.allElements addObjectsFromArray:pageElementsArray[i]];
    // Merge font statistics...
}
```

### 3.3. Parallel Image Saving

Saving images also runs in parallel:

```objc
dispatch_apply(imageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
    @autoreleasepool {
        ImageElement *imageElement = imageElements[index];
        NSString *savedPath = [assetExtractor saveImage:imageElement.image ...];
        if (savedPath) {
            @synchronized(imageElement) {
                imageElement.assetRelativePath = savedPath;
            }
        }
    }
});
```

### 3.4. Memory Management

Each parallel task runs inside an `@autoreleasepool` to keep memory usage from spiraling out of control.

## 4. Performance Gains

- **Multi-core Use**: Pages run on multiple CPU cores at once  
- **Faster Conversion**: Speedup scales nearly linearly with core count on large documents  
- **Controlled Memory**: Autorelease pools prevent leaks and bloat  
- **Hardware Adaptation**: Automatically adjusts to available cores  

## 5. Notes and Limits

- **Thread Safety Required**: Shared data must be guarded with synchronization  
- **Memory Trade-off**: More tasks mean more memory, but not unmanageable thanks to autorelease pools  
- **Disk I/O Can Slow Things Down**: Image saving speed depends on storage performance, not just CPU power