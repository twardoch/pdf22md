#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PDF22MDContentElement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents an image element extracted from a PDF page.
 * Handles both raster and vector graphics.
 */
@interface PDF22MDImageElement : NSObject <PDF22MDContentElement>

/**
 * The extracted image. Ownership is transferred to this object.
 */
@property (nonatomic, readonly) CGImageRef image;

/**
 * The bounding rectangle of this image in the PDF.
 */
@property (nonatomic, assign, readonly) CGRect bounds;

/**
 * The page index where this image was found.
 */
@property (nonatomic, assign, readonly) NSInteger pageIndex;

/**
 * Indicates whether this image was originally vector graphics.
 */
@property (nonatomic, assign, readonly) BOOL isVectorSource;

/**
 * The relative path to the saved asset file, if any.
 * This is set after the image has been extracted and saved.
 */
@property (nonatomic, copy, nullable) NSString *assetRelativePath;

/**
 * Designated initializer for creating an image element.
 *
 * @param image The CGImage (ownership is transferred)
 * @param bounds The bounding rectangle
 * @param pageIndex The page index
 * @param isVectorSource Whether this was originally vector graphics
 * @return A new image element instance
 */
- (instancetype)initWithImage:(CGImageRef)image
                       bounds:(CGRect)bounds
                    pageIndex:(NSInteger)pageIndex
               isVectorSource:(BOOL)isVectorSource NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Analyzes the image to determine if JPEG compression would be suitable.
 * @return YES if JPEG is recommended, NO for PNG
 */
- (BOOL)shouldUseJPEGCompression;

/**
 * Gets the dimensions of the image.
 * @return The size in pixels
 */
- (CGSize)imageDimensions;

@end

NS_ASSUME_NONNULL_END