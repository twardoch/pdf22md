//
//  PDF22MDErrorFactory.h
//  pdf22md - Shared Components
//
//  Unified error creation factory for consistent error handling
//  across all implementations and components.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declaration - error constants defined in implementation-specific headers
typedef NS_ENUM(NSInteger, PDF22MDError);

/**
 * Unified error factory for creating consistent, user-friendly error objects
 * across all PDF22MD implementations and components.
 */
@interface PDF22MDErrorFactory : NSObject

#pragma mark - Core Factory Methods

/**
 * Creates a user-friendly error with code, description, and actionable suggestion.
 */
+ (NSError *)createErrorForDomain:(NSErrorDomain)domain
                             code:(NSInteger)code
                      description:(NSString *)description
                       suggestion:(nullable NSString *)suggestion
                  underlyingError:(nullable NSError *)underlyingError;

#pragma mark - Configuration Error Factory Methods

/**
 * Creates an error for invalid configuration with specific validation details.
 */
+ (NSError *)invalidConfigurationErrorWithField:(NSString *)fieldName
                                         reason:(NSString *)reason
                                     suggestion:(NSString *)suggestion;

/**
 * Creates an error for invalid DPI value.
 */
+ (NSError *)invalidDPIErrorWithValue:(CGFloat)dpiValue;

/**
 * Creates an error for invalid concurrent pages value.
 */
+ (NSError *)invalidConcurrentPagesErrorWithValue:(NSInteger)pageCount;

/**
 * Creates an error for invalid heading level value.
 */
+ (NSError *)invalidHeadingLevelErrorWithValue:(NSInteger)headingLevel;

/**
 * Creates an error for invalid font size threshold.
 */
+ (NSError *)invalidFontSizeThresholdErrorWithValue:(CGFloat)threshold;

#pragma mark - File System Error Factory Methods

/**
 * Creates an error for invalid PDF input.
 */
+ (NSError *)invalidPDFErrorWithPath:(NSString *)path
                     underlyingError:(nullable NSError *)underlyingError;

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
+ (NSError *)assetCreationErrorWithPath:(NSString *)path
                                 reason:(NSString *)reason;

#pragma mark - Processing Error Factory Methods

/**
 * Creates an error for memory pressure.
 */
+ (NSError *)memoryPressureErrorWithContext:(NSString *)context;

/**
 * Creates an error for processing timeout.
 */
+ (NSError *)processingTimeoutErrorWithDuration:(NSTimeInterval)duration;

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