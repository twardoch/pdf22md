#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDF21MDContentElement;
@class PDF21MDFontAnalyzer;

/**
 * Processes individual PDF pages to extract content elements.
 * Uses PDFKit's high-level API for safe and reliable content extraction.
 */
@interface PDF21MDPageProcessor : NSObject

/**
 * The PDF page being processed.
 */
@property (nonatomic, strong, readonly) PDFPage *pdfPage;

/**
 * The zero-based index of the page.
 */
@property (nonatomic, assign, readonly) NSInteger pageIndex;

/**
 * DPI for rasterizing vector graphics.
 */
@property (nonatomic, assign, readonly) CGFloat dpi;

/**
 * Font analyzer for this page (optional).
 */
@property (nonatomic, strong, nullable) PDF21MDFontAnalyzer *fontAnalyzer;

/**
 * Initializes a page processor for the given PDF page.
 *
 * @param pdfPage The PDF page to process
 * @param pageIndex The zero-based page index
 * @param dpi DPI for rasterization (default: 144)
 * @return A new page processor instance
 */
- (instancetype)initWithPDFPage:(PDFPage *)pdfPage
                      pageIndex:(NSInteger)pageIndex
                            dpi:(CGFloat)dpi NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Extracts all content elements from the page.
 * This includes text and images.
 *
 * @return Array of content elements in reading order
 */
- (NSArray<id<PDF21MDContentElement>> *)extractContentElements;

/**
 * Extracts only text elements from the page.
 *
 * @return Array of text elements
 */
- (NSArray<id<PDF21MDContentElement>> *)extractTextElements;

/**
 * Extracts only image elements from the page.
 *
 * @return Array of image elements
 */
- (NSArray<id<PDF21MDContentElement>> *)extractImageElements;

/**
 * Captures vector graphics in the specified bounds as a rasterized image.
 *
 * @param bounds The area to capture
 * @param elements Array to add the captured image element to
 */
- (void)captureVectorGraphicsInBounds:(CGRect)bounds
                         withElements:(NSMutableArray<id<PDF21MDContentElement>> *)elements;

@end

NS_ASSUME_NONNULL_END