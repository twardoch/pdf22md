#import "PDFPageProcessor.h"
#import "ContentElement.h"

@interface PDFPageProcessor ()
@property (nonatomic, strong) PDFPage *pdfPage;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) CGFloat dpi;
@property (nonatomic, assign) CGPDFPageRef cgPdfPage;
@end

@implementation PDFPageProcessor

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

- (NSArray<id<ContentElement>> *)extractContentElements {
    // -------------------------------------------------------------------------
    // NEW IMPLEMENTATION (2025-06-22)
    // -------------------------------------------------------------------------
    // The previous version relied on low-level CGPDFScanner APIs which could
    // enter an infinite loop on some malformed PDFs, causing the whole tool to
    // hang. We now use PDFKit's high-level API which is both safer and faster
    // for common text extraction tasks. Vector graphics and images will be
    // handled separately in future improvements.
    // -------------------------------------------------------------------------
    
    NSMutableArray<id<ContentElement>> *elements = [NSMutableArray array];
    
    // 1. Extract plain text for the entire page.
    NSString *pageText = [self.pdfPage string]; // PDFKit handles parsing
    if (!pageText || pageText.length == 0) {
        return elements; // Nothing to do
    }
    
    // 2. Split into paragraphs so we keep some structure.
    NSArray<NSString *> *paragraphs = [pageText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // 3. Prepare some default typography metadata. We no longer have direct
    //    font info – set conservative defaults so later heading detection logic
    //    can still run (all body text will share the same size, which is fine
    //    for now; future work can re-introduce advanced heuristics).
    NSString *defaultFontName = @"Helvetica";
    CGFloat   defaultFontSize = 12.0;
    
    // 4. Create a rough vertical cursor so elements have distinct Y positions.
    //    This keeps the existing (page, y, x) sort logic intact.
    CGFloat pageHeight = CGRectGetHeight([self.pdfPage boundsForBox:kPDFDisplayBoxMediaBox]);
    CGFloat cursorY    = pageHeight; // start at the top
    CGFloat lineHeight = defaultFontSize * 1.4; // simple approximation
    
    for (NSString *rawParagraph in paragraphs) {
        NSString *trimmed = [rawParagraph stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) { continue; }
        
        TextElement *element = [[TextElement alloc] init];
        element.text      = trimmed;
        element.fontName  = defaultFontName;
        element.fontSize  = defaultFontSize;
        element.isBold    = NO;
        element.isItalic  = NO;
        element.pageIndex = self.pageIndex;
        
        CGRect bounds = CGRectMake(0, cursorY - lineHeight, 400, lineHeight);
        element.bounds = bounds;
        
        cursorY -= (lineHeight + 2.0); // simple spacing
        
        [elements addObject:element];
    }
    
    // 5. Extract images using PDFKit annotations
    [self extractImagesFromPageWithElements:elements];
    
    return elements;
}

- (void)captureVectorGraphicsInBounds:(CGRect)bounds
                         withElements:(NSMutableArray *)elements {
    // Expand bounds slightly to ensure we capture everything
    bounds = CGRectInset(bounds, -5, -5);
    
    // Calculate size at specified DPI
    CGFloat scale = self.dpi / 72.0;
    size_t width = (size_t)(CGRectGetWidth(bounds) * scale);
    size_t height = (size_t)(CGRectGetHeight(bounds) * scale);
    
    if (width == 0 || height == 0) {
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
        ImageElement *element = [[ImageElement alloc] init];
        element.image = image;
        element.bounds = bounds;
        element.pageIndex = self.pageIndex;
        element.isVectorSource = YES;
        [elements addObject:element];
    }
}

- (void)extractImagesFromPageWithElements:(NSMutableArray *)elements {
    // Method 1: Extract images from annotations (for embedded images)
    NSArray<PDFAnnotation *> *annotations = [self.pdfPage annotations];
    NSInteger imageIndex = 0;
    
    for (PDFAnnotation *annotation in annotations) {
        // Skip text annotations and other non-image types
        if (![annotation isKindOfClass:[PDFAnnotation class]]) {
            continue;
        }
        
        // Try to get image from annotation appearance
        CGImageRef image = [self imageFromAnnotation:annotation];
        if (image) {
            ImageElement *element = [[ImageElement alloc] init];
            element.image = image;
            element.bounds = [annotation bounds];
            element.pageIndex = self.pageIndex;
            element.isVectorSource = NO;
            [elements addObject:element];
            imageIndex++;
        }
    }
    
    // Method 2: Render page areas that likely contain images
    // This is a fallback approach - render page in sections and detect image-like content
    [self extractImagesByRenderingPageSections:elements startingIndex:imageIndex];
}

- (CGImageRef)imageFromAnnotation:(PDFAnnotation *)annotation {
    // Try to extract image from annotation's appearance stream
    CGRect bounds = [annotation bounds];
    if (CGRectIsEmpty(bounds) || bounds.size.width < 10 || bounds.size.height < 10) {
        return NULL;
    }
    
    // Create a bitmap context to render the annotation
    CGFloat scale = self.dpi / 72.0;
    size_t width = (size_t)(bounds.size.width * scale);
    size_t height = (size_t)(bounds.size.height * scale);
    
    if (width == 0 || height == 0) {
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

- (void)extractImagesByRenderingPageSections:(NSMutableArray *)elements startingIndex:(NSInteger)startIndex {
    // This method divides the page into a grid and analyzes each section
    // to detect areas that contain primarily image content vs text content
    
    CGRect pageRect = [self.pdfPage boundsForBox:kPDFDisplayBoxMediaBox];
    CGFloat sectionSize = 100.0; // 100 point sections
    
    NSInteger gridX = (NSInteger)ceil(pageRect.size.width / sectionSize);
    NSInteger gridY = (NSInteger)ceil(pageRect.size.height / sectionSize);
    
    NSInteger imageIndex = startIndex;
    
    for (NSInteger x = 0; x < gridX; x++) {
        for (NSInteger y = 0; y < gridY; y++) {
            CGRect sectionRect = CGRectMake(x * sectionSize, y * sectionSize, 
                                          sectionSize, sectionSize);
            
            // Intersect with page bounds
            sectionRect = CGRectIntersection(sectionRect, pageRect);
            if (CGRectIsEmpty(sectionRect) || sectionRect.size.width < 20 || sectionRect.size.height < 20) {
                continue;
            }
            
            // Check if this section contains primarily image content
            if ([self sectionContainsImageContent:sectionRect]) {
                CGImageRef sectionImage = [self renderPageSection:sectionRect];
                if (sectionImage) {
                    ImageElement *element = [[ImageElement alloc] init];
                    element.image = sectionImage;
                    element.bounds = sectionRect;
                    element.pageIndex = self.pageIndex;
                    element.isVectorSource = YES; // Since we're rendering from vector
                    [elements addObject:element];
                    imageIndex++;
                }
            }
        }
    }
}

- (BOOL)sectionContainsImageContent:(CGRect)sectionRect {
    // Simple heuristic: if a section doesn't contain much text, it might be an image
    // This is a simplified approach - we could improve this with more sophisticated analysis
    
    // Get text in this section
    PDFSelection *selection = [self.pdfPage selectionForRect:sectionRect];
    NSString *sectionText = [selection string];
    
    // If there's very little text, it might be an image area
    NSString *trimmedText = [sectionText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Threshold: if less than 10 characters, consider it potentially an image area
    return [trimmedText length] < 10;
}

- (CGImageRef)renderPageSection:(CGRect)sectionRect {
    // Render just the specified section of the page
    CGFloat scale = self.dpi / 72.0;
    size_t width = (size_t)(sectionRect.size.width * scale);
    size_t height = (size_t)(sectionRect.size.height * scale);
    
    if (width == 0 || height == 0) {
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
    
    // Transform context to render just the section
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);
    CGContextTranslateCTM(context, -sectionRect.origin.x, -sectionRect.origin.y);
    
    // Draw the PDF page
    CGContextDrawPDFPage(context, self.cgPdfPage);
    
    CGContextRestoreGState(context);
    
    // Create image
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return image;
}

@end