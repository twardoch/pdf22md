#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFMarkdownConverter : NSObject

- (nullable instancetype)initWithPDFData:(NSData *)pdfData;
- (nullable instancetype)initWithPDFAtURL:(NSURL *)pdfURL;

- (void)convertWithAssetsFolderPath:(nullable NSString *)assetsPath
                     rasterizedDPI:(CGFloat)dpi
                        completion:(void (^)(NSString * _Nullable markdown, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END