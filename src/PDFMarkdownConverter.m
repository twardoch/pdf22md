#import "PDFMarkdownConverter.h"
#import "PDFPageProcessor.h"
#import "ContentElement.h"
#import "AssetExtractor.h"

@interface PDFMarkdownConverter ()
@property (nonatomic, strong) PDFDocument *pdfDocument;
@property (nonatomic, strong) NSMutableArray<id<ContentElement>> *allElements;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *fontStats;
@end

@implementation PDFMarkdownConverter

- (nullable instancetype)initWithPDFData:(NSData *)pdfData {
    self = [super init];
    if (self) {
        _pdfDocument = [[PDFDocument alloc] initWithData:pdfData];
        if (!_pdfDocument) {
            return nil;
        }
        _allElements = [NSMutableArray array];
        _fontStats = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nullable instancetype)initWithPDFAtURL:(NSURL *)pdfURL {
    self = [super init];
    if (self) {
        _pdfDocument = [[PDFDocument alloc] initWithURL:pdfURL];
        if (!_pdfDocument) {
            return nil;
        }
        _allElements = [NSMutableArray array];
        _fontStats = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)convertWithAssetsFolderPath:(nullable NSString *)assetsPath
                     rasterizedDPI:(CGFloat)dpi
                        completion:(void (^)(NSString * _Nullable markdown, NSError * _Nullable error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        // Process all pages in parallel
        NSInteger pageCount = [self.pdfDocument pageCount];
        
        // Create thread-safe temporary storage
        NSMutableArray<NSMutableArray<id<ContentElement>> *> *pageElementsArray = [NSMutableArray arrayWithCapacity:pageCount];
        NSMutableArray<NSMutableDictionary *> *pageFontStatsArray = [NSMutableArray arrayWithCapacity:pageCount];
        
        // Initialize arrays
        for (NSInteger i = 0; i < pageCount; i++) {
            [pageElementsArray addObject:[NSMutableArray array]];
            [pageFontStatsArray addObject:[NSMutableDictionary dictionary]];
        }
        
        // Lock for thread safety
        NSObject *lock = [[NSObject alloc] init];
        __block BOOL processingFailed = NO;
        
        // Process pages in parallel using dispatch_apply
        dispatch_apply(pageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t pageIndex) {
            @autoreleasepool {
                // Check if processing has already failed
                @synchronized(lock) {
                    if (processingFailed) return;
                }
                
                PDFPage *page = [self.pdfDocument pageAtIndex:pageIndex];
                if (!page) {
                    @synchronized(lock) {
                        processingFailed = YES;
                    }
                    return;
                }
                
                PDFPageProcessor *processor = [[PDFPageProcessor alloc] initWithPDFPage:page
                                                                               pageIndex:pageIndex
                                                                                     dpi:dpi];
                
                NSArray<id<ContentElement>> *pageElements = [processor extractContentElements];
                
                // Store results in thread-safe arrays
                pageElementsArray[pageIndex] = [pageElements mutableCopy];
                
                // Collect font statistics for this page
                NSMutableDictionary *pageFontStats = pageFontStatsArray[pageIndex];
                for (id<ContentElement> element in pageElements) {
                    if ([element isKindOfClass:[TextElement class]]) {
                        TextElement *textElement = (TextElement *)element;
                        NSString *fontKey = [NSString stringWithFormat:@"%.1f-%@", 
                                           textElement.fontSize, 
                                           textElement.fontName ?: @"Unknown"];
                        
                        NSNumber *count = pageFontStats[fontKey];
                        pageFontStats[fontKey] = @([count integerValue] + 1);
                    }
                }
            }
        });
        
        // Check if processing failed
        if (processingFailed) {
            error = [NSError errorWithDomain:@"PDFMarkdownConverter"
                                       code:2
                                   userInfo:@{NSLocalizedDescriptionKey: @"Failed to process one or more PDF pages"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // Merge results from all pages
        for (NSInteger i = 0; i < pageCount; i++) {
            [self.allElements addObjectsFromArray:pageElementsArray[i]];
            
            // Merge font statistics
            NSDictionary *pageFontStats = pageFontStatsArray[i];
            for (NSString *fontKey in pageFontStats) {
                NSNumber *pageCount = pageFontStats[fontKey];
                NSNumber *totalCount = self.fontStats[fontKey];
                self.fontStats[fontKey] = @([totalCount integerValue] + [pageCount integerValue]);
            }
        }
        
        // Analyze font hierarchy
        [self analyzeFontHierarchy];
        
        // Sort elements by page and position
        [self sortElements];
        
        // Handle assets if needed
        AssetExtractor *assetExtractor = nil;
        if (assetsPath) {
            assetExtractor = [[AssetExtractor alloc] initWithAssetFolder:assetsPath];
            if (!assetExtractor) {
                error = [NSError errorWithDomain:@"PDFMarkdownConverter"
                                           code:1
                                       userInfo:@{NSLocalizedDescriptionKey: @"Failed to create assets folder"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
                return;
            }
            
            // Save images in parallel
            NSMutableArray<ImageElement *> *imageElements = [NSMutableArray array];
            for (id<ContentElement> element in self.allElements) {
                if ([element isKindOfClass:[ImageElement class]]) {
                    [imageElements addObject:(ImageElement *)element];
                }
            }
            
            NSInteger imageCount = [imageElements count];
            if (imageCount > 0) {
                dispatch_apply(imageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
                    @autoreleasepool {
                        ImageElement *imageElement = imageElements[index];
                        NSString *baseName = [NSString stringWithFormat:@"image_%03zu", index];
                        NSString *savedPath = [assetExtractor saveImage:imageElement.image
                                                          isVectorSource:imageElement.isVectorSource
                                                              withBaseName:baseName];
                        if (savedPath) {
                            @synchronized(imageElement) {
                                imageElement.assetRelativePath = savedPath;
                            }
                        }
                    }
                });
            }
        }
        
        // Generate markdown
        NSMutableString *markdown = [NSMutableString string];
        for (id<ContentElement> element in self.allElements) {
            NSString *elementMarkdown = [element markdownRepresentation];
            if (elementMarkdown) {
                [markdown appendString:elementMarkdown];
                [markdown appendString:@"\n\n"];
            }
        }
        
        // Clean up extra newlines
        NSString *finalMarkdown = [markdown stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(finalMarkdown, nil);
        });
    });
}

- (void)collectFontStatisticsFromElements:(NSArray<id<ContentElement>> *)elements {
    for (id<ContentElement> element in elements) {
        if ([element isKindOfClass:[TextElement class]]) {
            TextElement *textElement = (TextElement *)element;
            NSString *fontKey = [NSString stringWithFormat:@"%.1f-%@", 
                               textElement.fontSize, 
                               textElement.fontName ?: @"Unknown"];
            
            NSNumber *count = self.fontStats[fontKey];
            self.fontStats[fontKey] = @([count integerValue] + 1);
        }
    }
}

- (void)analyzeFontHierarchy {
    // Sort font sizes to determine heading levels
    NSMutableArray<NSNumber *> *uniqueSizes = [NSMutableArray array];
    NSMutableDictionary<NSNumber *, NSNumber *> *sizeFrequency = [NSMutableDictionary dictionary];
    
    for (NSString *fontKey in self.fontStats) {
        NSArray *components = [fontKey componentsSeparatedByString:@"-"];
        if (components.count > 0) {
            CGFloat fontSize = [components[0] floatValue];
            NSNumber *sizeNum = @(fontSize);
            
            if (![uniqueSizes containsObject:sizeNum]) {
                [uniqueSizes addObject:sizeNum];
            }
            
            NSInteger freq = [sizeFrequency[sizeNum] integerValue] + [self.fontStats[fontKey] integerValue];
            sizeFrequency[sizeNum] = @(freq);
        }
    }
    
    // Sort sizes in descending order
    [uniqueSizes sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj2 compare:obj1];
    }];
    
    // Assign heading levels based on size hierarchy
    // Assume largest font is H1, second largest is H2, etc.
    NSMutableDictionary<NSNumber *, NSNumber *> *sizeToHeadingLevel = [NSMutableDictionary dictionary];
    NSInteger headingLevel = 1;
    
    for (NSNumber *size in uniqueSizes) {
        // Only assign heading levels to fonts that are significantly larger than average
        // and appear less frequently (typical of headings)
        NSInteger frequency = [sizeFrequency[size] integerValue];
        
        if (headingLevel <= 6 && frequency < 100) { // Adjust threshold as needed
            sizeToHeadingLevel[size] = @(headingLevel);
            headingLevel++;
        } else {
            sizeToHeadingLevel[size] = @(0); // Body text
        }
    }
    
    // Apply heading levels to text elements
    for (id<ContentElement> element in self.allElements) {
        if ([element isKindOfClass:[TextElement class]]) {
            TextElement *textElement = (TextElement *)element;
            NSNumber *sizeNum = @(textElement.fontSize);
            NSNumber *level = sizeToHeadingLevel[sizeNum];
            textElement.headingLevel = level ? [level integerValue] : 0;
        }
    }
}

- (void)sortElements {
    [self.allElements sortUsingComparator:^NSComparisonResult(id<ContentElement> obj1, id<ContentElement> obj2) {
        // First sort by page
        if ([obj1 respondsToSelector:@selector(pageIndex)] && [obj2 respondsToSelector:@selector(pageIndex)]) {
            NSInteger page1 = [(id)obj1 pageIndex];
            NSInteger page2 = [(id)obj2 pageIndex];
            
            if (page1 != page2) {
                return page1 < page2 ? NSOrderedAscending : NSOrderedDescending;
            }
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

@end