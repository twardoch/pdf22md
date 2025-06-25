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
    PDF22MDErrorAssetFolderCreation = 1001,
    
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
     * Memory allocation failure or insufficient memory to process PDF.
     */
    PDF22MDErrorMemoryPressure = 1006,
    
    /**
     * Operation was cancelled.
     */
    PDF22MDErrorCancelled = 1007,
    
    /**
     * PDF processing timed out (document too complex).
     */
    PDF22MDErrorProcessingTimeout = 1008,
    
    /**
     * Password-protected PDFs are not currently supported.
     */
    PDF22MDErrorEncryptedPDF = 1009,
    
    /**
     * The PDF contains no readable content.
     */
    PDF22MDErrorEmptyDocument = 1010,
    
    /**
     * Invalid input parameters provided.
     */
    PDF22MDErrorInvalidInput = 1011,
    
    /**
     * File not found at specified path.
     */
    PDF22MDErrorFileNotFound = 1012,
    
    /**
     * Invalid file path provided.
     */
    PDF22MDErrorInvalidPath = 1013,
    
    /**
     * Directory not found or does not exist.
     */
    PDF22MDErrorDirectoryNotFound = 1014,
    
    /**
     * Permission denied for file system operation.
     */
    PDF22MDErrorPermissionDenied = 1015
};

/**
 * Keys for additional information in error's userInfo dictionary.
 */
extern NSString * const PDF22MDErrorPageIndexKey;      // NSNumber containing the failed page index
extern NSString * const PDF22MDErrorFilePathKey;       // NSString containing the problematic file path
extern NSString * const PDF22MDErrorUnderlyingErrorKey; // Original NSError that caused this error

/**
 * Helper class for creating consistent, user-friendly error objects.
 */
@interface PDF22MDErrorHelper : NSObject

/**
 * Creates a user-friendly error with code, description, and actionable suggestion.
 */
+ (NSError *)userFriendlyErrorWithCode:(PDF22MDError)code 
                           description:(NSString *)description
                            suggestion:(nullable NSString *)suggestion
                       underlyingError:(nullable NSError *)underlyingError;

/**
 * Creates an error for invalid PDF input.
 */
+ (NSError *)invalidPDFError;

/**
 * Creates an error for invalid PDF input with additional details.
 */
+ (NSError *)invalidPDFErrorWithReason:(nullable NSString *)reason;

/**
 * Creates an error for file not found.
 */
+ (NSError *)fileNotFoundErrorWithPath:(NSString *)path;

/**
 * Creates an error for invalid input parameters.
 */
+ (NSError *)invalidInputErrorWithReason:(NSString *)reason;

/**
 * Creates an error for asset folder creation failure.
 */
+ (NSError *)assetFolderCreationErrorWithPath:(NSString *)path 
                                       reason:(nullable NSString *)reason;

/**
 * Creates an error for memory pressure.
 */
+ (NSError *)memoryPressureError;

/**
 * Creates an error for processing timeout.
 */
+ (NSError *)processingTimeoutError;

/**
 * Creates an error for encrypted PDF.
 */
+ (NSError *)encryptedPDFError;

/**
 * Creates an error for empty document.
 */
+ (NSError *)emptyDocumentError;

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