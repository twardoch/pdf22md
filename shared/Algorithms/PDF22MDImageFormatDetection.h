//
//  PDF22MDImageFormatDetection.h
//  pdf22md - Shared Components
//
//  Shared utility for determining optimal image format (JPEG vs PNG)
//  based on image characteristics and source type.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Shared utility class for image format detection and optimization.
 * Determines whether to use JPEG or PNG format based on image characteristics.
 */
@interface PDF22MDImageFormatDetection : NSObject

/**
 * Determines whether JPEG format should be used for an image.
 * 
 * @param image The CGImageRef to analyze
 * @param isVectorSource Whether the image originates from a vector source
 * @return YES if JPEG is recommended, NO if PNG is recommended
 */
+ (BOOL)shouldUseJPEGForImage:(CGImageRef)image 
               isVectorSource:(BOOL)isVectorSource;

/**
 * Estimates the number of unique colors in an image through sampling.
 * Used to determine color complexity for format selection.
 * 
 * @param image The CGImageRef to analyze
 * @return Estimated number of unique colors (capped at practical limits)
 */
+ (NSUInteger)estimateUniqueColorCountForImage:(CGImageRef)image;

/**
 * Returns the recommended file extension for an image.
 * 
 * @param image The CGImageRef to analyze
 * @param isVectorSource Whether the image originates from a vector source
 * @return "jpg" or "png" based on analysis
 */
+ (NSString *)recommendedExtensionForImage:(CGImageRef)image 
                            isVectorSource:(BOOL)isVectorSource;

@end

NS_ASSUME_NONNULL_END