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
    
    // NOTE: Image extraction has been temporarily disabled to prioritise
    //       reliability. The placeholder method captureVectorGraphicsInBounds:
    //       remains available for future use.
    
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

@end