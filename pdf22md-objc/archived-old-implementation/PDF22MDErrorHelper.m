//
//  PDF22MDErrorHelper.m
//  pdf22md
//
//  Enhanced error handling with user-friendly messages and suggestions
//

#import "PDF22MDErrorHelper.h"

NSErrorDomain const PDF22MDErrorDomain = @"com.twardoch.pdf22md.error";

@implementation PDF22MDErrorHelper

+ (NSError *)errorWithCode:(PDF22MDError)code
               description:(NSString *)description
                suggestion:(NSString *)suggestion {
    return [self errorWithCode:code
                   description:description
                    suggestion:suggestion
               underlyingError:nil];
}

+ (NSError *)errorWithCode:(PDF22MDError)code
               description:(NSString *)description
                suggestion:(NSString *)suggestion
           underlyingError:(nullable NSError *)underlyingError {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion;
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    
    // Add additional context based on error code
    switch (code) {
        case PDF22MDErrorInvalidPDF:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"The PDF file appears to be corrupted or in an unsupported format";
            break;
        case PDF22MDErrorAssetFolderCreation:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"Unable to create the specified assets folder";
            break;
        case PDF22MDErrorMemoryPressure:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"Insufficient memory to process this PDF";
            break;
        case PDF22MDErrorProcessingTimeout:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"PDF processing timed out";
            break;
        case PDF22MDErrorEncryptedPDF:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"The PDF is password-protected";
            break;
        case PDF22MDErrorEmptyDocument:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"The PDF contains no readable content";
            break;
        case PDF22MDErrorIOError:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"File input/output error occurred";
            break;
        case PDF22MDErrorPermissionDenied:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"Insufficient permissions to access the file or folder";
            break;
        case PDF22MDErrorUnsupportedFormat:
            userInfo[NSLocalizedFailureReasonErrorKey] = @"The PDF format or version is not supported";
            break;
    }
    
    return [NSError errorWithDomain:PDF22MDErrorDomain code:code userInfo:userInfo];
}

#pragma mark - Factory Methods

+ (NSError *)invalidPDFErrorWithPath:(NSString *)path {
    NSString *description = [NSString stringWithFormat:@"Cannot open PDF file: %@", path];
    NSString *suggestion = @"• Verify the file exists and is a valid PDF\n"
                          @"• Check if the file is corrupted\n"
                          @"• Ensure you have read permissions for the file";
    
    return [self errorWithCode:PDF22MDErrorInvalidPDF
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)assetFolderErrorWithPath:(NSString *)path reason:(NSString *)reason {
    NSString *description = [NSString stringWithFormat:@"Cannot create assets folder: %@", path];
    NSString *suggestion = [NSString stringWithFormat:@"• Check if the parent directory exists\n"
                                                      @"• Verify you have write permissions\n"
                                                      @"• Ensure sufficient disk space\n"
                                                      @"• Error details: %@", reason];
    
    return [self errorWithCode:PDF22MDErrorAssetFolderCreation
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)memoryPressureError {
    NSString *description = @"Insufficient memory to process this PDF";
    NSString *suggestion = @"• Close other applications to free memory\n"
                          @"• Try processing a smaller PDF file\n"
                          @"• Consider using a lower DPI setting (-d 72)\n"
                          @"• If the PDF is very large, split it into smaller parts";
    
    return [self errorWithCode:PDF22MDErrorMemoryPressure
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)encryptedPDFError {
    NSString *description = @"Cannot process password-protected PDF";
    NSString *suggestion = @"• Remove password protection using another tool first\n"
                          @"• Use Adobe Acrobat or similar to unlock the PDF\n"
                          @"• Try: qpdf --decrypt input.pdf output.pdf";
    
    return [self errorWithCode:PDF22MDErrorEncryptedPDF
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)emptyDocumentError {
    NSString *description = @"PDF contains no readable text or content";
    NSString *suggestion = @"• Check if the PDF has text (not just scanned images)\n"
                          @"• For scanned documents, use OCR software first\n"
                          @"• Verify the PDF is not corrupted";
    
    return [self errorWithCode:PDF22MDErrorEmptyDocument
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)ioErrorWithPath:(NSString *)path operation:(NSString *)operation {
    NSString *description = [NSString stringWithFormat:@"Failed to %@ file: %@", operation, path];
    NSString *suggestion = @"• Check if the file path is correct\n"
                          @"• Verify you have appropriate permissions\n"
                          @"• Ensure sufficient disk space\n"
                          @"• Check if the file is in use by another application";
    
    return [self errorWithCode:PDF22MDErrorIOError
                   description:description
                    suggestion:suggestion];
}

+ (NSError *)permissionErrorWithPath:(NSString *)path {
    NSString *description = [NSString stringWithFormat:@"Permission denied accessing: %@", path];
    NSString *suggestion = @"• Check file permissions with: ls -la\n"
                          @"• Use: chmod 644 for files, chmod 755 for directories\n"
                          @"• Ensure you own the file or have appropriate access\n"
                          @"• Try running with sudo if appropriate";
    
    return [self errorWithCode:PDF22MDErrorPermissionDenied
                   description:description
                    suggestion:suggestion];
}

#pragma mark - User-Friendly Formatting

+ (NSString *)userFriendlyMessageForError:(NSError *)error {
    if (![error.domain isEqualToString:PDF22MDErrorDomain]) {
        // For non-PDF22MD errors, provide basic formatting
        return [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    }
    
    NSMutableString *message = [NSMutableString string];
    
    // Add main description
    [message appendFormat:@"❌ %@\n", error.localizedDescription];
    
    // Add failure reason if available
    NSString *failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey];
    if (failureReason) {
        [message appendFormat:@"\n💡 %@\n", failureReason];
    }
    
    // Add suggestions if available
    NSString *suggestion = error.userInfo[NSLocalizedRecoverySuggestionErrorKey];
    if (suggestion) {
        [message appendFormat:@"\n🔧 Try these solutions:\n%@\n", suggestion];
    }
    
    // Add underlying error details if available
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    if (underlyingError) {
        [message appendFormat:@"\n📋 Technical details: %@", underlyingError.localizedDescription];
    }
    
    return message;
}

@end