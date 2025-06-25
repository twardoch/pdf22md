#import <Foundation/Foundation.h>
#import "PDF22MDContentElement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a text element extracted from a PDF page.
 * Includes text content and associated styling information.
 */
@interface PDF22MDTextElement : NSObject <PDF22MDContentElement>

/**
 * The extracted text content. Never nil, but may be empty.
 */
@property (nonatomic, copy, readonly) NSString *text;

/**
 * The bounding rectangle of this text element.
 */
@property (nonatomic, assign, readonly) CGRect bounds;

/**
 * The page index where this text was found.
 */
@property (nonatomic, assign, readonly) NSInteger pageIndex;

/**
 * The font name used for this text, if available.
 */
@property (nonatomic, copy, nullable, readonly) NSString *fontName;

/**
 * The font size in points.
 */
@property (nonatomic, assign, readonly) CGFloat fontSize;

/**
 * Indicates if the text appears to be bold.
 */
@property (nonatomic, assign, readonly) BOOL isBold;

/**
 * Indicates if the text appears to be italic.
 */
@property (nonatomic, assign, readonly) BOOL isItalic;

/**
 * The detected heading level (0 for body text, 1-6 for headings).
 */
@property (nonatomic, assign) NSInteger headingLevel;

/**
 * Designated initializer for creating a text element.
 *
 * @param text The text content (required)
 * @param bounds The bounding rectangle
 * @param pageIndex The page index
 * @return A new text element instance
 */
- (instancetype)initWithText:(NSString *)text
                      bounds:(CGRect)bounds
                   pageIndex:(NSInteger)pageIndex;

/**
 * Convenience initializer with full styling information.
 *
 * @param text The text content
 * @param bounds The bounding rectangle
 * @param pageIndex The page index
 * @param fontName The font name (optional)
 * @param fontSize The font size
 * @param isBold Bold style flag
 * @param isItalic Italic style flag
 * @return A new text element instance
 */
- (instancetype)initWithText:(NSString *)text
                      bounds:(CGRect)bounds
                   pageIndex:(NSInteger)pageIndex
                    fontName:(nullable NSString *)fontName
                    fontSize:(CGFloat)fontSize
                      isBold:(BOOL)isBold
                    isItalic:(BOOL)isItalic NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END