#import "PDF21MDConverter.h"
#import "PDF21MDConversionOptions.h"
#import "PDF21MDPageProcessor.h"
#import "../Models/PDF21MDContentElement.h"
#import "../Models/PDF21MDImageElement.h"
#import "../Services/PDF21MDAssetManager.h"
#import "../Services/PDF21MDMarkdownGenerator.h"
#import "PDF21MDFontAnalyzer.h"
#import "PDF21MDError.h"
#import "../../shared-core/PDF21MDConcurrencyManager.h"

@interface PDF21MDConverter ()
@property (nonatomic, strong) dispatch_queue_t conversionQueue;
@property (nonatomic, strong) NSMutableArray<id<PDF21MDContentElement>> *allElements;
@property (nonatomic, strong) PDF21MDFontAnalyzer *fontAnalyzer;
@property (nonatomic, assign) BOOL isCancelled;
@end

@implementation PDF21MDConverter

#pragma mark - Initialization

- (nullable instancetype)initWithPDFData:(NSData *)pdfData {
    if (!pdfData || pdfData.length == 0) {
        return nil;
    }
    
    PDFDocument *document = [[PDFDocument alloc] initWithData:pdfData];
    if (!document) {
        return nil;
    }
    
    NSURL *tempURL = [NSURL URLWithString:@"data:application/pdf"];
    return [self initWithPDFURL:tempURL document:document];
}

- (nullable instancetype)initWithPDFURL:(NSURL *)pdfURL {
    if (!pdfURL) {
        return nil;
    }
    
    PDFDocument *document = [[PDFDocument alloc] initWithURL:pdfURL];
    if (!document) {
        return nil;
    }
    
    return [self initWithPDFURL:pdfURL document:document];
}

