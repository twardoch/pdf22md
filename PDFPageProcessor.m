#import "PDFPageProcessor.h"
#import "ContentElement.h"

typedef struct {
    __unsafe_unretained PDFPageProcessor *processor;
    CGAffineTransform textMatrix;
    CGAffineTransform ctm;
    CGFloat fontSize;
    NSString *fontName;
    NSMutableString *currentText;
    CGFloat textX;
    CGFloat textY;
    NSMutableArray *elements;
    NSMutableArray *pathPoints;
    BOOL inTextObject;
    BOOL hasPath;
    CGRect pathBounds;
} PDFScannerState;

// PDF operator callbacks
static void op_BT(CGPDFScannerRef scanner __attribute__((unused)), void *info) {
    // Begin text object
    PDFScannerState *state = (PDFScannerState *)info;
    state->inTextObject = YES;
    state->textMatrix = CGAffineTransformIdentity;
    state->currentText = [NSMutableString string];
}

static void op_ET(CGPDFScannerRef scanner __attribute__((unused)), void *info) {
    // End text object
    PDFScannerState *state = (PDFScannerState *)info;
    
    if ([state->currentText length] > 0) {
        TextElement *element = [[TextElement alloc] init];
        element.text = [state->currentText copy];
        element.fontSize = state->fontSize;
        element.fontName = state->fontName;
        element.pageIndex = state->processor->_pageIndex;
        
        // Simple bold/italic detection based on font name
        NSString *lowerFontName = [state->fontName lowercaseString];
        element.isBold = [lowerFontName containsString:@"bold"];
        element.isItalic = [lowerFontName containsString:@"italic"] || [lowerFontName containsString:@"oblique"];
        
        // Calculate bounds (simplified)
        CGFloat width = [state->currentText length] * state->fontSize * 0.5;
        CGFloat height = state->fontSize * 1.2;
        element.bounds = CGRectMake(state->textX, state->textY - height, width, height);
        
        [state->elements addObject:element];
    }
    
    state->inTextObject = NO;
    [state->currentText setString:@""];
}

static void op_Tf(CGPDFScannerRef scanner, void *info) {
    // Set font and size
    PDFScannerState *state = (PDFScannerState *)info;
    
    CGPDFReal size;
    const char *fontName;
    
    if (CGPDFScannerPopNumber(scanner, &size) &&
        CGPDFScannerPopName(scanner, &fontName)) {
        state->fontSize = size;
        state->fontName = [NSString stringWithUTF8String:fontName];
    }
}

static void op_Td(CGPDFScannerRef scanner, void *info) {
    // Move text position
    PDFScannerState *state = (PDFScannerState *)info;
    
    CGPDFReal tx, ty;
    if (CGPDFScannerPopNumber(scanner, &ty) &&
        CGPDFScannerPopNumber(scanner, &tx)) {
        state->textX += tx;
        state->textY += ty;
    }
}

static void op_TD(CGPDFScannerRef scanner, void *info) {
    // Move text position and set leading
    op_Td(scanner, info);
}

static void op_Tm(CGPDFScannerRef scanner, void *info) {
    // Set text matrix
    PDFScannerState *state = (PDFScannerState *)info;
    
    CGPDFReal a, b, c, d, e, f;
    if (CGPDFScannerPopNumber(scanner, &f) &&
        CGPDFScannerPopNumber(scanner, &e) &&
        CGPDFScannerPopNumber(scanner, &d) &&
        CGPDFScannerPopNumber(scanner, &c) &&
        CGPDFScannerPopNumber(scanner, &b) &&
        CGPDFScannerPopNumber(scanner, &a)) {
        state->textMatrix = CGAffineTransformMake(a, b, c, d, e, f);
        state->textX = e;
        state->textY = f;
    }
}

static void op_Tj(CGPDFScannerRef scanner, void *info) {
    // Show text string
    PDFScannerState *state = (PDFScannerState *)info;
    
    CGPDFStringRef pdfString;
    if (CGPDFScannerPopString(scanner, &pdfString)) {
        NSString *string = (__bridge_transfer NSString *)CGPDFStringCopyTextString(pdfString);
        if (string) {
            [state->currentText appendString:string];
        }
    }
}

