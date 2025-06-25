//
//  PDF22MDErrorFactory.m
//  pdf22md - Shared Components
//
//  Unified error creation factory for consistent error handling
//  across all implementations and components.
//

#import "PDF22MDErrorFactory.h"

// Import error constants from implementation-specific header
// This ensures we use the same error domain and codes consistently
extern NSErrorDomain const PDF22MDErrorDomain;

// Error codes - using constants to avoid redefinition
#define PDF22MDErrorInvalidConfiguration 1004
#define PDF22MDErrorInvalidPDF 1000
#define PDF22MDErrorFileNotFound 1012
#define PDF22MDErrorInvalidInput 1011
#define PDF22MDErrorAssetFolderCreation 1001
#define PDF22MDErrorMemoryPressure 1006
#define PDF22MDErrorProcessingTimeout 1008
#define PDF22MDErrorEncryptedPDF 1009
#define PDF22MDErrorEmptyDocument 1010
#define PDF22MDErrorPageProcessingFailed 1003
#define PDF22MDErrorProcessingFailed 1002
#define PDF22MDErrorIOFailure 1005

// Error keys
extern NSString * const PDF22MDErrorPageIndexKey;
extern NSString * const PDF22MDErrorFilePathKey;
extern NSString * const PDF22MDErrorUnderlyingErrorKey;

@implementation PDF22MDErrorFactory

#pragma mark - Core Factory Methods

+ (NSError *)createErrorForDomain:(NSErrorDomain)domain
                             code:(NSInteger)code
                      description:(NSString *)description
                       suggestion:(nullable NSString *)suggestion
                  underlyingError:(nullable NSError *)underlyingError {
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description
    } mutableCopy];
    
    if (suggestion) {
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion;
    }
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF22MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:domain
                               code:code
                           userInfo:userInfo];
}

#pragma mark - Configuration Error Factory Methods

+ (NSError *)invalidConfigurationErrorWithField:(NSString *)fieldName
                                         reason:(NSString *)reason
                                     suggestion:(NSString *)suggestion {
    NSString *description = [NSString stringWithFormat:@"Invalid %@: %@", fieldName, reason];
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorInvalidConfiguration
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)invalidDPIErrorWithValue:(CGFloat)dpiValue {
    NSString *reason = [NSString stringWithFormat:@"DPI value %.1f is invalid", dpiValue];
    NSString *suggestion = @"DPI must be between 1 and 600";
    
    return [self invalidConfigurationErrorWithField:@"rasterization DPI"
                                              reason:reason
                                          suggestion:suggestion];
}

+ (NSError *)invalidConcurrentPagesErrorWithValue:(NSInteger)pageCount {
    NSString *reason = [NSString stringWithFormat:@"concurrent pages value %ld is invalid", (long)pageCount];
    NSString *suggestion = @"Value must be between 1 and 64";
    
    return [self invalidConfigurationErrorWithField:@"max concurrent pages"
                                              reason:reason
                                          suggestion:suggestion];
}

+ (NSError *)invalidHeadingLevelErrorWithValue:(NSInteger)headingLevel {
    NSString *reason = [NSString stringWithFormat:@"heading level %ld is invalid", (long)headingLevel];
    NSString *suggestion = @"Heading level must be between 1 and 6";
    
    return [self invalidConfigurationErrorWithField:@"max heading level"
                                              reason:reason
                                          suggestion:suggestion];
}

+ (NSError *)invalidFontSizeThresholdErrorWithValue:(CGFloat)threshold {
    NSString *reason = [NSString stringWithFormat:@"font size threshold %.1f is invalid", threshold];
    NSString *suggestion = @"Threshold must be between 0.5 and 10.0 points";
    
    return [self invalidConfigurationErrorWithField:@"heading font size threshold"
                                              reason:reason
                                          suggestion:suggestion];
}

#pragma mark - File System Error Factory Methods

+ (NSError *)invalidPDFErrorWithPath:(NSString *)path
                     underlyingError:(nullable NSError *)underlyingError {
    NSString *description = [NSString stringWithFormat:@"The PDF file appears to be corrupted or invalid: %@", path];
    NSString *suggestion = @"Ensure the file is a valid PDF document. Try opening it in another PDF viewer to verify it's not corrupted.";
    
    NSError *error = [self createErrorForDomain:PDF22MDErrorDomain
                                           code:PDF22MDErrorInvalidPDF
                                    description:description
                                     suggestion:suggestion
                                underlyingError:underlyingError];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF22MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorInvalidPDF
                           userInfo:userInfo];
}

