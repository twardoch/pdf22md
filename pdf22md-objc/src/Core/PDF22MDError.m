#import "PDF22MDError.h"

NSErrorDomain const PDF22MDErrorDomain = @"com.twardoch.pdf22md.ErrorDomain";

NSString * const PDF22MDErrorPageIndexKey = @"PDF22MDErrorPageIndex";
NSString * const PDF22MDErrorFilePathKey = @"PDF22MDErrorFilePath";
NSString * const PDF22MDErrorUnderlyingErrorKey = @"PDF22MDErrorUnderlyingError";

@implementation PDF22MDErrorHelper

+ (NSError *)userFriendlyErrorWithCode:(PDF22MDError)code 
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
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:code
                           userInfo:userInfo];
}

+ (NSError *)invalidPDFError {
    return [self invalidPDFErrorWithReason:nil];
}

+ (NSError *)invalidPDFErrorWithReason:(nullable NSString *)reason {
    NSString *description = reason ?: @"The PDF file appears to be corrupted or invalid";
    NSString *suggestion = @"Ensure the file is a valid PDF document. Try opening it in another PDF viewer to verify it's not corrupted.";
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorInvalidPDF
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)fileNotFoundErrorWithPath:(NSString *)path {
    NSString *description = [NSString stringWithFormat:@"File not found: %@", path];
    NSString *suggestion = @"Check that the file path is correct and the file exists.";
    
    NSError *error = [self userFriendlyErrorWithCode:PDF22MDErrorFileNotFound
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
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorInvalidInput
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)assetFolderCreationErrorWithPath:(NSString *)path 
                                       reason:(nullable NSString *)reason {
    NSString *description = reason ?: @"Could not create assets folder at specified path";
    NSString *suggestion = @"Ensure you have write permissions to the target directory and sufficient disk space.";
    
    NSError *error = [self userFriendlyErrorWithCode:PDF22MDErrorAssetFolderCreation
                                         description:description
                                          suggestion:suggestion
                                     underlyingError:nil];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF22MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorAssetFolderCreation
                           userInfo:userInfo];
}

+ (NSError *)memoryPressureError {
    NSString *description = @"Insufficient memory to process this PDF";
    NSString *suggestion = @"Try processing a smaller PDF or close other applications to free up memory. For very large documents, consider splitting them into smaller files.";
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorMemoryPressure
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)processingTimeoutError {
    NSString *description = @"PDF processing timed out (document too complex)";
    NSString *suggestion = @"The PDF may be extremely large or complex. Try processing smaller sections or contact support if this persists.";
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorProcessingTimeout
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)encryptedPDFError {
    NSString *description = @"Password-protected PDFs are not currently supported";
    NSString *suggestion = @"Please remove the password protection from the PDF using another tool before conversion.";
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorEncryptedPDF
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)emptyDocumentError {
    NSString *description = @"The PDF contains no readable content";
    NSString *suggestion = @"The PDF may be empty, contain only images without text, or have text in an unsupported format.";
    
    return [self userFriendlyErrorWithCode:PDF22MDErrorEmptyDocument
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)assetCreationFailedErrorWithPath:(NSString *)path 
                                         reason:(nullable NSString *)reason {
    // This method is deprecated in favor of assetFolderCreationErrorWithPath:reason:
    return [self assetFolderCreationErrorWithPath:path reason:reason];
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