static void op_TJ(CGPDFScannerRef scanner, void *info) {
    // Show text with individual glyph positioning
    PDFScannerState *state = (PDFScannerState *)info;
    
    CGPDFArrayRef array;
    if (CGPDFScannerPopArray(scanner, &array)) {
        size_t count = CGPDFArrayGetCount(array);
        for (size_t i = 0; i < count; i++) {
            CGPDFObjectRef object;
            if (CGPDFArrayGetObject(array, i, &object)) {
                CGPDFObjectType type = CGPDFObjectGetType(object);
                if (type == kCGPDFObjectTypeString) {
                    CGPDFStringRef pdfString;
                    if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString)) {
                        NSString *string = (__bridge_transfer NSString *)CGPDFStringCopyTextString(pdfString);
                        if (string) {
                            [state->currentText appendString:string];
                        }
                    }
                }
            }
        }
    }
}

static void op_Do(CGPDFScannerRef scanner, void *info) {
    // Draw XObject (potentially an image)
    PDFScannerState *state = (PDFScannerState *)info;
    
    const char *name;
    if (CGPDFScannerPopName(scanner, &name)) {
        // In a full implementation, we would look up this XObject
        // and extract the image if it's an image XObject
        // For now, we'll create a placeholder
        
        CGPDFContentStreamRef contentStream = CGPDFScannerGetContentStream(scanner);
        if (contentStream) {
            // This is simplified - in reality we'd need to look up the XObject
            // from the page's resource dictionary
            ImageElement *element = [[ImageElement alloc] init];
            element.bounds = CGRectMake(state->ctm.tx, state->ctm.ty, 100, 100); // Placeholder
            element.pageIndex = state->processor->_pageIndex;
            element.isVectorSource = NO;
            
            // Create a placeholder image
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(NULL, 100, 100, 8, 0, colorSpace,
                                                        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
            CGColorSpaceRelease(colorSpace);
            
            if (context) {
                CGContextSetRGBFillColor(context, 0.9, 0.9, 0.9, 1.0);
                CGContextFillRect(context, CGRectMake(0, 0, 100, 100));
                element.image = CGBitmapContextCreateImage(context);
                CGContextRelease(context);
                
                [state->elements addObject:element];
            }
        }
    }
}

// Path construction operators
static void op_m(CGPDFScannerRef scanner, void *info) {
    // Move to
    PDFScannerState *state = (PDFScannerState *)info;
    CGPDFReal x, y;
    if (CGPDFScannerPopNumber(scanner, &y) &&
        CGPDFScannerPopNumber(scanner, &x)) {
        [state->pathPoints addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
        state->hasPath = YES;
        
        // Update path bounds
        if (state->pathPoints.count == 1) {
            state->pathBounds = CGRectMake(x, y, 0, 0);
        } else {
            state->pathBounds = CGRectUnion(state->pathBounds, CGRectMake(x, y, 0, 0));
        }
    }
}

static void op_l(CGPDFScannerRef scanner, void *info) {
    // Line to
    op_m(scanner, info); // Same handling for bounds tracking
}

static void op_c(CGPDFScannerRef scanner, void *info) {
    // Cubic Bezier curve
    PDFScannerState *state = (PDFScannerState *)info;
    CGPDFReal x1, y1, x2, y2, x3, y3;
    if (CGPDFScannerPopNumber(scanner, &y3) &&
        CGPDFScannerPopNumber(scanner, &x3) &&
        CGPDFScannerPopNumber(scanner, &y2) &&
        CGPDFScannerPopNumber(scanner, &x2) &&
        CGPDFScannerPopNumber(scanner, &y1) &&
        CGPDFScannerPopNumber(scanner, &x1)) {
        state->hasPath = YES;
        state->pathBounds = CGRectUnion(state->pathBounds, CGRectMake(x3, y3, 0, 0));
    }
}

static void op_re(CGPDFScannerRef scanner, void *info) {
    // Rectangle
    PDFScannerState *state = (PDFScannerState *)info;
    CGPDFReal x, y, width, height;
    if (CGPDFScannerPopNumber(scanner, &height) &&
        CGPDFScannerPopNumber(scanner, &width) &&
        CGPDFScannerPopNumber(scanner, &y) &&
        CGPDFScannerPopNumber(scanner, &x)) {
        state->hasPath = YES;
        state->pathBounds = CGRectUnion(state->pathBounds, CGRectMake(x, y, width, height));
    }
}

static void op_S(CGPDFScannerRef scanner __attribute__((unused)), void *info) {
    // Stroke path
    PDFScannerState *state = (PDFScannerState *)info;
    if (state->hasPath) {
        [state->processor captureVectorGraphicsInBounds:state->pathBounds
                                            withElements:state->elements];
        state->hasPath = NO;
        [state->pathPoints removeAllObjects];
    }
}

static void op_f(CGPDFScannerRef scanner, void *info) {
    // Fill path
    op_S(scanner, info); // Same handling
}

static void op_B(CGPDFScannerRef scanner, void *info) {
    // Fill and stroke path
    op_S(scanner, info); // Same handling
}

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
    NSMutableArray<id<ContentElement>> *elements = [NSMutableArray array];
    
    if (!self.cgPdfPage) {
        return elements;
    }
    
    // Set up scanner state
    PDFScannerState state = {0};
    state.processor = self;
    state.elements = elements;
    state.pathPoints = [NSMutableArray array];
    state.ctm = CGAffineTransformIdentity;
    state.fontSize = 12.0;
    state.fontName = @"Helvetica";
    
    // Get content stream
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(self.cgPdfPage);
    if (!contentStream) {
        return elements;
    }
    
    // Create operator table
    CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();
    
    // Register text operators
    CGPDFOperatorTableSetCallback(operatorTable, "BT", &op_BT);
    CGPDFOperatorTableSetCallback(operatorTable, "ET", &op_ET);
    CGPDFOperatorTableSetCallback(operatorTable, "Tf", &op_Tf);
    CGPDFOperatorTableSetCallback(operatorTable, "Td", &op_Td);
    CGPDFOperatorTableSetCallback(operatorTable, "TD", &op_TD);
    CGPDFOperatorTableSetCallback(operatorTable, "Tm", &op_Tm);
    CGPDFOperatorTableSetCallback(operatorTable, "Tj", &op_Tj);
    CGPDFOperatorTableSetCallback(operatorTable, "TJ", &op_TJ);
    
    // Register graphics operators
    CGPDFOperatorTableSetCallback(operatorTable, "Do", &op_Do);
    CGPDFOperatorTableSetCallback(operatorTable, "m", &op_m);
    CGPDFOperatorTableSetCallback(operatorTable, "l", &op_l);
    CGPDFOperatorTableSetCallback(operatorTable, "c", &op_c);
    CGPDFOperatorTableSetCallback(operatorTable, "re", &op_re);
    CGPDFOperatorTableSetCallback(operatorTable, "S", &op_S);
    CGPDFOperatorTableSetCallback(operatorTable, "f", &op_f);
    CGPDFOperatorTableSetCallback(operatorTable, "F", &op_f);
    CGPDFOperatorTableSetCallback(operatorTable, "f*", &op_f);
    CGPDFOperatorTableSetCallback(operatorTable, "B", &op_B);
    CGPDFOperatorTableSetCallback(operatorTable, "B*", &op_B);
    CGPDFOperatorTableSetCallback(operatorTable, "b", &op_B);
    CGPDFOperatorTableSetCallback(operatorTable, "b*", &op_B);
    
    // Create scanner
    CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, &state);
    
    // Scan the page
    CGPDFScannerScan(scanner);
    
    // Clean up
    CGPDFScannerRelease(scanner);
    CGPDFOperatorTableRelease(operatorTable);
    CGPDFContentStreamRelease(contentStream);
    
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