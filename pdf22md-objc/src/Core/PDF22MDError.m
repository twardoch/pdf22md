#import "PDF22MDError.h"

NSErrorDomain const PDF22MDErrorDomain = @"com.twardoch.pdf22md.ErrorDomain";

NSString * const PDF22MDErrorPageIndexKey = @"PDF22MDErrorPageIndex";
NSString * const PDF22MDErrorFilePathKey = @"PDF22MDErrorFilePath";
NSString * const PDF22MDErrorUnderlyingErrorKey = @"PDF22MDErrorUnderlyingError";

@implementation PDF22MDErrorHelper

+ (NSError *)invalidPDFError {
    return [self invalidPDFErrorWithReason:nil];
}

+ (NSError *)invalidPDFErrorWithReason:(nullable NSString *)reason {
    NSString *description = @"Invalid or corrupted PDF file";
    NSString *failureReason = reason ?: @"The PDF document could not be opened or parsed";
    
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: failureReason,
        NSLocalizedRecoverySuggestionErrorKey: @"Ensure the file is a valid PDF document and is not corrupted"
    };
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorInvalidPDF
                           userInfo:userInfo];
}

+ (NSError *)assetCreationFailedErrorWithPath:(NSString *)path 
                                         reason:(nullable NSString *)reason {
    NSString *description = @"Failed to create or save asset";
    NSString *failureReason = reason ?: [NSString stringWithFormat:@"Could not save asset to path: %@", path];
    
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: failureReason,
        NSLocalizedRecoverySuggestionErrorKey: @"Check that the directory exists and you have write permissions"
    } mutableCopy];
    
    if (path) {
        userInfo[PDF22MDErrorFilePathKey] = path;
    }
    
    return [NSError errorWithDomain:PDF22MDErrorDomain
                               code:PDF22MDErrorAssetCreationFailed
                           userInfo:userInfo];
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