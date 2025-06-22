#import "AssetExtractor.h"
#import <ImageIO/ImageIO.h>

@interface AssetExtractor ()
@property (nonatomic, strong) NSString *assetFolderPath;
@property (nonatomic, strong) NSFileManager *fileManager;
@end

@implementation AssetExtractor

- (nullable instancetype)initWithAssetFolder:(NSString *)folderPath {
    self = [super init];
    if (self) {
        _assetFolderPath = folderPath;
        _fileManager = [NSFileManager defaultManager];
        
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

- (nullable NSString *)saveImage:(CGImageRef)image
                  isVectorSource:(BOOL)isVector
                      withBaseName:(NSString *)baseName {
    if (!image) {
        return nil;
    }
    
    // Analyze image to determine optimal format
    BOOL shouldUseJPEG = [self shouldUseJPEGForImage:image];
    
    NSString *extension = shouldUseJPEG ? @"jpg" : @"png";
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", baseName, extension];
    NSString *fullPath = [self.assetFolderPath stringByAppendingPathComponent:fileName];
    
    // Create destination
    NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL,
                                                                       shouldUseJPEG ? (__bridge CFStringRef)@"public.jpeg" : (__bridge CFStringRef)@"public.png",
                                                                       1, NULL);
    if (!destination) {
        NSLog(@"Failed to create image destination");
        return nil;
    }
    
    // Set compression options
    NSDictionary *properties = nil;
    if (shouldUseJPEG) {
        properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @0.85};
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

- (BOOL)shouldUseJPEGForImage:(CGImageRef)image {
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
    
    // Analyze color complexity by sampling pixels
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bytesPerRow = width * 4;
    size_t sampleSize = MIN(width * height, 10000); // Sample up to 10k pixels
    
    unsigned char *pixelData = calloc(sampleSize * 4, sizeof(unsigned char));
    if (!pixelData) {
        CGColorSpaceRelease(colorSpace);
        return YES; // Default to JPEG if we can't analyze
    }
    
    CGContextRef context = CGBitmapContextCreate(pixelData, width, 1, 8, bytesPerRow, colorSpace,
                                                kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        free(pixelData);
        return YES;
    }
    
    // Sample middle row
    CGContextDrawImage(context, CGRectMake(0, 0, width, 1), image);
    CGContextRelease(context);
    
    // Count unique colors in sample
    NSMutableSet *uniqueColors = [NSMutableSet set];
    for (size_t i = 0; i < width * 4; i += 4) {
        uint32_t color = (pixelData[i] << 24) | (pixelData[i+1] << 16) | 
                        (pixelData[i+2] << 8) | pixelData[i+3];
        [uniqueColors addObject:@(color)];
    }
    
    free(pixelData);
    
    // If we have many unique colors, it's likely a photograph - use JPEG
    return [uniqueColors count] > 256;
}

@end