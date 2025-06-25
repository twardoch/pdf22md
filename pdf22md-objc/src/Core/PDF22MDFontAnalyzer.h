#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDF22MDContentElement;
@class PDF22MDTextElement;

/**
 * Font statistics for a particular font and size combination.
 */
@interface PDF22MDFontStatistics : NSObject
@property (nonatomic, copy, readonly) NSString *fontKey;
@property (nonatomic, copy, readonly) NSString *fontName;
@property (nonatomic, assign, readonly) CGFloat fontSize;
@property (nonatomic, assign, readonly) NSUInteger occurrenceCount;
@property (nonatomic, assign) NSInteger assignedHeadingLevel; // 0 for body text, 1-6 for headings

- (instancetype)initWithFontKey:(NSString *)fontKey
                       fontName:(NSString *)fontName
                       fontSize:(CGFloat)fontSize;

- (void)incrementOccurrenceCount;
- (void)addOccurrenceCount:(NSUInteger)count;

@end

/**
 * Analyzes font usage in PDF documents to detect heading hierarchy.
 */
@interface PDF22MDFontAnalyzer : NSObject

/**
 * The font size threshold for detecting headings.
 * Text with font size differences greater than this value may be considered headings.
 */
@property (nonatomic, assign) CGFloat fontSizeThreshold;

/**
 * Maximum heading level to assign (1-6).
 */
@property (nonatomic, assign) NSInteger maxHeadingLevel;

/**
 * Dictionary of font statistics keyed by font identifier.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, PDF22MDFontStatistics *> *fontStatistics;

/**
 * Initializes the analyzer with default settings.
 */
- (instancetype)init;

/**
 * Analyzes an array of content elements to build font statistics.
 * This should be called before assignHeadingLevels.
 *
 * @param elements Array of content elements to analyze
 */
- (void)analyzeElements:(NSArray<id<PDF22MDContentElement>> *)elements;

/**
 * Assigns heading levels to text elements based on font analysis.
 * Call this after analyzeElements.
 *
 * @param elements Array of content elements to process
 */
- (void)assignHeadingLevels:(NSArray<id<PDF22MDContentElement>> *)elements;

/**
 * Merges font statistics from another analyzer.
 * Useful for combining statistics from multiple pages.
 *
 * @param otherAnalyzer The analyzer to merge from
 */
- (void)mergeFontStatisticsFromAnalyzer:(PDF22MDFontAnalyzer *)otherAnalyzer;

/**
 * Resets all collected statistics.
 */
- (void)reset;

/**
 * Gets a sorted array of font statistics by size (largest first).
 */
- (NSArray<PDF22MDFontStatistics *> *)sortedFontStatistics;

/**
 * Creates a font key identifier from font properties.
 */
+ (NSString *)fontKeyForFontName:(nullable NSString *)fontName fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END