- (nullable instancetype)initWithPDFURL:(nullable NSURL *)pdfURL document:(PDFDocument *)document {
    if (!document) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _document = document;
        _conversionQueue = [PDF21MDConcurrencyManager sharedConverterQueue];
        _allElements = [NSMutableArray array];
        _fontAnalyzer = [[PDF21MDFontAnalyzer alloc] init];
        _progress = [NSProgress progressWithTotalUnitCount:[document pageCount]];
        _isCancelled = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (void)convertWithOptions:(nullable PDF21MDConversionOptions *)options
                completion:(void (^)(NSString * _Nullable markdown, NSError * _Nullable error))completion {
    // Use default options if none provided
    if (!options) {
        options = [PDF21MDConversionOptions defaultOptions];
    }
    
    // Validate options
    NSError *validationError = nil;
    if (![options validateWithError:&validationError]) {
        completion(nil, validationError);
        return;
    }
    
    // Reset state
    self.isCancelled = NO;
    [self.allElements removeAllObjects];
    [self.fontAnalyzer reset];
    self.progress.completedUnitCount = 0;
    
    // Configure font analyzer
    self.fontAnalyzer.fontSizeThreshold = options.headingFontSizeThreshold;
    self.fontAnalyzer.maxHeadingLevel = options.maxHeadingLevel;
    
    // Perform conversion using shared concurrency manager
    [PDF21MDConcurrencyManager performConverterOperation:^{
        @autoreleasepool {
            NSError *error = nil;
            NSString *markdown = [self performConversionWithOptions:options error:&error];
            
            // Call completion on main queue
            [PDF21MDConcurrencyManager executeOnMainQueue:^{
                completion(markdown, error);
            }];
        }
    } completion:nil];
}

- (void)cancelConversion {
    self.isCancelled = YES;
    [self.progress cancel];
}

- (BOOL)validateDocumentWithError:(NSError * _Nullable * _Nullable)error {
    if (!self.document) {
        if (error) {
            *error = [PDF21MDErrorHelper invalidPDFErrorWithReason:@"Document is nil"];
        }
        return NO;
    }
    
    if ([self.document pageCount] == 0) {
        if (error) {
            *error = [PDF21MDErrorHelper invalidPDFErrorWithReason:@"Document has no pages"];
        }
        return NO;
    }
    
    if ([self.document isLocked]) {
        if (error) {
            *error = [PDF21MDErrorHelper invalidPDFErrorWithReason:@"Document is password protected"];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - Private Methods

- (nullable NSString *)performConversionWithOptions:(PDF21MDConversionOptions *)options
                                              error:(NSError * _Nullable * _Nullable)error {
    // Validate document
    if (![self validateDocumentWithError:error]) {
        return nil;
    }
    
    NSInteger pageCount = [self.document pageCount];
    
    // Create asset manager if needed
    PDF21MDAssetManager *assetManager = nil;
    if (options.extractImages && options.assetsFolderPath) {
        assetManager = [[PDF21MDAssetManager alloc] initWithAssetFolder:options.assetsFolderPath];
        if (!assetManager) {
            if (error) {
                *error = [PDF21MDErrorHelper assetFolderCreationErrorWithPath:options.assetsFolderPath
                                                                          reason:@"Failed to create asset manager"];
            }
            return nil;
        }
    }
    
    // Process pages in parallel
    NSMutableArray<NSMutableArray<id<PDF21MDContentElement>> *> *pageElementsArray = [NSMutableArray arrayWithCapacity:pageCount];
    NSMutableArray<PDF21MDFontAnalyzer *> *pageFontAnalyzers = [NSMutableArray arrayWithCapacity:pageCount];
    
    for (NSInteger i = 0; i < pageCount; i++) {
        [pageElementsArray addObject:[NSMutableArray array]];
        [pageFontAnalyzers addObject:[[PDF21MDFontAnalyzer alloc] init]];
    }
    
    // Create dispatch group for parallel processing
    dispatch_group_t processingGroup = dispatch_group_create();
    __block BOOL processingFailed = NO;
    __block NSError *processingError = nil;
    
    // Limit concurrency based on options
    dispatch_semaphore_t concurrencySemaphore = dispatch_semaphore_create(options.maxConcurrentPages);
    
    for (NSInteger pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        if (self.isCancelled) {
            if (error) {
                *error = [NSError errorWithDomain:PDF21MDErrorDomain
                                             code:PDF21MDErrorCancelled
                                         userInfo:@{NSLocalizedDescriptionKey: @"Conversion was cancelled"}];
            }
            return nil;
        }
        
        dispatch_group_async(processingGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(concurrencySemaphore, DISPATCH_TIME_FOREVER);
            
            @autoreleasepool {
                if (!processingFailed && !self.isCancelled) {
                    PDFPage *page = [self.document pageAtIndex:pageIndex];
                    if (!page) {
                        processingFailed = YES;
                        processingError = [PDF21MDErrorHelper pageProcessingFailedErrorForPage:pageIndex
                                                                                        reason:@"Failed to get page"
                                                                               underlyingError:nil];
                    } else {
                        // Process page
                        PDF21MDPageProcessor *processor = [[PDF21MDPageProcessor alloc] initWithPDFPage:page
                                                                                             pageIndex:pageIndex
                                                                                                   dpi:options.rasterizationDPI];
                        processor.fontAnalyzer = pageFontAnalyzers[pageIndex];
                        
                        NSArray<id<PDF21MDContentElement>> *pageElements = [processor extractContentElements];
                        [pageElementsArray[pageIndex] addObjectsFromArray:pageElements];
                        
                        // Analyze fonts for this page
                        [pageFontAnalyzers[pageIndex] analyzeElements:pageElements];
                        
                        // Update progress
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progress.completedUnitCount = pageIndex + 1;
                            if (options.progressHandler) {
                                options.progressHandler(pageIndex + 1, pageCount);
                            }
                        });
                    }
                }
            }
            
            dispatch_semaphore_signal(concurrencySemaphore);
        });
    }
    
    // Wait for all pages to complete with timeout
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC); // 60 seconds timeout
    long result = dispatch_group_wait(processingGroup, timeout);
    
    if (result != 0) {
        // Timeout occurred
        if (error) {
            *error = [PDF21MDErrorHelper processingFailedErrorWithReason:@"PDF processing timed out after 60 seconds. The PDF may be corrupted or too complex."
                                                       underlyingError:nil];
        }
        return nil;
    }
    
    if (processingFailed) {
        if (error) {
            *error = processingError ?: [PDF21MDErrorHelper processingFailedErrorWithReason:@"Unknown processing error"
                                                                              underlyingError:nil];
        }
        return nil;
    }
    
    if (self.isCancelled) {
        if (error) {
            *error = [NSError errorWithDomain:PDF21MDErrorDomain
                                         code:PDF21MDErrorCancelled
                                     userInfo:@{NSLocalizedDescriptionKey: @"Conversion was cancelled"}];
        }
        return nil;
    }
    
    // Merge results from all pages
    for (NSInteger i = 0; i < pageCount; i++) {
        [self.allElements addObjectsFromArray:pageElementsArray[i]];
        [self.fontAnalyzer mergeFontStatisticsFromAnalyzer:pageFontAnalyzers[i]];
    }
    
    // Analyze font hierarchy and assign heading levels
    [self.fontAnalyzer analyzeElements:self.allElements];
    [self.fontAnalyzer assignHeadingLevels:self.allElements];
    
    // Sort elements by page and position
    [self sortElements];
    
    // Extract and save images if needed
    if (assetManager) {
        [self extractImagesWithAssetManager:assetManager];
    }
    
    // Generate markdown
    PDF21MDMarkdownGenerator *generator = [[PDF21MDMarkdownGenerator alloc] initWithOptions:options];
    PDF21MDDocumentMetadata *metadata = [PDF21MDMarkdownGenerator extractMetadataFromDocument:self.document];
    
    NSString *markdown = [generator generateMarkdownFromElements:self.allElements withMetadata:metadata];
    
    return markdown;
}

