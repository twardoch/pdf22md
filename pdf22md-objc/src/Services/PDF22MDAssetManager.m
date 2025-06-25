#import "PDF22MDAssetManager.h"
#import "../Models/PDF22MDImageElement.h"
#import "../../shared/Algorithms/PDF22MDImageFormatDetection.h"
#import "../../shared/Core/PDF22MDConcurrencyManager.h"
#import "../../shared/Core/PDF22MDFileSystemUtils.h"
#import "../../shared/Core/PDF22MDConstants.h"
#import <ImageIO/ImageIO.h>

@interface PDF22MDAssetManager ()
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) dispatch_queue_t fileAccessQueue;
@property (nonatomic, strong) NSMutableSet<NSString *> *usedFilenames;
@end

@implementation PDF22MDAssetManager

#pragma mark - Initialization

- (nullable instancetype)initWithAssetFolder:(NSString *)folderPath {
    self = [super init];
    if (self) {
        _assetsFolderPath = [folderPath copy];
        _fileManager = [[NSFileManager alloc] init];
        _fileAccessQueue = [PDF22MDConcurrencyManager sharedFileAccessQueue];
        _usedFilenames = [NSMutableSet set];
        
        // Create assets folder if it doesn't exist
        NSError *error = nil;
        if (![PDF22MDFileSystemUtils ensureDirectoryExists:folderPath error:&error]) {
            NSLog(@"Failed to create assets folder: %@", error);
            return nil;
        }
    }
    return self;
}

#pragma mark - Public Methods

- (nullable NSString *)saveImage:(CGImageRef)image
                  isVectorSource:(BOOL)isVectorSource
                    withBaseName:(NSString *)baseName {
    if (!image) {
        return nil;
    }
    
    // Determine optimal format
    BOOL shouldUseJPEG = [PDF22MDImageFormatDetection shouldUseJPEGForImage:image isVectorSource:isVectorSource];
    
    NSString *extension = shouldUseJPEG ? @"jpg" : @"png";
    NSString *fileName = [self uniqueFilenameForBaseName:baseName withExtension:extension];
    NSString *fullPath = [self.assetsFolderPath stringByAppendingPathComponent:fileName];
    
    // Create destination
    NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
        (__bridge CFURLRef)fileURL,
        shouldUseJPEG ? (__bridge CFStringRef)@"public.jpeg" : (__bridge CFStringRef)@"public.png",
        1,
        NULL
    );
    
    if (!destination) {
        NSLog(@"Failed to create image destination for %@", fullPath);
        return nil;
    }
    
    // Set compression options
    NSDictionary *properties = nil;
    if (shouldUseJPEG) {
        properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(0.85)};
    } else {
        properties = @{(__bridge NSString *)kCGImagePropertyPNGCompressionFilter: @(1)};
    }
    
    // Add image to destination
    CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)properties);
    
    // Finalize
    BOOL success = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    if (!success) {
        NSLog(@"Failed to save image to %@", fullPath);
        return nil;
    }
    
    // Return relative path (just the filename since it's in the assets folder)
    return fileName;
}

- (nullable NSString *)saveImageElement:(PDF22MDImageElement *)imageElement
                           withBaseName:(NSString *)baseName {
    NSString *savedPath = [self saveImage:imageElement.image
                           isVectorSource:imageElement.isVectorSource
                             withBaseName:baseName];
    
    if (savedPath) {
        imageElement.assetRelativePath = savedPath;
    }
    
    return savedPath;
}


- (NSString *)uniqueFilenameForBaseName:(NSString *)baseName
                          withExtension:(NSString *)extension {
    __block NSString *filename = nil;
    
    dispatch_sync(self.fileAccessQueue, ^{
        NSString *fullPath = [PDF22MDFileSystemUtils uniqueFilePathForBaseName:baseName
                                                                      extension:extension
                                                                    inDirectory:self.assetsFolderPath];
        if (fullPath) {
            filename = [fullPath lastPathComponent];
            [self.usedFilenames addObject:filename];
        } else {
            // Fallback to timestamp-based naming if unique path generation fails
            NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
            filename = [NSString stringWithFormat:@"%@_%.0f.%@", baseName, timestamp, extension];
            [self.usedFilenames addObject:filename];
        }
    });
    
    return filename;
}


@end