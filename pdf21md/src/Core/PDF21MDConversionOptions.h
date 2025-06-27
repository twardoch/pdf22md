#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Configuration options for PDF to Markdown conversion.
 * This class uses the builder pattern for convenient configuration.
 */
@interface PDF21MDConversionOptions : NSObject <NSCopying>

/**
 * Path to the folder where extracted assets (images) should be saved.
 * If nil, images will not be extracted.
 */
@property (nonatomic, copy, nullable) NSString *assetsFolderPath;

/**
 * DPI for rasterizing vector graphics.
 * Default is 144.0
 */
@property (nonatomic, assign) CGFloat rasterizationDPI;

/**
 * Maximum number of concurrent page processing operations.
 * Default is NSProcessInfo.processInfo.processorCount
 */
@property (nonatomic, assign) NSInteger maxConcurrentPages;

/**
 * Whether to include YAML frontmatter with metadata.
 * Default is YES
 */
@property (nonatomic, assign) BOOL includeMetadata;

/**
 * Whether to extract images from the PDF.
 * Default is YES (if assetsFolderPath is set)
 */
@property (nonatomic, assign) BOOL extractImages;

/**
 * Whether to preserve the PDF outline/bookmarks structure.
 * Default is YES
 */
@property (nonatomic, assign) BOOL preserveOutline;

/**
 * Minimum font size difference to consider for heading detection.
 * Default is 2.0 points
 */
@property (nonatomic, assign) CGFloat headingFontSizeThreshold;

/**
 * Maximum heading level to detect (1-6).
 * Default is 6
 */
@property (nonatomic, assign) NSInteger maxHeadingLevel;

/**
 * Progress handler called during conversion.
 * The handler receives the current page index and total page count.
 */
@property (nonatomic, copy, nullable) void (^progressHandler)(NSInteger currentPage, NSInteger totalPages);

/**
 * Creates default conversion options.
 */
+ (instancetype)defaultOptions;

/**
 * Validates the current options configuration.
 * @param error Set if validation fails
 * @return YES if valid, NO otherwise
 */
- (BOOL)validateWithError:(NSError * _Nullable * _Nullable)error;

@end

/**
 * Builder class for creating PDF21MDConversionOptions instances.
 */
@interface PDF21MDConversionOptionsBuilder : NSObject

@property (nonatomic, copy, nullable) NSString *assetsFolderPath;
@property (nonatomic, assign) CGFloat rasterizationDPI;
@property (nonatomic, assign) NSInteger maxConcurrentPages;
@property (nonatomic, assign) BOOL includeMetadata;
@property (nonatomic, assign) BOOL extractImages;
@property (nonatomic, assign) BOOL preserveOutline;
@property (nonatomic, assign) CGFloat headingFontSizeThreshold;
@property (nonatomic, assign) NSInteger maxHeadingLevel;
@property (nonatomic, copy, nullable) void (^progressHandler)(NSInteger currentPage, NSInteger totalPages);

- (PDF21MDConversionOptions *)build;

@end

NS_ASSUME_NONNULL_END