- (void)sortElements {
    [self.allElements sortUsingComparator:^NSComparisonResult(id<PDF21MDContentElement> obj1, id<PDF21MDContentElement> obj2) {
        // First sort by page
        if (obj1.pageIndex != obj2.pageIndex) {
            return obj1.pageIndex < obj2.pageIndex ? NSOrderedAscending : NSOrderedDescending;
        }
        
        // Then sort by vertical position (top to bottom)
        CGFloat y1 = CGRectGetMaxY(obj1.bounds);
        CGFloat y2 = CGRectGetMaxY(obj2.bounds);
        
        if (fabs(y1 - y2) > 5.0) { // Tolerance for same line
            return y1 > y2 ? NSOrderedAscending : NSOrderedDescending;
        }
        
        // Finally sort by horizontal position (left to right)
        CGFloat x1 = CGRectGetMinX(obj1.bounds);
        CGFloat x2 = CGRectGetMinX(obj2.bounds);
        
        return x1 < x2 ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void)extractImagesWithAssetManager:(PDF21MDAssetManager *)assetManager {
    NSMutableArray<PDF21MDImageElement *> *imageElements = [NSMutableArray array];
    
    for (id<PDF21MDContentElement> element in self.allElements) {
        if ([element isKindOfClass:[PDF21MDImageElement class]]) {
            [imageElements addObject:(PDF21MDImageElement *)element];
        }
    }
    
    if (imageElements.count == 0) {
        return;
    }
    
    // Save images in parallel
    dispatch_group_t imageGroup = dispatch_group_create();
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [imageElements enumerateObjectsUsingBlock:^(PDF21MDImageElement *imageElement, NSUInteger idx, BOOL * __unused stop) {
        dispatch_group_async(imageGroup, imageQueue, ^{
            @autoreleasepool {
                NSString *baseName = [NSString stringWithFormat:@"image_%03lu", (unsigned long)idx];
                [assetManager saveImageElement:imageElement withBaseName:baseName];
            }
        });
    }];
    
    dispatch_group_wait(imageGroup, DISPATCH_TIME_FOREVER);
}

@end