#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol defining the interface for all content elements extracted from a PDF.
 * This includes text elements, image elements, and potentially other content types.
 */
@protocol PDF22MDContentElement <NSObject>

@required
/**
 * The bounding rectangle of this element in PDF coordinate space.
 */
@property (nonatomic, readonly) CGRect bounds;

/**
 * The zero-based index of the page this element was extracted from.
 */
@property (nonatomic, readonly) NSInteger pageIndex;

/**
 * Generates the Markdown representation of this element.
 * @return A string containing the Markdown formatted content, or nil if the element has no valid representation.
 */
- (nullable NSString *)markdownRepresentation;

@optional
/**
 * Additional metadata associated with this element.
 * The dictionary keys and values are element-type specific.
 */
- (NSDictionary<NSString *, id> *)metadata;

/**
 * The original extraction context for debugging purposes.
 */
- (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END