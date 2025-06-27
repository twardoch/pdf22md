#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDF22MDFileSystemUtils : NSObject

#pragma mark - Directory Operations

+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError *_Nullable *_Nullable)error;
+ (BOOL)directoryExistsAtPath:(NSString *)path;
+ (BOOL)ensureDirectoryExists:(NSString *)path error:(NSError *_Nullable *_Nullable)error;

#pragma mark - File Operations

+ (BOOL)fileExistsAtPath:(NSString *)path;
+ (BOOL)removeItemAtPath:(NSString *)path error:(NSError *_Nullable *_Nullable)error;
+ (NSString *)temporaryDirectoryPath;
+ (NSString *)documentsDirectoryPath;

#pragma mark - Path Utilities

+ (NSString *)sanitizeFileName:(NSString *)fileName;
+ (NSString *)uniqueFilePathForBaseName:(NSString *)baseName
                              extension:(NSString *)extension
                            inDirectory:(NSString *)directory;
+ (NSString *)pathByAppendingUniqueIdentifier:(NSString *)basePath;

#pragma mark - Validation

+ (BOOL)isValidFilePath:(NSString *)path error:(NSError *_Nullable *_Nullable)error;
+ (BOOL)hasWritePermissionForDirectory:(NSString *)path error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END