# Parallel Processing in `pdf22md`

This document outlines the implementation of parallel processing in the `pdf22md` command-line tool for converting PDF documents to Markdown format.

## 1. Objective

The goal was to accelerate the conversion of multi-page PDF documents by processing multiple pages concurrently and saving extracted images in parallel.

## 2. Technology: Grand Central Dispatch (GCD)

Similar to `pdfupng`, we utilized Apple's **Grand Central Dispatch (GCD)** framework with the `dispatch_apply` function for parallel execution.

## 3. Implementation Details

### 3.1. Parallel Page Processing

The core changes were made within the `convertWithAssetsFolderPath:rasterizedDPI:completion:` method in `PDFMarkdownConverter.m`.

#### From Sequential to Concurrent

The original implementation used a sequential `for` loop:

```objc
for (NSInteger pageIndex = 0; pageIndex < pageCount; pageIndex++) {
    PDFPage *page = [self.pdfDocument pageAtIndex:pageIndex];
    // ... process page ...
}
```

This was replaced with:

```objc
dispatch_apply(pageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t pageIndex) {
    @autoreleasepool {
        PDFPage *page = [self.pdfDocument pageAtIndex:pageIndex];
        // ... process page ...
    }
});
```

### 3.2. Thread Safety Measures

1. **Temporary Storage Arrays**: Instead of directly modifying shared arrays (`allElements`, `fontStats`), we create temporary per-page storage:

```objc
NSMutableArray<NSMutableArray<id<ContentElement>> *> *pageElementsArray = [NSMutableArray arrayWithCapacity:pageCount];
NSMutableArray<NSMutableDictionary *> *pageFontStatsArray = [NSMutableArray arrayWithCapacity:pageCount];
```

2. **Error Handling**: A shared boolean flag with synchronized access:

```objc
__block BOOL processingFailed = NO;
NSObject *lock = [[NSObject alloc] init];

// Inside parallel block
@synchronized(lock) {
    if (processingFailed) return;
}
```

3. **Result Merging**: After parallel processing completes, results are merged sequentially:

```objc
for (NSInteger i = 0; i < pageCount; i++) {
    [self.allElements addObjectsFromArray:pageElementsArray[i]];
    // Merge font statistics...
}
```

### 3.3. Parallel Image Saving

Image saving was also parallelized:

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

Each parallel operation is wrapped in `@autoreleasepool` to ensure prompt deallocation of temporary objects and prevent memory spikes.

## 4. Performance Benefits

- **Multi-core Utilization**: Pages are processed on multiple CPU cores simultaneously
- **Reduced Total Time**: For PDFs with many pages, the speedup is nearly linear with the number of cores
- **Efficient Memory Usage**: Autoreleasepool prevents memory accumulation
- **Scalability**: The implementation automatically adapts to the available hardware

## 5. Considerations

- **Thread Safety**: All shared resources are protected with appropriate synchronization
- **Memory Overhead**: Each parallel task has its own memory footprint, but autoreleasepool keeps it manageable
- **I/O Bottlenecks**: Image saving may be limited by disk I/O speed rather than CPU