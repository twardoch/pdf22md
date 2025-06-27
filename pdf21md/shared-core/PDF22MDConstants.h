#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Default Configuration Values

extern const CGFloat PDF22MD_DEFAULT_DPI;
extern const CGFloat PDF22MD_DEFAULT_FONT_SIZE_THRESHOLD;
extern const NSInteger PDF22MD_MAX_HEADING_LEVEL;
extern const NSInteger PDF22MD_MIN_HEADING_LEVEL;
extern const NSInteger PDF22MD_DEFAULT_MAX_CONCURRENT_PAGES;

#pragma mark - Validation Limits

extern const NSInteger PDF22MD_MAXIMUM_DPI;
extern const NSInteger PDF22MD_MINIMUM_DPI;
extern const NSInteger PDF22MD_MAXIMUM_CONCURRENT_PAGES;
extern const NSInteger PDF22MD_MINIMUM_CONCURRENT_PAGES;
extern const CGFloat PDF22MD_MAXIMUM_FONT_SIZE_THRESHOLD;
extern const CGFloat PDF22MD_MINIMUM_FONT_SIZE_THRESHOLD;

#pragma mark - File and Asset Configuration

extern NSString * const PDF22MD_DEFAULT_ASSETS_DIRECTORY;
extern NSString * const _Nonnull PDF22MD_SUPPORTED_IMAGE_FORMATS[];
extern const NSUInteger PDF22MD_SUPPORTED_IMAGE_FORMATS_COUNT;

#pragma mark - Processing Configuration

extern const NSTimeInterval PDF22MD_DEFAULT_PROCESSING_TIMEOUT;
extern const NSUInteger PDF22MD_COLOR_COMPLEXITY_THRESHOLD;
extern const NSUInteger PDF22MD_SMALL_IMAGE_THRESHOLD;
extern const NSUInteger PDF22MD_LARGE_IMAGE_THRESHOLD;

#pragma mark - Memory and Performance

extern const NSUInteger PDF22MD_DEFAULT_QUEUE_PRIORITY;
extern const NSUInteger PDF22MD_MEMORY_WARNING_THRESHOLD_MB;

NS_ASSUME_NONNULL_END