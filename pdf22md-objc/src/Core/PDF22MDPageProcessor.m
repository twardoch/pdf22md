#import "PDF22MDPageProcessor.h"
#import "../Models/PDF22MDTextElement.h"
#import "../Models/PDF22MDImageElement.h"
#import "PDF22MDFontAnalyzer.h"
#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

@interface PDF22MDPageProcessor ()
@property (nonatomic, assign) CGPDFPageRef cgPdfPage;
@end

@implementation PDF22MDPageProcessor

#pragma mark - Initialization

- (instancetype)initWithPDFPage:(PDFPage *)pdfPage
                      pageIndex:(NSInteger)pageIndex
                            dpi:(CGFloat)dpi {
    self = [super init];
    if (self) {
        _pdfPage = pdfPage;
        _pageIndex = pageIndex;
        _dpi = dpi;
        _cgPdfPage = [pdfPage pageRef];
    }
    return self;
}

#pragma mark - Public Methods

- (NSArray<id<PDF22MDContentElement>> *)extractContentElements {
    NSMutableArray<id<PDF22MDContentElement>> *elements = [NSMutableArray array];
    
    // Extract text elements
    NSArray *textElements = [self extractTextElements];
    [elements addObjectsFromArray:textElements];
    
    // Extract image elements
    NSArray *imageElements = [self extractImageElements];
    [elements addObjectsFromArray:imageElements];
    
    // Sort elements by position
    [self sortElementsByPosition:elements];
    
    return elements;
}

- (NSArray<id<PDF22MDContentElement>> *)extractTextElements {
    NSMutableArray<id<PDF22MDContentElement>> *elements = [NSMutableArray array];
    
    // Extract text using PDFKit's high-level API
    NSString *pageText = [self.pdfPage string];
    if (!pageText || pageText.length == 0) {
        return elements;
    }
    
    // Get page bounds for positioning
    CGRect pageRect = [self.pdfPage boundsForBox:kPDFDisplayBoxMediaBox];
    CGFloat pageHeight = CGRectGetHeight(pageRect);
    
    // Split into paragraphs while preserving structure
    NSArray<NSString *> *paragraphs = [self extractParagraphsFromPageText:pageText];
    
    // Create text elements with approximate positioning
    CGFloat cursorY = pageHeight - 20; // Start near top with margin
    CGFloat lineHeight = 14.0; // Default line height
    CGFloat paragraphSpacing = lineHeight * 0.5;
    
    for (NSString *paragraph in paragraphs) {
        NSString *trimmed = [paragraph stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            cursorY -= paragraphSpacing;
            continue;
        }
        
        // Try to extract font information from PDF selections
        PDFSelection *selection = [self.pdfPage selectionForRange:NSMakeRange(0, trimmed.length)];
        NSDictionary *fontInfo = [self extractFontInfoFromSelection:selection];
        
        PDF22MDTextElement *element = [[PDF22MDTextElement alloc] initWithText:trimmed
                                                                        bounds:CGRectMake(20, cursorY - lineHeight, pageRect.size.width - 40, lineHeight)
                                                                     pageIndex:self.pageIndex
                                                                      fontName:fontInfo[@"fontName"]
                                                                      fontSize:[fontInfo[@"fontSize"] doubleValue]
                                                                        isBold:[fontInfo[@"isBold"] boolValue]
                                                                      isItalic:[fontInfo[@"isItalic"] boolValue]];
        
        [elements addObject:element];
        
        // Update cursor position
        NSInteger lineCount = [self estimateLineCountForText:trimmed inWidth:pageRect.size.width - 40];
        cursorY -= (lineHeight * lineCount + paragraphSpacing);
    }
    
    return elements;
}

- (NSArray<id<PDF22MDContentElement>> *)extractImageElements {
    NSMutableArray<id<PDF22MDContentElement>> *elements = [NSMutableArray array];
    
    // Method 1: Extract images from annotations
    NSArray<PDFAnnotation *> *annotations = [self.pdfPage annotations];
    
    for (PDFAnnotation *annotation in annotations) {
        // Check if annotation might contain an image
        if ([self annotationMayContainImage:annotation]) {
            CGImageRef image = [self imageFromAnnotation:annotation];
            if (image) {
                PDF22MDImageElement *element = [[PDF22MDImageElement alloc] initWithImage:image
                                                                                   bounds:[annotation bounds]
                                                                                pageIndex:self.pageIndex
                                                                           isVectorSource:NO];
                [elements addObject:element];
                CGImageRelease(image);
            }
        }
    }
    
    // Method 2: Detect image regions by analyzing page content
    NSArray *imageRegions = [self detectImageRegionsInPage];
    for (NSData *regionData in imageRegions) {
        CGRect region;
        [regionData getBytes:&region length:sizeof(CGRect)];
        [self captureVectorGraphicsInBounds:region withElements:elements];
    }
    
    return elements;
}

