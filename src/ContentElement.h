#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ContentElement <NSObject>
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) NSInteger pageIndex;
- (NSString *)markdownRepresentation;
@end

@interface TextElement : NSObject <ContentElement>
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, strong, nullable) NSString *fontName;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) BOOL isBold;
@property (nonatomic, assign) BOOL isItalic;
@property (nonatomic, assign) NSInteger headingLevel;
@end

@interface ImageElement : NSObject <ContentElement>
@property (nonatomic, assign) CGImageRef image;
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) BOOL isVectorSource;
@property (nonatomic, strong, nullable) NSString *assetRelativePath;
@end

NS_ASSUME_NONNULL_END