+ (NSError *)fileNotFoundErrorWithPath:(NSString *)path {
    NSString *description = [NSString stringWithFormat:@"File not found: %@", path];
    NSString *suggestion = @"Check that the file path is correct and the file exists.";
    
    NSError *error = [self createErrorForDomain:PDF22MDErrorDomain
                                           code:PDF22MDErrorFileNotFound
                                    description:description
                                     suggestion:suggestion
                                underlyingError:nil];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF22MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorFileNotFound
                           userInfo:userInfo];
}

+ (NSError *)invalidInputErrorWithReason:(NSString *)reason {
    NSString *description = [NSString stringWithFormat:@"Invalid input: %@", reason];
    NSString *suggestion = @"Check the command line arguments and ensure all required parameters are provided correctly.";
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorInvalidInput
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)assetCreationErrorWithPath:(NSString *)path
                                 reason:(NSString *)reason {
    NSString *description = [NSString stringWithFormat:@"Could not create assets folder at %@: %@", path, reason];
    NSString *suggestion = @"Ensure you have write permissions to the target directory and sufficient disk space.";
    
    NSError *error = [self createErrorForDomain:PDF22MDErrorDomain
                                           code:PDF22MDErrorAssetFolderCreation
                                    description:description
                                     suggestion:suggestion
                                underlyingError:nil];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF22MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorAssetFolderCreation
                           userInfo:userInfo];
}

#pragma mark - Processing Error Factory Methods

+ (NSError *)memoryPressureErrorWithContext:(NSString *)context {
    NSString *description = [NSString stringWithFormat:@"Insufficient memory to process PDF during %@", context];
    NSString *suggestion = @"Try processing a smaller PDF or close other applications to free up memory. For very large documents, consider splitting them into smaller files.";
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorMemoryPressure
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)processingTimeoutErrorWithDuration:(NSTimeInterval)duration {
    NSString *description = [NSString stringWithFormat:@"PDF processing timed out after %.1f seconds (document too complex)", duration];
    NSString *suggestion = @"The PDF may be extremely large or complex. Try processing smaller sections or contact support if this persists.";
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorProcessingTimeout
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)encryptedPDFError {
    NSString *description = @"Password-protected PDFs are not currently supported";
    NSString *suggestion = @"Please remove the password protection from the PDF using another tool before conversion.";
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorEncryptedPDF
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)emptyDocumentError {
    NSString *description = @"The PDF contains no readable content";
    NSString *suggestion = @"The PDF may be empty, contain only images without text, or have text in an unsupported format.";
    
    return [self createErrorForDomain:PDF22MDErrorDomain
                                 code:PDF22MDErrorEmptyDocument
                          description:description
                           suggestion:suggestion
                      underlyingError:nil];
}

+ (NSError *)pageProcessingFailedErrorForPage:(NSInteger)pageIndex 
                                       reason:(nullable NSString *)reason
                              underlyingError:(nullable NSError *)underlyingError {
    NSString *description = [NSString stringWithFormat:@"Failed to process page %ld", (long)(pageIndex + 1)];
    NSString *failureReason = reason ?: @"An error occurred while extracting content from the page";
    
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: failureReason,
        NSLocalizedRecoverySuggestionErrorKey: @"The page may contain unsupported content or be corrupted",
        PDF22MDErrorPageIndexKey: @(pageIndex)
    } mutableCopy];
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF22MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorPageProcessingFailed
                           userInfo:userInfo];
}

+ (NSError *)processingFailedErrorWithReason:(NSString *)reason 
                             underlyingError:(nullable NSError *)underlyingError {
    NSString *description = @"PDF processing failed";
    
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: reason,
        NSLocalizedRecoverySuggestionErrorKey: @"Check the input file and try again"
    } mutableCopy];
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF22MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorProcessingFailed
                           userInfo:userInfo];
}

+ (NSError *)ioFailureErrorWithPath:(nullable NSString *)path 
                             reason:(NSString *)reason
                    underlyingError:(nullable NSError *)underlyingError {
    NSString *description = @"File I/O operation failed";
    
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: reason,
        NSLocalizedRecoverySuggestionErrorKey: @"Check file permissions and available disk space"
    } mutableCopy];
    
    if (path) {
        userInfo[PDF22MDErrorFilePathKey] = path;
    }
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF22MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorIOFailure
                           userInfo:userInfo];
}

@end