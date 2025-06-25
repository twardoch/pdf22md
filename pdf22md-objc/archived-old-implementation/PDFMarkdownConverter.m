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
        // DEBUG log suppressed: Starting conversion of pages
        
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
        // DEBUG log suppressed: Starting dispatch_apply for pages
        dispatch_apply(pageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t pageIndex) {
            @autoreleasepool {
                // DEBUG log suppressed: Processing page
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
                // DEBUG log suppressed: Page extracted elements
                
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
        
        // DEBUG log suppressed: dispatch_apply completed
        
        // Check if processing failed
        if (processingFailed) {
            error = [NSError errorWithDomain:@"PDFMarkdownConverter"
                                       code:2
                                   userInfo:@{NSLocalizedDescriptionKey: @"Failed to process one or more PDF pages"}];
            completion(nil, error);
            return;
        }
        
        // DEBUG log suppressed: Merging results from all pages
        
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
        
        // DEBUG log suppressed: Analyzing font hierarchy
        
        // Analyze font hierarchy
        [self analyzeFontHierarchy];
        
        // DEBUG log suppressed: Sorting elements
        
        // Sort elements by page and position
        [self sortElements];
        
        // DEBUG log suppressed: Sort completed
        
        // Handle assets if needed
        AssetExtractor *assetExtractor = nil;
        if (assetsPath) {
            // DEBUG log suppressed: Starting asset extraction with path:
            assetExtractor = [[AssetExtractor alloc] initWithAssetFolder:assetsPath];
            if (!assetExtractor) {
                error = [NSError errorWithDomain:@"PDFMarkdownConverter"
                                           code:1
                                       userInfo:@{NSLocalizedDescriptionKey: @"Failed to create assets folder"}];
                completion(nil, error);
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
            // DEBUG log suppressed: Found images to extract
            if (imageCount > 0) {
                // DEBUG log suppressed: Starting parallel image extraction
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
                // DEBUG log suppressed: Completed parallel image extraction
            }
        } else {
            // DEBUG log suppressed: No assets path provided, skipping image extraction
        }
        
        // DEBUG log suppressed: Starting markdown generation
        
        // Generate markdown with YAML frontmatter
        NSMutableString *markdown = [NSMutableString string];
        
        // Add YAML frontmatter with metadata
        // DEBUG log suppressed: Generating YAML frontmatter
        NSString *yamlFrontmatter = [self generateYAMLFrontmatter];
        if (yamlFrontmatter) {
            [markdown appendString:yamlFrontmatter];
            [markdown appendString:@"\n"];
        }
        
        // DEBUG log suppressed: Converting elements to markdown
        for (id<ContentElement> element in self.allElements) {
            NSString *elementMarkdown = [element markdownRepresentation];
            if (elementMarkdown) {
                [markdown appendString:elementMarkdown];
                [markdown appendString:@"\n\n"];
            }
        }
        // DEBUG log suppressed: Markdown generation completed
        
        // Clean up extra newlines
        NSString *finalMarkdown = [markdown stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        completion(finalMarkdown, nil);
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

- (NSString *)generateYAMLFrontmatter {
    NSMutableString *yaml = [NSMutableString string];
    
    // Get PDF metadata
    NSDictionary *docAttributes = [self.pdfDocument documentAttributes];
    
    [yaml appendString:@"---\n"];
    
    // Title
    NSString *title = docAttributes[PDFDocumentTitleAttribute];
    if (title && title.length > 0) {
        [yaml appendFormat:@"title: \"%@\"\n", [self escapeYAMLString:title]];
    }
    
    // Author
    NSString *author = docAttributes[PDFDocumentAuthorAttribute];
    if (author && author.length > 0) {
        [yaml appendFormat:@"author: \"%@\"\n", [self escapeYAMLString:author]];
    }
    
    // Subject
    NSString *subject = docAttributes[PDFDocumentSubjectAttribute];
    if (subject && subject.length > 0) {
        [yaml appendFormat:@"subject: \"%@\"\n", [self escapeYAMLString:subject]];
    }
    
    // Keywords
    NSArray *keywords = docAttributes[PDFDocumentKeywordsAttribute];
    if (keywords && [keywords isKindOfClass:[NSArray class]] && keywords.count > 0) {
        [yaml appendString:@"keywords:\n"];
        for (NSString *keyword in keywords) {
            if ([keyword isKindOfClass:[NSString class]]) {
                [yaml appendFormat:@"  - \"%@\"\n", [self escapeYAMLString:keyword]];
            }
        }
    }
    
    // Creator (PDF producer software)
    NSString *creator = docAttributes[PDFDocumentCreatorAttribute];
    if (creator && creator.length > 0) {
        [yaml appendFormat:@"creator: \"%@\"\n", [self escapeYAMLString:creator]];
    }
    
    // Producer
    NSString *producer = docAttributes[PDFDocumentProducerAttribute];
    if (producer && producer.length > 0) {
        [yaml appendFormat:@"producer: \"%@\"\n", [self escapeYAMLString:producer]];
    }
    
    // Creation date
    NSDate *creationDate = docAttributes[PDFDocumentCreationDateAttribute];
    if (creationDate) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        [yaml appendFormat:@"created: %@\n", [formatter stringFromDate:creationDate]];
    }
    
    // Modification date
    NSDate *modDate = docAttributes[PDFDocumentModificationDateAttribute];
    if (modDate) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        [yaml appendFormat:@"modified: %@\n", [formatter stringFromDate:modDate]];
    }
    
    // PDF specific metadata
    [yaml appendString:@"pdf_metadata:\n"];
    [yaml appendFormat:@"  page_count: %ld\n", (long)[self.pdfDocument pageCount]];
    
    // PDF version
    NSString *pdfVersion = [self extractPDFVersion];
    if (pdfVersion) {
        [yaml appendFormat:@"  version: \"%@\"\n", pdfVersion];
    }
    
    // PDF outline (bookmarks/TOC)
    PDFOutline *outline = [self.pdfDocument outlineRoot];
    if (outline && [outline numberOfChildren] > 0) {
        [yaml appendString:@"  outline:\n"];
        [self appendOutlineToYAML:yaml outline:outline indent:@"    "];
    }
    
    // Conversion metadata
    [yaml appendString:@"conversion:\n"];
    [yaml appendString:@"  tool: \"pdf22md\"\n"];
    [yaml appendFormat:@"  version: \"%s\"\n", VERSION];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [yaml appendFormat:@"  date: %@\n", [formatter stringFromDate:[NSDate date]]];
    
    [yaml appendString:@"---\n"];
    
    return yaml;
}

- (NSString *)escapeYAMLString:(NSString *)string {
    // Escape quotes and backslashes for YAML
    NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    return escaped;
}

- (NSString *)extractPDFVersion {
    // Try to extract PDF version from document attributes or metadata
    // This is a simplified approach - actual PDF version extraction might require
    // reading the PDF header directly
    NSDictionary *attributes = [self.pdfDocument documentAttributes];
    for (NSString *key in attributes) {
        id value = attributes[key];
        if ([value isKindOfClass:[NSString class]] && 
            [value rangeOfString:@"PDF-" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return value;
        }
    }
    return nil;
}

- (void)appendOutlineToYAML:(NSMutableString *)yaml outline:(PDFOutline *)outline indent:(NSString *)indent {
    for (NSUInteger i = 0; i < [outline numberOfChildren]; i++) {
        PDFOutline *child = [outline childAtIndex:i];
        NSString *label = [child label];
        if (label && label.length > 0) {
            [yaml appendFormat:@"%@- title: \"%@\"\n", indent, [self escapeYAMLString:label]];
            
            PDFDestination *destination = [child destination];
            if (destination) {
                PDFPage *page = [destination page];
                NSInteger pageIndex = [self.pdfDocument indexForPage:page];
                [yaml appendFormat:@"%@  page: %ld\n", indent, (long)(pageIndex + 1)];
            }
            
            if ([child numberOfChildren] > 0) {
                [yaml appendFormat:@"%@  children:\n", indent];
                NSString *newIndent = [indent stringByAppendingString:@"    "];
                [self appendOutlineToYAML:yaml outline:child indent:newIndent];
            }
        }
    }
}

@end