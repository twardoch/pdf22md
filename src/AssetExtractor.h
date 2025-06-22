#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetExtractor : NSObject

- (nullable instancetype)initWithAssetFolder:(NSString *)folderPath;

- (nullable NSString *)saveImage:(CGImageRef)image
                  isVectorSource:(BOOL)isVector
                      withBaseName:(NSString *)baseName;

@end

NS_ASSUME_NONNULL_END