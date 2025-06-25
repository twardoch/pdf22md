#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ContentElement;

@interface PDFPageProcessor : NSObject {
    @public
    NSInteger _pageIndex;
}

- (instancetype)initWithPDFPage:(PDFPage *)pdfPage
                      pageIndex:(NSInteger)pageIndex
                            dpi:(CGFloat)dpi;

- (NSArray<id<ContentElement>> *)extractContentElements;

- (void)captureVectorGraphicsInBounds:(CGRect)bounds
                         withElements:(NSMutableArray *)elements;

@end

NS_ASSUME_NONNULL_END