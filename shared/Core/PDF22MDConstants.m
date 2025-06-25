#import "PDF22MDConstants.h"

#pragma mark - Default Configuration Values

const CGFloat PDF22MD_DEFAULT_DPI = 144.0;
const CGFloat PDF22MD_DEFAULT_FONT_SIZE_THRESHOLD = 2.0;
const NSInteger PDF22MD_MAX_HEADING_LEVEL = 6;
const NSInteger PDF22MD_MIN_HEADING_LEVEL = 1;

const NSInteger PDF22MD_DEFAULT_MAX_CONCURRENT_PAGES = 0; // Will be set to processor count at runtime

#pragma mark - Validation Limits

const NSInteger PDF22MD_MAXIMUM_DPI = 600;
const NSInteger PDF22MD_MINIMUM_DPI = 72;
const NSInteger PDF22MD_MAXIMUM_CONCURRENT_PAGES = 64;
const NSInteger PDF22MD_MINIMUM_CONCURRENT_PAGES = 1;
const CGFloat PDF22MD_MAXIMUM_FONT_SIZE_THRESHOLD = 10.0;
const CGFloat PDF22MD_MINIMUM_FONT_SIZE_THRESHOLD = 0.5;

#pragma mark - File and Asset Configuration

NSString * const PDF22MD_DEFAULT_ASSETS_DIRECTORY = @"assets";

NSString * const PDF22MD_SUPPORTED_IMAGE_FORMATS[] = {
    @"png",
    @"jpg", 
    @"jpeg",
    @"gif",
    @"tiff",
    @"tif",
    @"bmp",
    @"webp"
};

const NSUInteger PDF22MD_SUPPORTED_IMAGE_FORMATS_COUNT = 8;

#pragma mark - Processing Configuration

const NSTimeInterval PDF22MD_DEFAULT_PROCESSING_TIMEOUT = 30.0;
const NSUInteger PDF22MD_COLOR_COMPLEXITY_THRESHOLD = 256;
const NSUInteger PDF22MD_SMALL_IMAGE_THRESHOLD = 32;
const NSUInteger PDF22MD_LARGE_IMAGE_THRESHOLD = 2048;

#pragma mark - Memory and Performance

const NSUInteger PDF22MD_DEFAULT_QUEUE_PRIORITY = DISPATCH_QUEUE_PRIORITY_DEFAULT;
const NSUInteger PDF22MD_MEMORY_WARNING_THRESHOLD_MB = 100;