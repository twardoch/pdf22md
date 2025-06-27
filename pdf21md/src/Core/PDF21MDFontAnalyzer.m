#import "PDF21MDFontAnalyzer.h"
#import "../Models/PDF21MDContentElement.h"
#import "../Models/PDF21MDTextElement.h"

@implementation PDF21MDFontStatistics

- (instancetype)initWithFontKey:(NSString *)fontKey
                       fontName:(NSString *)fontName
                       fontSize:(CGFloat)fontSize {
    self = [super init];
    if (self) {
        _fontKey = [fontKey copy];
        _fontName = [fontName copy];
        _fontSize = fontSize;
        _occurrenceCount = 0;
        _assignedHeadingLevel = 0;
    }
    return self;
}

- (void)incrementOccurrenceCount {
    _occurrenceCount++;
}

- (void)addOccurrenceCount:(NSUInteger)count {
    _occurrenceCount += count;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<FontStats: %@ size=%.1f count=%lu level=%ld>",
            self.fontName, self.fontSize, (unsigned long)self.occurrenceCount, (long)self.assignedHeadingLevel];
}

@end

@interface PDF21MDFontAnalyzer ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, PDF21MDFontStatistics *> *mutableFontStatistics;
@end

@implementation PDF21MDFontAnalyzer

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _fontSizeThreshold = 2.0;
        _maxHeadingLevel = 6;
        _mutableFontStatistics = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public Methods

- (void)analyzeElements:(NSArray<id<PDF21MDContentElement>> *)elements {
    for (id<PDF21MDContentElement> element in elements) {
        if ([element isKindOfClass:[PDF21MDTextElement class]]) {
            PDF21MDTextElement *textElement = (PDF21MDTextElement *)element;
            [self addTextElementToStatistics:textElement];
        }
    }
}

- (void)assignHeadingLevels:(NSArray<id<PDF21MDContentElement>> *)elements {
    // Get sorted font statistics
    NSArray<PDF21MDFontStatistics *> *sortedStats = [self sortedFontStatistics];
    
    if (sortedStats.count == 0) {
        return;
    }
    
    // Find the most common font size (likely body text)
    PDF21MDFontStatistics *mostCommonFont = nil;
    NSUInteger highestCount = 0;
    
    for (PDF21MDFontStatistics *stats in sortedStats) {
        if (stats.occurrenceCount > highestCount) {
            highestCount = stats.occurrenceCount;
            mostCommonFont = stats;
        }
    }
    
    CGFloat bodyFontSize = mostCommonFont ? mostCommonFont.fontSize : 12.0;
    
    // Assign heading levels based on size hierarchy
    NSInteger currentHeadingLevel = 1;
    CGFloat lastHeadingSize = CGFLOAT_MAX;
    
    for (PDF21MDFontStatistics *stats in sortedStats) {
        // Skip if this is likely body text
        if (stats == mostCommonFont) {
            stats.assignedHeadingLevel = 0;
            continue;
        }
        
        // Check if this font is significantly larger than body text
        CGFloat sizeDifference = stats.fontSize - bodyFontSize;
        
        if (sizeDifference >= self.fontSizeThreshold) {
            // This is a potential heading
            // Check if it's significantly different from the last heading size
            if (lastHeadingSize - stats.fontSize >= self.fontSizeThreshold) {
                currentHeadingLevel++;
            }
            
            if (currentHeadingLevel <= self.maxHeadingLevel) {
                stats.assignedHeadingLevel = currentHeadingLevel;
                lastHeadingSize = stats.fontSize;
            } else {
                // Too many heading levels, treat as body text
                stats.assignedHeadingLevel = 0;
            }
        } else {
            // Not large enough to be a heading
            stats.assignedHeadingLevel = 0;
        }
        
        // Additional heuristic: if occurrence count is very high, it's probably not a heading
        if (stats.occurrenceCount > highestCount * 0.5) {
            stats.assignedHeadingLevel = 0;
        }
    }
    
    // Apply heading levels to text elements
    for (id<PDF21MDContentElement> element in elements) {
        if ([element isKindOfClass:[PDF21MDTextElement class]]) {
            PDF21MDTextElement *textElement = (PDF21MDTextElement *)element;
            NSString *fontKey = [[self class] fontKeyForFontName:textElement.fontName 
                                                        fontSize:textElement.fontSize];
            PDF21MDFontStatistics *stats = self.mutableFontStatistics[fontKey];
            if (stats) {
                textElement.headingLevel = stats.assignedHeadingLevel;
            }
        }
    }
}

- (void)mergeFontStatisticsFromAnalyzer:(PDF21MDFontAnalyzer *)otherAnalyzer {
    [otherAnalyzer.fontStatistics enumerateKeysAndObjectsUsingBlock:^(NSString *key, PDF21MDFontStatistics *otherStats, BOOL * __unused stop) {
        PDF21MDFontStatistics *existingStats = self.mutableFontStatistics[key];
        
        if (existingStats) {
            // Merge occurrence counts
            [existingStats addOccurrenceCount:otherStats.occurrenceCount];
        } else {
            // Add new statistics
            PDF21MDFontStatistics *newStats = [[PDF21MDFontStatistics alloc] initWithFontKey:otherStats.fontKey
                                                                                    fontName:otherStats.fontName
                                                                                    fontSize:otherStats.fontSize];
            [newStats addOccurrenceCount:otherStats.occurrenceCount];
            self.mutableFontStatistics[key] = newStats;
        }
    }];
}

- (void)reset {
    [self.mutableFontStatistics removeAllObjects];
}

- (NSArray<PDF21MDFontStatistics *> *)sortedFontStatistics {
    NSArray<PDF21MDFontStatistics *> *allStats = [self.mutableFontStatistics allValues];
    
    // Sort by font size in descending order
    return [allStats sortedArrayUsingComparator:^NSComparisonResult(PDF21MDFontStatistics *obj1, PDF21MDFontStatistics *obj2) {
        if (obj1.fontSize > obj2.fontSize) {
            return NSOrderedAscending;
        } else if (obj1.fontSize < obj2.fontSize) {
            return NSOrderedDescending;
        } else {
            // Same size, sort by occurrence count
            if (obj1.occurrenceCount > obj2.occurrenceCount) {
                return NSOrderedAscending;
            } else if (obj1.occurrenceCount < obj2.occurrenceCount) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }
    }];
}

+ (NSString *)fontKeyForFontName:(nullable NSString *)fontName fontSize:(CGFloat)fontSize {
    NSString *name = fontName ?: @"Unknown";
    return [NSString stringWithFormat:@"%.1f-%@", fontSize, name];
}

#pragma mark - Properties

- (NSDictionary<NSString *, PDF21MDFontStatistics *> *)fontStatistics {
    return [self.mutableFontStatistics copy];
}

#pragma mark - Private Methods

- (void)addTextElementToStatistics:(PDF21MDTextElement *)textElement {
    // Skip empty text
    NSString *trimmedText = [textElement.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length == 0) {
        return;
    }
    
    NSString *fontKey = [[self class] fontKeyForFontName:textElement.fontName fontSize:textElement.fontSize];
    
    PDF21MDFontStatistics *stats = self.mutableFontStatistics[fontKey];
    if (!stats) {
        stats = [[PDF21MDFontStatistics alloc] initWithFontKey:fontKey
                                                      fontName:textElement.fontName ?: @"Unknown"
                                                      fontSize:textElement.fontSize];
        self.mutableFontStatistics[fontKey] = stats;
    }
    
    [stats incrementOccurrenceCount];
}

@end