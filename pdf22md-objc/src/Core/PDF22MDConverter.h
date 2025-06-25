#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PDF22MDConversionOptions;

/**
 * Main converter class that coordinates the PDF to Markdown conversion process.
 * This class manages the entire conversion pipeline including parallel processing,
 * content extraction, and markdown generation.
 */
@interface PDF22MDConverter : NSObject

/**
 * The PDF document being converted.
 */
@property (nonatomic, strong, readonly) PDFDocument *document;

/**
 * Progress object for tracking conversion progress.
 */
@property (nonatomic, strong, readonly) NSProgress *progress;

/**
 * Initializes a converter with PDF data.
 *
 * @param pdfData The PDF data to convert
 * @return A new converter instance, or nil if the PDF is invalid
 */
- (nullable instancetype)initWithPDFData:(NSData *)pdfData;

/**
 * Initializes a converter with a PDF file URL.
 *
 * @param pdfURL The URL of the PDF file to convert
 * @return A new converter instance, or nil if the PDF is invalid
 */
- (nullable instancetype)initWithPDFURL:(NSURL *)pdfURL;

/**
 * Designated initializer that creates a converter with both URL and document.
 * This is the real designated initializer that other initializers should call.
 *
 * @param pdfURL The URL of the PDF file (may be nil for data-based PDFs)
 * @param document The PDF document instance
 * @return A new converter instance, or nil if invalid
 */
- (nullable instancetype)initWithPDFURL:(nullable NSURL *)pdfURL document:(PDFDocument *)document NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Converts the PDF to Markdown with the given options.
 * This method performs the conversion asynchronously on a background queue.
 *
 * @param options Conversion options (uses defaults if nil)
 * @param completion Completion handler called with the result or error
 */
- (void)convertWithOptions:(nullable PDF22MDConversionOptions *)options
                completion:(void (^)(NSString * _Nullable markdown, NSError * _Nullable error))completion;

/**
 * Cancels an ongoing conversion.
 * The completion handler will be called with a cancellation error.
 */
- (void)cancelConversion;

/**
 * Validates that the PDF can be converted.
 *
 * @param error Set if validation fails
 * @return YES if the PDF is valid for conversion, NO otherwise
 */
- (BOOL)validateDocumentWithError:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END