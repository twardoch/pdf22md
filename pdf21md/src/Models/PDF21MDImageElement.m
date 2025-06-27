#import "PDF21MDImageElement.h"

@implementation PDF21MDImageElement

#pragma mark - Initialization

- (instancetype)initWithImage:(CGImageRef)image
                       bounds:(CGRect)bounds
                    pageIndex:(NSInteger)pageIndex
               isVectorSource:(BOOL)isVectorSource {
    self = [super init];
    if (self) {
        _image = CGImageRetain(image);
        _bounds = bounds;
        _pageIndex = pageIndex;
        _isVectorSource = isVectorSource;
    }
    return self;
}

- (void)dealloc {
    if (_image) {
        CGImageRelease(_image);
    }
}

#pragma mark - PDF21MDContentElement Protocol

- (nullable NSString *)markdownRepresentation {
    if (!self.assetRelativePath) {
        return @"![Image](image-not-saved)";
    }
    
    return [NSString stringWithFormat:@"![Image](%@)", self.assetRelativePath];
}

- (NSDictionary<NSString *, id> *)metadata {
    CGSize dimensions = [self imageDimensions];
    
    return @{
        @"width": @(dimensions.width),
        @"height": @(dimensions.height),
        @"isVectorSource": @(self.isVectorSource),
        @"hasAlpha": @([self imageHasAlpha]),
        @"shouldUseJPEG": @([self shouldUseJPEGCompression])
    };
}

#pragma mark - Public Methods

- (CGSize)imageDimensions {
    if (!self.image) {
        return CGSizeZero;
    }
    
    return CGSizeMake(CGImageGetWidth(self.image), CGImageGetHeight(self.image));
}

- (BOOL)shouldUseJPEGCompression {
    if (!self.image) {
        return NO;
    }
    
    // If image has alpha channel, use PNG
    if ([self imageHasAlpha]) {
        return NO;
    }
    
    // For small images, use PNG
    CGSize dimensions = [self imageDimensions];
    if (dimensions.width * dimensions.height < 10000) { // Less than 100x100
        return NO;
    }
    
    // For vector sources, prefer PNG to maintain quality
    if (self.isVectorSource) {
        return NO;
    }
    
    // Analyze color complexity
    NSUInteger uniqueColors = [self estimateUniqueColorCount];
    
    // If we have many unique colors, it's likely a photograph - use JPEG
    return uniqueColors > 256;
}

#pragma mark - Private Methods

- (BOOL)imageHasAlpha {
    if (!self.image) {
        return NO;
    }
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.image);
    
    return alphaInfo != kCGImageAlphaNone &&
           alphaInfo != kCGImageAlphaNoneSkipFirst &&
           alphaInfo != kCGImageAlphaNoneSkipLast;
}

- (NSUInteger)estimateUniqueColorCount {
    if (!self.image) {
        return 0;
    }
    
    size_t width = CGImageGetWidth(self.image);
    size_t height = CGImageGetHeight(self.image);
    
    // Sample a subset of pixels for performance
    size_t sampleWidth = MIN(width, 100);
    size_t sampleHeight = MIN(height, 100);
    size_t __unused stepX = MAX(1, width / sampleWidth);
    size_t __unused stepY = MAX(1, height / sampleHeight);
    
    // Create a small bitmap context for sampling
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bytesPerRow = sampleWidth * 4;
    unsigned char *pixelData = calloc(sampleHeight * bytesPerRow, sizeof(unsigned char));
    
    if (!pixelData) {
        CGColorSpaceRelease(colorSpace);
        return 256; // Default to medium complexity
    }
    
    CGContextRef context = CGBitmapContextCreate(pixelData, sampleWidth, sampleHeight, 8, bytesPerRow, colorSpace,
                                                kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        free(pixelData);
        return 256;
    }
    
    // Draw scaled image
    CGContextDrawImage(context, CGRectMake(0, 0, sampleWidth, sampleHeight), self.image);
    CGContextRelease(context);
    
    // Count unique colors
    NSMutableSet *uniqueColors = [NSMutableSet set];
    
    for (size_t y = 0; y < sampleHeight; y++) {
        for (size_t x = 0; x < sampleWidth; x++) {
            size_t offset = (y * bytesPerRow) + (x * 4);
            uint32_t color = (pixelData[offset] << 24) | 
                           (pixelData[offset + 1] << 16) | 
                           (pixelData[offset + 2] << 8) | 
                           pixelData[offset + 3];
            [uniqueColors addObject:@(color)];
            
            // Early exit if we already have many colors
            if (uniqueColors.count > 1000) {
                free(pixelData);
                return uniqueColors.count;
            }
        }
    }
    
    free(pixelData);
    return uniqueColors.count;
}

#pragma mark - NSObject

- (NSString *)description {
    CGSize dimensions = [self imageDimensions];
    return [NSString stringWithFormat:@"<%@: %p, size=%.0fx%.0f, bounds=%@, page=%ld>",
            NSStringFromClass([self class]),
            self,
            dimensions.width,
            dimensions.height,
            [NSString stringWithFormat:@"{{%.1f,%.1f},{%.1f,%.1f}}", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height],
            (long)self.pageIndex];
}

- (NSString *)debugDescription {
    CGSize dimensions = [self imageDimensions];
    return [NSString stringWithFormat:@"<%@: %p> {\n  dimensions: %.0fx%.0f\n  bounds: %@\n  page: %ld\n  vector: %@\n  alpha: %@\n  path: %@\n}",
            NSStringFromClass([self class]),
            self,
            dimensions.width,
            dimensions.height,
            [NSString stringWithFormat:@"{{%.1f,%.1f},{%.1f,%.1f}}", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height],
            (long)self.pageIndex,
            self.isVectorSource ? @"YES" : @"NO",
            [self imageHasAlpha] ? @"YES" : @"NO",
            self.assetRelativePath ?: @"<not saved>"];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[PDF21MDImageElement class]]) {
        return NO;
    }
    
    PDF21MDImageElement *other = (PDF21MDImageElement *)object;
    
    return CGRectEqualToRect(self.bounds, other.bounds) &&
           self.pageIndex == other.pageIndex &&
           self.isVectorSource == other.isVectorSource &&
           (self.assetRelativePath == other.assetRelativePath || 
            [self.assetRelativePath isEqualToString:other.assetRelativePath]);
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + (NSUInteger)(self.bounds.origin.x + self.bounds.origin.y + self.bounds.size.width + self.bounds.size.height);
    result = prime * result + self.pageIndex;
    result = prime * result + (self.isVectorSource ? 1 : 0);
    result = prime * result + [self.assetRelativePath hash];
    
    return result;
}

@end