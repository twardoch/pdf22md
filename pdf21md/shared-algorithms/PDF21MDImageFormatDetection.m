//
//  PDF21MDImageFormatDetection.m
//  pdf21md - Shared Components
//
//  Shared utility for determining optimal image format (JPEG vs PNG)
//  based on image characteristics and source type.
//

#import "PDF21MDImageFormatDetection.h"

@implementation PDF21MDImageFormatDetection

+ (BOOL)shouldUseJPEGForImage:(CGImageRef)image 
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

+ (NSUInteger)estimateUniqueColorCountForImage:(CGImageRef)image {
    if (!image) {
        return 0;
    }
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    // Don't analyze extremely large images - assume they're complex
    if (width * height > 4000000) { // Larger than ~2000x2000
        return 10000; // Assume high complexity
    }
    
    // Create a bitmap context for pixel analysis
    uint32_t *pixelData = malloc(sizeof(uint32_t));
    if (!pixelData) {
        return 0;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, 8, 4,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast |
                                               kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        free(pixelData);
        return 0;
    }
    
    // Sample the image at regular intervals
    size_t stepX = MAX(1, width / 100);   // Sample ~100 points horizontally
    size_t stepY = MAX(1, height / 100);  // Sample ~100 points vertically
    
    // Count unique colors by sampling
    NSMutableSet *uniqueColors = [NSMutableSet set];
    
    for (size_t y = 0; y < height; y += stepY) {
        for (size_t x = 0; x < width; x += stepX) {
            // Draw a single pixel
            CGContextClearRect(context, CGRectMake(0, 0, 1, 1));
            CGContextDrawImage(context, CGRectMake(-x, -y, width, height), image);
            
            uint32_t color = pixelData[0];
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

+ (NSString *)recommendedExtensionForImage:(CGImageRef)image 
                            isVectorSource:(BOOL)isVectorSource {
    return [self shouldUseJPEGForImage:image isVectorSource:isVectorSource] ? @"jpg" : @"png";
}

@end