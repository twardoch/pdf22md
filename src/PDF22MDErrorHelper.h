//
//  PDF22MDErrorHelper.h
//  pdf22md
//
//  Enhanced error handling with user-friendly messages and suggestions
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Error domain for pdf22md errors
extern NSErrorDomain const PDF22MDErrorDomain;

// Specific error codes with clear meanings
typedef NS_ENUM(NSInteger, PDF22MDError) {
    PDF22MDErrorInvalidPDF = 1000,          // PDF file is corrupted or invalid
    PDF22MDErrorAssetFolderCreation,        // Cannot create assets folder
    PDF22MDErrorMemoryPressure,            // Insufficient memory
    PDF22MDErrorProcessingTimeout,         // Processing took too long
    PDF22MDErrorEncryptedPDF,              // Password-protected PDF
    PDF22MDErrorEmptyDocument,             // PDF has no readable content
    PDF22MDErrorIOError,                   // File I/O error
    PDF22MDErrorPermissionDenied,          // Insufficient permissions
    PDF22MDErrorUnsupportedFormat          // PDF format not supported
};

/**
 * Helper class for creating user-friendly error messages with actionable suggestions
 */
@interface PDF22MDErrorHelper : NSObject

/**
 * Creates a user-friendly error with description and suggestion
 */
+ (NSError *)errorWithCode:(PDF22MDError)code
               description:(NSString *)description
                suggestion:(NSString *)suggestion;

/**
 * Creates a user-friendly error with underlying error context
 */
+ (NSError *)errorWithCode:(PDF22MDError)code
               description:(NSString *)description
                suggestion:(NSString *)suggestion
           underlyingError:(nullable NSError *)underlyingError;

/**
 * Common error factory methods
 */
+ (NSError *)invalidPDFErrorWithPath:(NSString *)path;
+ (NSError *)assetFolderErrorWithPath:(NSString *)path reason:(NSString *)reason;
+ (NSError *)memoryPressureError;
+ (NSError *)encryptedPDFError;
+ (NSError *)emptyDocumentError;
+ (NSError *)ioErrorWithPath:(NSString *)path operation:(NSString *)operation;
+ (NSError *)permissionErrorWithPath:(NSString *)path;

/**
 * Formats error for command-line display
 */
+ (NSString *)userFriendlyMessageForError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END