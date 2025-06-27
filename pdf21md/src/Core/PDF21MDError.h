#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for all PDF21MD errors.
 */
extern NSErrorDomain const PDF21MDErrorDomain;

/**
 * Error codes used throughout the PDF21MD framework.
 */
typedef NS_ERROR_ENUM(PDF21MDErrorDomain, PDF21MDError) {
    /**
     * The provided PDF file or data is invalid or corrupted.
     */
    PDF21MDErrorInvalidPDF = 1000,
    
    /**
     * Failed to create the assets folder or save extracted images.
     */
    PDF21MDErrorAssetFolderCreation = 1001,
    
    /**
     * General processing failure during conversion.
     */
    PDF21MDErrorProcessingFailed = 1002,
    
    /**
     * One or more pages failed to process.
     */
    PDF21MDErrorPageProcessingFailed = 1003,
    
    /**
     * Invalid or missing configuration options.
     */
    PDF21MDErrorInvalidConfiguration = 1004,
    
    /**
     * I/O error reading or writing files.
     */
    PDF21MDErrorIOFailure = 1005,
    
    /**
     * Memory allocation failure or insufficient memory to process PDF.
     */
    PDF21MDErrorMemoryPressure = 1006,
    
    /**
     * Operation was cancelled.
     */
    PDF21MDErrorCancelled = 1007,
    
    /**
     * PDF processing timed out (document too complex).
     */
    PDF21MDErrorProcessingTimeout = 1008,
    
    /**
     * Password-protected PDFs are not currently supported.
     */
    PDF21MDErrorEncryptedPDF = 1009,
    
    /**
     * The PDF contains no readable content.
     */
    PDF21MDErrorEmptyDocument = 1010,
    
    /**
     * Invalid input parameters provided.
     */
    PDF21MDErrorInvalidInput = 1011,
    
    /**
     * File not found at specified path.
     */
    PDF21MDErrorFileNotFound = 1012,
    
    /**
     * Invalid file path provided.
     */
    PDF21MDErrorInvalidPath = 1013,
    
    /**
     * Directory not found or does not exist.
     */
    PDF21MDErrorDirectoryNotFound = 1014,
    
    /**
     * Permission denied for file system operation.
     */
    PDF21MDErrorPermissionDenied = 1015
};

/**
 * Keys for additional information in error's userInfo dictionary.
 */
extern NSString * const PDF21MDErrorPageIndexKey;      // NSNumber containing the failed page index
extern NSString * const PDF21MDErrorFilePathKey;       // NSString containing the problematic file path
extern NSString * const PDF21MDErrorUnderlyingErrorKey; // Original NSError that caused this error

/**
 * Helper class for creating consistent, user-friendly error objects.
 */
@interface PDF21MDErrorHelper : NSObject

/**
 * Creates a user-friendly error with code, description, and actionable suggestion.
 */
+ (NSError *)userFriendlyErrorWithCode:(PDF21MDError)code 
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