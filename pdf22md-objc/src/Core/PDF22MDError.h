#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for all PDF22MD errors.
 */
extern NSErrorDomain const PDF22MDErrorDomain;

/**
 * Error codes used throughout the PDF22MD framework.
 */
typedef NS_ERROR_ENUM(PDF22MDErrorDomain, PDF22MDError) {
    /**
     * The provided PDF file or data is invalid or corrupted.
     */
    PDF22MDErrorInvalidPDF = 1000,
    
    /**
     * Failed to create the assets folder or save extracted images.
     */
    PDF22MDErrorAssetCreationFailed = 1001,
    
    /**
     * General processing failure during conversion.
     */
    PDF22MDErrorProcessingFailed = 1002,
    
    /**
     * One or more pages failed to process.
     */
    PDF22MDErrorPageProcessingFailed = 1003,
    
    /**
     * Invalid or missing configuration options.
     */
    PDF22MDErrorInvalidConfiguration = 1004,
    
    /**
     * I/O error reading or writing files.
     */
    PDF22MDErrorIOFailure = 1005,
    
    /**
     * Memory allocation failure.
     */
    PDF22MDErrorMemoryFailure = 1006,
    
    /**
     * Operation was cancelled.
     */
    PDF22MDErrorCancelled = 1007
};

/**
 * Keys for additional information in error's userInfo dictionary.
 */
extern NSString * const PDF22MDErrorPageIndexKey;      // NSNumber containing the failed page index
extern NSString * const PDF22MDErrorFilePathKey;       // NSString containing the problematic file path
extern NSString * const PDF22MDErrorUnderlyingErrorKey; // Original NSError that caused this error

/**
 * Helper class for creating consistent error objects.
 */
@interface PDF22MDErrorHelper : NSObject

/**
 * Creates an error for invalid PDF input.
 */
+ (NSError *)invalidPDFError;

/**
 * Creates an error for invalid PDF input with additional details.
 */
+ (NSError *)invalidPDFErrorWithReason:(nullable NSString *)reason;

/**
 * Creates an error for asset creation failure.
 */
+ (NSError *)assetCreationFailedErrorWithPath:(NSString *)path 
                                         reason:(nullable NSString *)reason;

/**
 * Creates an error for page processing failure.
 */
+ (NSError *)pageProcessingFailedErrorForPage:(NSInteger)pageIndex 
                                        reason:(nullable NSString *)reason
                               underlyingError:(nullable NSError *)underlyingError;

/**
 * Creates an error for general processing failure.
 */
+ (NSError *)processingFailedErrorWithReason:(NSString *)reason 
                              underlyingError:(nullable NSError *)underlyingError;

/**
 * Creates an error for I/O failure.
 */
+ (NSError *)ioFailureErrorWithPath:(nullable NSString *)path 
                              reason:(NSString *)reason
                     underlyingError:(nullable NSError *)underlyingError;

@end

NS_ASSUME_NONNULL_END