- (void)captureVectorGraphicsInBounds:(CGRect)bounds
                         withElements:(NSMutableArray<id<PDF22MDContentElement>> *)elements {
    // Expand bounds slightly to ensure we capture everything
    bounds = CGRectInset(bounds, -5, -5);
    
    // Calculate size at specified DPI
    CGFloat scale = self.dpi / 72.0;
    size_t width = (size_t)(CGRectGetWidth(bounds) * scale);
    size_t height = (size_t)(CGRectGetHeight(bounds) * scale);
    
    if (width == 0 || height == 0 || width > 4096 || height > 4096) {
        return;
    }
    
    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace,
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        return;
    }
    
    // Set white background
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    // Set up transformation to render just the bounds area
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);
    CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
    
    // Draw the PDF page
    CGContextDrawPDFPage(context, self.cgPdfPage);
    
    CGContextRestoreGState(context);
    
    // Create image
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    if (image) {
        PDF22MDImageElement *element = [[PDF22MDImageElement alloc] initWithImage:image
                                                                           bounds:bounds
                                                                        pageIndex:self.pageIndex
                                                                   isVectorSource:YES];
        [elements addObject:element];
        CGImageRelease(image);
    }
}

#pragma mark - Private Methods

- (NSArray<NSString *> *)extractParagraphsFromPageText:(NSString *)pageText {
    // Split by multiple newlines to get paragraphs
    NSArray *components = [pageText componentsSeparatedByString:@"\n\n"];
    NSMutableArray *paragraphs = [NSMutableArray array];
    
    for (NSString *component in components) {
        // Further split by single newlines but join short lines
        NSArray *lines = [component componentsSeparatedByString:@"\n"];
        NSMutableString *paragraph = [NSMutableString string];
        
        for (NSString *line in lines) {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (trimmedLine.length > 0) {
                if (paragraph.length > 0) {
                    // Add space between lines
                    [paragraph appendString:@" "];
                }
                [paragraph appendString:trimmedLine];
            }
        }
        
        if (paragraph.length > 0) {
            [paragraphs addObject:[paragraph copy]];
        }
    }
    
    return paragraphs;
}

- (NSDictionary *)extractFontInfoFromSelection:(PDFSelection *)selection {
    // Default font info
    NSMutableDictionary *fontInfo = [@{
        @"fontName": @"Helvetica",
        @"fontSize": @(12.0),
        @"isBold": @(NO),
        @"isItalic": @(NO)
    } mutableCopy];
    
    // PDFKit doesn't provide direct access to font information
    // This would require lower-level Core Graphics analysis
    // For now, we'll use heuristics based on the text content
    
    NSString *text = [selection string];
    if (text) {
        // Simple heuristic: all caps might indicate a heading
        if ([text isEqualToString:[text uppercaseString]] && text.length > 3) {
            fontInfo[@"fontSize"] = @(14.0);
            fontInfo[@"isBold"] = @(YES);
        }
    }
    
    return fontInfo;
}

- (BOOL)annotationMayContainImage:(PDFAnnotation *)annotation {
    // Check annotation type and bounds
    CGRect bounds = [annotation bounds];
    
    // Images typically have reasonable dimensions
    if (CGRectIsEmpty(bounds) || bounds.size.width < 10 || bounds.size.height < 10) {
        return NO;
    }
    
    // Check if it's not a text annotation
    NSString *contents = [annotation contents];
    if (contents && contents.length > 0) {
        return NO;
    }
    
    return YES;
}

- (CGImageRef)imageFromAnnotation:(PDFAnnotation *)annotation {
    CGRect bounds = [annotation bounds];
    
    // Create a bitmap context to render the annotation
    CGFloat scale = self.dpi / 72.0;
    size_t width = (size_t)(bounds.size.width * scale);
    size_t height = (size_t)(bounds.size.height * scale);
    
    if (width == 0 || height == 0 || width > 4096 || height > 4096) {
        return NULL;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace,
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        return NULL;
    }
    
    // Set white background
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    // Transform context to match annotation bounds
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);
    
    // Draw just the annotation area from the page
    CGContextClipToRect(context, CGRectMake(0, 0, bounds.size.width, bounds.size.height));
    CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
    CGContextDrawPDFPage(context, self.cgPdfPage);
    
    CGContextRestoreGState(context);
    
    // Create image
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return image;
}

