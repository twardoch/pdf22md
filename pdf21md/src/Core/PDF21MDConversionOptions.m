#import "PDF21MDConversionOptions.h"
#import "PDF21MDError.h"
#import "../../shared-core/PDF21MDErrorFactory.h"
#import "../../shared-core/PDF21MDConstants.h"
#import "../../shared-core/PDF21MDFileSystemUtils.h"

@implementation PDF21MDConversionOptions

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        // Set default values
        _rasterizationDPI = PDF21MD_DEFAULT_DPI;
        _maxConcurrentPages = PDF21MD_DEFAULT_MAX_CONCURRENT_PAGES ?: [[NSProcessInfo processInfo] processorCount];
        _includeMetadata = YES;
        _extractImages = YES;
        _preserveOutline = YES;
        _headingFontSizeThreshold = PDF21MD_DEFAULT_FONT_SIZE_THRESHOLD;
        _maxHeadingLevel = PDF21MD_MAX_HEADING_LEVEL;
    }
    return self;
}

+ (instancetype)defaultOptions {
    return [[self alloc] init];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    PDF21MDConversionOptions *copy = [[PDF21MDConversionOptions allocWithZone:zone] init];
    
    copy.assetsFolderPath = self.assetsFolderPath;
    copy.rasterizationDPI = self.rasterizationDPI;
    copy.maxConcurrentPages = self.maxConcurrentPages;
    copy.includeMetadata = self.includeMetadata;
    copy.extractImages = self.extractImages;
    copy.preserveOutline = self.preserveOutline;
    copy.headingFontSizeThreshold = self.headingFontSizeThreshold;
    copy.maxHeadingLevel = self.maxHeadingLevel;
    copy.progressHandler = self.progressHandler;
    
    return copy;
}

#pragma mark - Validation

- (BOOL)validateWithError:(NSError * _Nullable * _Nullable)error {
    // Validate DPI
    if (self.rasterizationDPI < PDF21MD_MINIMUM_DPI || self.rasterizationDPI > PDF21MD_MAXIMUM_DPI) {
        if (error) {
            *error = [PDF21MDErrorFactory invalidDPIErrorWithValue:self.rasterizationDPI];
        }
        return NO;
    }
    
    // Validate concurrent pages
    if (self.maxConcurrentPages < PDF21MD_MINIMUM_CONCURRENT_PAGES || self.maxConcurrentPages > PDF21MD_MAXIMUM_CONCURRENT_PAGES) {
        if (error) {
            *error = [PDF21MDErrorFactory invalidConcurrentPagesErrorWithValue:self.maxConcurrentPages];
        }
        return NO;
    }
    
    // Validate heading level
    if (self.maxHeadingLevel < PDF21MD_MIN_HEADING_LEVEL || self.maxHeadingLevel > PDF21MD_MAX_HEADING_LEVEL) {
        if (error) {
            *error = [PDF21MDErrorFactory invalidHeadingLevelErrorWithValue:self.maxHeadingLevel];
        }
        return NO;
    }
    
    // Validate font size threshold
    if (self.headingFontSizeThreshold < PDF21MD_MINIMUM_FONT_SIZE_THRESHOLD || self.headingFontSizeThreshold > PDF21MD_MAXIMUM_FONT_SIZE_THRESHOLD) {
        if (error) {
            *error = [PDF21MDErrorFactory invalidFontSizeThresholdErrorWithValue:self.headingFontSizeThreshold];
        }
        return NO;
    }
    
    // Validate assets path if image extraction is enabled
    if (self.extractImages && self.assetsFolderPath) {
        NSError *validationError = nil;
        if (![PDF21MDFileSystemUtils isValidFilePath:self.assetsFolderPath error:&validationError]) {
            if (error) {
                *error = validationError;
            }
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, assets=%@, dpi=%.0f, concurrent=%ld>",
            NSStringFromClass([self class]),
            self,
            self.assetsFolderPath ?: @"<none>",
            self.rasterizationDPI,
            (long)self.maxConcurrentPages];
}

@end

#pragma mark - Builder Implementation

@implementation PDF21MDConversionOptionsBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with default values
        PDF21MDConversionOptions *defaults = [PDF21MDConversionOptions defaultOptions];
        _rasterizationDPI = defaults.rasterizationDPI;
        _maxConcurrentPages = defaults.maxConcurrentPages;
        _includeMetadata = defaults.includeMetadata;
        _extractImages = defaults.extractImages;
        _preserveOutline = defaults.preserveOutline;
        _headingFontSizeThreshold = defaults.headingFontSizeThreshold;
        _maxHeadingLevel = defaults.maxHeadingLevel;
    }
    return self;
}

- (PDF21MDConversionOptions *)build {
    PDF21MDConversionOptions *options = [[PDF21MDConversionOptions alloc] init];
    
    options.assetsFolderPath = self.assetsFolderPath;
    options.rasterizationDPI = self.rasterizationDPI;
    options.maxConcurrentPages = self.maxConcurrentPages;
    options.includeMetadata = self.includeMetadata;
    options.extractImages = self.extractImages;
    options.preserveOutline = self.preserveOutline;
    options.headingFontSizeThreshold = self.headingFontSizeThreshold;
    options.maxHeadingLevel = self.maxHeadingLevel;
    options.progressHandler = self.progressHandler;
    
    return options;
}

@end