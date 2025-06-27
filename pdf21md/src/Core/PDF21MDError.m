#import "PDF21MDError.h"

NSErrorDomain const PDF21MDErrorDomain = @"com.twardoch.pdf21md.ErrorDomain";

NSString * const PDF21MDErrorPageIndexKey = @"PDF21MDErrorPageIndex";
NSString * const PDF21MDErrorFilePathKey = @"PDF21MDErrorFilePath";
NSString * const PDF21MDErrorUnderlyingErrorKey = @"PDF21MDErrorUnderlyingError";

@implementation PDF21MDErrorHelper

+ (NSError *)userFriendlyErrorWithCode:(PDF21MDError)code 
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
        userInfo[PDF21MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:code
                           userInfo:userInfo];
}

+ (NSError *)invalidPDFError {
    return [self invalidPDFErrorWithReason:nil];
}

+ (NSError *)invalidPDFErrorWithReason:(nullable NSString *)reason {
    NSString *description = reason ?: @"The PDF file appears to be corrupted or invalid";
    NSString *suggestion = @"Ensure the file is a valid PDF document. Try opening it in another PDF viewer to verify it's not corrupted.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorInvalidPDF
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)fileNotFoundErrorWithPath:(NSString *)path {
    NSString *description = [NSString stringWithFormat:@"File not found: %@", path];
    NSString *suggestion = @"Check that the file path is correct and the file exists.";
    
    NSError *error = [self userFriendlyErrorWithCode:PDF21MDErrorFileNotFound
                                         description:description
                                          suggestion:suggestion
                                     underlyingError:nil];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF21MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:PDF21MDErrorFileNotFound
                           userInfo:userInfo];
}

+ (NSError *)invalidInputErrorWithReason:(NSString *)reason {
    NSString *description = [NSString stringWithFormat:@"Invalid input: %@", reason];
    NSString *suggestion = @"Check the command line arguments and ensure all required parameters are provided correctly.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorInvalidInput
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)assetFolderCreationErrorWithPath:(NSString *)path 
                                       reason:(nullable NSString *)reason {
    NSString *description = reason ?: @"Could not create assets folder at specified path";
    NSString *suggestion = @"Ensure you have write permissions to the target directory and sufficient disk space.";
    
    NSError *error = [self userFriendlyErrorWithCode:PDF21MDErrorAssetFolderCreation
                                         description:description
                                          suggestion:suggestion
                                     underlyingError:nil];
    
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    userInfo[PDF21MDErrorFilePathKey] = path;
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:PDF21MDErrorAssetFolderCreation
                           userInfo:userInfo];
}

+ (NSError *)memoryPressureError {
    NSString *description = @"Insufficient memory to process this PDF";
    NSString *suggestion = @"Try processing a smaller PDF or close other applications to free up memory. For very large documents, consider splitting them into smaller files.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorMemoryPressure
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)processingTimeoutError {
    NSString *description = @"PDF processing timed out (document too complex)";
    NSString *suggestion = @"The PDF may be extremely large or complex. Try processing smaller sections or contact support if this persists.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorProcessingTimeout
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)encryptedPDFError {
    NSString *description = @"Password-protected PDFs are not currently supported";
    NSString *suggestion = @"Please remove the password protection from the PDF using another tool before conversion.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorEncryptedPDF
                               description:description
                                suggestion:suggestion
                           underlyingError:nil];
}

+ (NSError *)emptyDocumentError {
    NSString *description = @"The PDF contains no readable content";
    NSString *suggestion = @"The PDF may be empty, contain only images without text, or have text in an unsupported format.";
    
    return [self userFriendlyErrorWithCode:PDF21MDErrorEmptyDocument
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
        PDF21MDErrorPageIndexKey: @(pageIndex)
    } mutableCopy];
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF21MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:PDF21MDErrorPageProcessingFailed
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
        userInfo[PDF21MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:PDF21MDErrorProcessingFailed
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
        userInfo[PDF21MDErrorFilePathKey] = path;
    }
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        userInfo[PDF21MDErrorUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:PDF21MDErrorDomain
                               code:PDF21MDErrorIOFailure
                           userInfo:userInfo];
}

@end