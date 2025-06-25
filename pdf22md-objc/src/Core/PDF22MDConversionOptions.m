#import "PDF22MDConversionOptions.h"
#import "PDF22MDError.h"
#import "../../shared/Core/PDF22MDErrorFactory.h"

@implementation PDF22MDConversionOptions

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        // Set default values
        _rasterizationDPI = 144.0;
        _maxConcurrentPages = [[NSProcessInfo processInfo] processorCount];
        _includeMetadata = YES;
        _extractImages = YES;
        _preserveOutline = YES;
        _headingFontSizeThreshold = 2.0;
        _maxHeadingLevel = 6;
    }
    return self;
}

+ (instancetype)defaultOptions {
    return [[self alloc] init];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    PDF22MDConversionOptions *copy = [[PDF22MDConversionOptions allocWithZone:zone] init];
    
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
    if (self.rasterizationDPI <= 0 || self.rasterizationDPI > 600) {
        if (error) {
            *error = [PDF22MDErrorFactory invalidDPIErrorWithValue:self.rasterizationDPI];
        }
        return NO;
    }
    
    // Validate concurrent pages
    if (self.maxConcurrentPages < 1 || self.maxConcurrentPages > 64) {
        if (error) {
            *error = [PDF22MDErrorFactory invalidConcurrentPagesErrorWithValue:self.maxConcurrentPages];
        }
        return NO;
    }
    
    // Validate heading level
    if (self.maxHeadingLevel < 1 || self.maxHeadingLevel > 6) {
        if (error) {
            *error = [PDF22MDErrorFactory invalidHeadingLevelErrorWithValue:self.maxHeadingLevel];
        }
        return NO;
    }
    
    // Validate font size threshold
    if (self.headingFontSizeThreshold < 0.5 || self.headingFontSizeThreshold > 10.0) {
        if (error) {
            *error = [PDF22MDErrorFactory invalidFontSizeThresholdErrorWithValue:self.headingFontSizeThreshold];
        }
        return NO;
    }
    
    // Validate assets path if image extraction is enabled
    if (self.extractImages && self.assetsFolderPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        BOOL exists = [fileManager fileExistsAtPath:self.assetsFolderPath isDirectory:&isDirectory];
        
        if (exists && !isDirectory) {
            if (error) {
                *error = [PDF22MDErrorFactory assetCreationErrorWithPath:self.assetsFolderPath
                                                                   reason:@"Path exists but is not a directory"];
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

@implementation PDF22MDConversionOptionsBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with default values
        PDF22MDConversionOptions *defaults = [PDF22MDConversionOptions defaultOptions];
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

- (PDF22MDConversionOptions *)build {
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    
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