- (NSArray *)detectImageRegionsInPage {
    NSMutableArray *regions = [NSMutableArray array];
    
    // Simple heuristic: divide page into grid and check for non-text regions
    CGRect pageRect = [self.pdfPage boundsForBox:kPDFDisplayBoxMediaBox];
    CGFloat gridSize = 100.0;
    
    NSInteger gridX = (NSInteger)ceil(pageRect.size.width / gridSize);
    NSInteger gridY = (NSInteger)ceil(pageRect.size.height / gridSize);
    
    for (NSInteger x = 0; x < gridX; x++) {
        for (NSInteger y = 0; y < gridY; y++) {
            CGRect gridRect = CGRectMake(x * gridSize, y * gridSize, gridSize, gridSize);
            gridRect = CGRectIntersection(gridRect, pageRect);
            
            if (CGRectIsEmpty(gridRect) || gridRect.size.width < 20 || gridRect.size.height < 20) {
                continue;
            }
            
            // Check if this region contains primarily non-text content
            PDFSelection *selection = [self.pdfPage selectionForRect:gridRect];
            NSString *regionText = [[selection string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // If very little text, might be an image region
            if (regionText.length < 10) {
                NSData *rectData = [NSData dataWithBytes:&gridRect length:sizeof(CGRect)];
                [regions addObject:rectData];
            }
        }
    }
    
    // Merge adjacent regions
    return [self mergeAdjacentRegions:regions];
}

- (NSArray *)mergeAdjacentRegions:(NSArray *)regions {
    if (regions.count <= 1) {
        return regions;
    }
    
    NSMutableArray *mergedRegions = [NSMutableArray array];
    NSMutableSet *processedIndices = [NSMutableSet set];
    
    for (NSUInteger i = 0; i < regions.count; i++) {
        if ([processedIndices containsObject:@(i)]) {
            continue;
        }
        
        CGRect currentRect;
        [regions[i] getBytes:&currentRect length:sizeof(CGRect)];
        [processedIndices addObject:@(i)];
        
        // Try to merge with adjacent regions
        BOOL merged = YES;
        while (merged) {
            merged = NO;
            
            for (NSUInteger j = 0; j < regions.count; j++) {
                if ([processedIndices containsObject:@(j)]) {
                    continue;
                }
                
                CGRect otherRect;
                [regions[j] getBytes:&otherRect length:sizeof(CGRect)];
                
                // Check if rectangles are adjacent
                if (CGRectIntersectsRect(CGRectInset(currentRect, -10, -10), otherRect)) {
                    currentRect = CGRectUnion(currentRect, otherRect);
                    [processedIndices addObject:@(j)];
                    merged = YES;
                }
            }
        }
        
        NSData *rectData = [NSData dataWithBytes:&currentRect length:sizeof(CGRect)];
        [mergedRegions addObject:rectData];
    }
    
    return mergedRegions;
}

- (NSInteger)estimateLineCountForText:(NSString *)text inWidth:(CGFloat)width {
    // Simple estimation based on average character width
    CGFloat avgCharWidth = 7.0; // Approximate for 12pt font
    NSInteger charsPerLine = (NSInteger)(width / avgCharWidth);
    
    if (charsPerLine <= 0) {
        return 1;
    }
    
    return MAX(1, (text.length + charsPerLine - 1) / charsPerLine);
}

- (void)sortElementsByPosition:(NSMutableArray<id<PDF22MDContentElement>> *)elements {
    [elements sortUsingComparator:^NSComparisonResult(id<PDF22MDContentElement> obj1, id<PDF22MDContentElement> obj2) {
        // Sort by vertical position (top to bottom)
        CGFloat y1 = CGRectGetMaxY(obj1.bounds);
        CGFloat y2 = CGRectGetMaxY(obj2.bounds);
        
        if (fabs(y1 - y2) > 5.0) { // Tolerance for same line
            return y1 > y2 ? NSOrderedAscending : NSOrderedDescending;
        }
        
        // Same line, sort by horizontal position (left to right)
        CGFloat x1 = CGRectGetMinX(obj1.bounds);
        CGFloat x2 = CGRectGetMinX(obj2.bounds);
        
        return x1 < x2 ? NSOrderedAscending : NSOrderedDescending;
    }];
}

@end