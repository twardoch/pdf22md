#import "PDF22MDFileSystemUtils.h"
#import "PDF22MDErrorFactory.h"
#import "../src/Core/PDF22MDError.h"

@implementation PDF22MDFileSystemUtils

#pragma mark - Directory Operations

+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path]) {
        return YES;
    }
    
    return [fileManager createDirectoryAtPath:path
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:error];
}

+ (BOOL)directoryExistsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    return exists && isDirectory;
}

+ (BOOL)ensureDirectoryExists:(NSString *)path error:(NSError **)error {
    if ([self directoryExistsAtPath:path]) {
        return YES;
    }
    
    return [self createDirectoryAtPath:path error:error];
}

#pragma mark - File Operations

+ (BOOL)fileExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    if (![self fileExistsAtPath:path]) {
        return YES;
    }
    
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (NSString *)temporaryDirectoryPath {
    return NSTemporaryDirectory();
}

+ (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject ?: NSTemporaryDirectory();
}

#pragma mark - Path Utilities

+ (NSString *)sanitizeFileName:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return @"untitled";
    }
    
    NSCharacterSet *illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/:*?\"<>|\\"];
    NSString *sanitized = [[fileName componentsSeparatedByCharactersInSet:illegalCharacters] componentsJoinedByString:@"-"];
    
    sanitized = [sanitized stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (sanitized.length == 0) {
        return @"untitled";
    }
    
    if (sanitized.length > 255) {
        sanitized = [sanitized substringToIndex:255];
    }
    
    return sanitized;
}

+ (NSString *)uniqueFilePathForBaseName:(NSString *)baseName
                              extension:(NSString *)extension
                            inDirectory:(NSString *)directory {
    if (!baseName || !extension || !directory) {
        return nil;
    }
    
    NSString *sanitizedBaseName = [self sanitizeFileName:baseName];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", sanitizedBaseName, extension];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    if (![self fileExistsAtPath:filePath]) {
        return filePath;
    }
    
    NSInteger counter = 1;
    while (counter < 1000) {
        fileName = [NSString stringWithFormat:@"%@_%ld.%@", sanitizedBaseName, (long)counter, extension];
        filePath = [directory stringByAppendingPathComponent:fileName];
        
        if (![self fileExistsAtPath:filePath]) {
            return filePath;
        }
        
        counter++;
    }
    
    return nil;
}

+ (NSString *)pathByAppendingUniqueIdentifier:(NSString *)basePath {
    if (!basePath) {
        return nil;
    }
    
    if (![self fileExistsAtPath:basePath]) {
        return basePath;
    }
    
    NSString *directory = [basePath stringByDeletingLastPathComponent];
    NSString *fileName = [basePath lastPathComponent];
    NSString *extension = [fileName pathExtension];
    NSString *baseName = [fileName stringByDeletingPathExtension];
    
    return [self uniqueFilePathForBaseName:baseName extension:extension inDirectory:directory];
}

#pragma mark - Validation

+ (BOOL)isValidFilePath:(NSString *)path error:(NSError **)error {
    if (!path || path.length == 0) {
        if (error) {
            *error = [PDF22MDErrorFactory createFileSystemErrorWithCode:PDF22MDErrorInvalidPath
                                                            description:@"Path cannot be nil or empty"
                                                             suggestion:@"Provide a valid file path"];
        }
        return NO;
    }
    
    if (path.length > 4096) {
        if (error) {
            *error = [PDF22MDErrorFactory createFileSystemErrorWithCode:PDF22MDErrorInvalidPath
                                                            description:@"Path exceeds maximum length"
                                                             suggestion:@"Use a shorter file path"];
        }
        return NO;
    }
    
    NSCharacterSet *illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@"*?\"<>|"];
    if ([path rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound) {
        if (error) {
            *error = [PDF22MDErrorFactory createFileSystemErrorWithCode:PDF22MDErrorInvalidPath
                                                            description:@"Path contains illegal characters"
                                                             suggestion:@"Remove characters: *?\"<>|"];
        }
        return NO;
    }
    
    return YES;
}

+ (BOOL)hasWritePermissionForDirectory:(NSString *)path error:(NSError **)error {
    if (![self directoryExistsAtPath:path]) {
        if (error) {
            *error = [PDF22MDErrorFactory createFileSystemErrorWithCode:PDF22MDErrorDirectoryNotFound
                                                            description:[NSString stringWithFormat:@"Directory does not exist: %@", path]
                                                             suggestion:@"Create the directory first or choose an existing one"];
        }
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager isWritableFileAtPath:path]) {
        if (error) {
            *error = [PDF22MDErrorFactory createFileSystemErrorWithCode:PDF22MDErrorPermissionDenied
                                                            description:[NSString stringWithFormat:@"No write permission for directory: %@", path]
                                                             suggestion:@"Check directory permissions or choose a different location"];
        }
        return NO;
    }
    
    return YES;
}

@end