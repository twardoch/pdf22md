#import "PDF22MDAssetManager.h"
#import "../Models/PDF22MDImageElement.h"
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
        _fileAccessQueue = dispatch_queue_create("com.twardoch.pdf22md.assetmanager", DISPATCH_QUEUE_SERIAL);
        _usedFilenames = [NSMutableSet set];
        
        // Create assets folder if it doesn't exist
        NSError *error = nil;
        BOOL isDirectory = NO;
        BOOL exists = [_fileManager fileExistsAtPath:folderPath isDirectory:&isDirectory];
        
        if (exists && !isDirectory) {
            NSLog(@"Asset path exists but is not a directory: %@", folderPath);
            return nil;
        }
        
        if (!exists) {
            if (![_fileManager createDirectoryAtPath:folderPath
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error]) {
                NSLog(@"Failed to create assets folder: %@", error);
                return nil;
            }
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
    BOOL shouldUseJPEG = [self shouldUseJPEGForImage:image isVectorSource:isVectorSource];
    
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
        // For PNG, we can set compression level
        properties = @{(__bridge NSString *)kCGImagePropertyPNGCompressionFilter: @(1)}; // Best compression
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

- (BOOL)shouldUseJPEGForImage:(CGImageRef)image
                isVectorSource:(BOOL)isVectorSource {
    if (!image) {
        return NO;
    }
    
    // Get image properties
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
    
    // If image has alpha channel, use PNG
    if (alphaInfo != kCGImageAlphaNone &&
        alphaInfo != kCGImageAlphaNoneSkipFirst &&
        alphaInfo != kCGImageAlphaNoneSkipLast) {
        return NO;
    }
    
    // For small images, use PNG
    if (width * height < 10000) { // Less than 100x100
        return NO;
    }
    
    // For vector sources, prefer PNG to maintain quality
    if (isVectorSource) {
        return NO;
    }
    
    // Analyze color complexity
    NSUInteger uniqueColors = [self estimateUniqueColorCountForImage:image];
    
    // If we have many unique colors, it's likely a photograph - use JPEG
    return uniqueColors > 256;
}

- (NSString *)uniqueFilenameForBaseName:(NSString *)baseName
                          withExtension:(NSString *)extension {
    __block NSString *filename = nil;
    
    dispatch_sync(self.fileAccessQueue, ^{
        NSString *candidate = [NSString stringWithFormat:@"%@.%@", baseName, extension];
        NSInteger counter = 1;
        
        // Check if filename is already used
        while ([self.usedFilenames containsObject:candidate] ||
               [self.fileManager fileExistsAtPath:[self.assetsFolderPath stringByAppendingPathComponent:candidate]]) {
            candidate = [NSString stringWithFormat:@"%@_%03ld.%@", baseName, (long)counter, extension];
            counter++;
        }
        
        [self.usedFilenames addObject:candidate];
        filename = candidate;
    });
    
    return filename;
}

#pragma mark - Private Methods

- (NSUInteger)estimateUniqueColorCountForImage:(CGImageRef)image {
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    // Sample a subset of pixels for performance
    size_t __unused sampleSize = MIN(width * height, 10000);
    size_t stepX = MAX(1, width / 100);
    size_t stepY = MAX(1, height / 100);
    
    // Create a small bitmap context for sampling
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bytesPerRow = 4; // Single pixel
    unsigned char *pixelData = calloc(4, sizeof(unsigned char));
    
    if (!pixelData) {
        CGColorSpaceRelease(colorSpace);
        return 256; // Default to medium complexity
    }
    
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, 8, bytesPerRow, colorSpace,
                                                kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        free(pixelData);
        return 256;
    }
    
    // Count unique colors by sampling
    NSMutableSet *uniqueColors = [NSMutableSet set];
    
    for (size_t y = 0; y < height; y += stepY) {
        for (size_t x = 0; x < width; x += stepX) {
            // Draw a single pixel
            CGRect __unused sourceRect = CGRectMake(x, y, 1, 1);
            CGContextClearRect(context, CGRectMake(0, 0, 1, 1));
            CGContextDrawImage(context, CGRectMake(-x, -y, width, height), image);
            
            uint32_t color = (pixelData[0] << 24) | (pixelData[1] << 16) | 
                           (pixelData[2] << 8) | pixelData[3];
            [uniqueColors addObject:@(color)];
            
            // Early exit if we already have many colors
            if (uniqueColors.count > 1000) {
                break;
            }
        }
        
        if (uniqueColors.count > 1000) {
            break;
        }
    }
    
    CGContextRelease(context);
    free(pixelData);
    
    return uniqueColors.count;
}

@end