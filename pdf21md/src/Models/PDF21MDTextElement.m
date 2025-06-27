#import "PDF21MDTextElement.h"

@implementation PDF21MDTextElement

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text
                      bounds:(CGRect)bounds
                   pageIndex:(NSInteger)pageIndex {
    return [self initWithText:text
                       bounds:bounds
                    pageIndex:pageIndex
                     fontName:nil
                     fontSize:12.0
                       isBold:NO
                     isItalic:NO];
}

- (instancetype)initWithText:(NSString *)text
                      bounds:(CGRect)bounds
                   pageIndex:(NSInteger)pageIndex
                    fontName:(nullable NSString *)fontName
                    fontSize:(CGFloat)fontSize
                      isBold:(BOOL)isBold
                    isItalic:(BOOL)isItalic {
    self = [super init];
    if (self) {
        _text = [text copy];
        _bounds = bounds;
        _pageIndex = pageIndex;
        _fontName = [fontName copy];
        _fontSize = fontSize;
        _isBold = isBold;
        _isItalic = isItalic;
        _headingLevel = 0; // Default to body text
    }
    return self;
}

#pragma mark - PDF21MDContentElement Protocol

- (nullable NSString *)markdownRepresentation {
    if (!self.text || self.text.length == 0) {
        return nil;
    }
    
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length == 0) {
        return nil;
    }
    
    // Apply heading formatting
    if (self.headingLevel > 0 && self.headingLevel <= 6) {
        NSMutableString *heading = [NSMutableString string];
        for (NSInteger i = 0; i < self.headingLevel; i++) {
            [heading appendString:@"#"];
        }
        [heading appendString:@" "];
        [heading appendString:trimmedText];
        return heading;
    }
    
    // Apply bold/italic formatting
    NSString *formattedText = trimmedText;
    
    if (self.isBold && self.isItalic) {
        formattedText = [NSString stringWithFormat:@"***%@***", formattedText];
    } else if (self.isBold) {
        formattedText = [NSString stringWithFormat:@"**%@**", formattedText];
    } else if (self.isItalic) {
        formattedText = [NSString stringWithFormat:@"*%@*", formattedText];
    }
    
    return formattedText;
}

- (NSDictionary<NSString *, id> *)metadata {
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    
    if (self.fontName) {
        metadata[@"fontName"] = self.fontName;
    }
    metadata[@"fontSize"] = @(self.fontSize);
    metadata[@"isBold"] = @(self.isBold);
    metadata[@"isItalic"] = @(self.isItalic);
    metadata[@"headingLevel"] = @(self.headingLevel);
    
    return [metadata copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, text='%@', bounds=%@, page=%ld>",
            NSStringFromClass([self class]),
            self,
            [self.text length] > 50 ? [[self.text substringToIndex:50] stringByAppendingString:@"..."] : self.text,
            [NSString stringWithFormat:@"{{%.1f,%.1f},{%.1f,%.1f}}", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height],
            (long)self.pageIndex];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p> {\n  text: '%@'\n  bounds: %@\n  page: %ld\n  font: %@\n  size: %.1f\n  bold: %@\n  italic: %@\n  heading: %ld\n}",
            NSStringFromClass([self class]),
            self,
            self.text,
            [NSString stringWithFormat:@"{{%.1f,%.1f},{%.1f,%.1f}}", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height],
            (long)self.pageIndex,
            self.fontName ?: @"<unknown>",
            self.fontSize,
            self.isBold ? @"YES" : @"NO",
            self.isItalic ? @"YES" : @"NO",
            (long)self.headingLevel];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[PDF21MDTextElement class]]) {
        return NO;
    }
    
    PDF21MDTextElement *other = (PDF21MDTextElement *)object;
    
    return [self.text isEqualToString:other.text] &&
           CGRectEqualToRect(self.bounds, other.bounds) &&
           self.pageIndex == other.pageIndex &&
           (self.fontName == other.fontName || [self.fontName isEqualToString:other.fontName]) &&
           self.fontSize == other.fontSize &&
           self.isBold == other.isBold &&
           self.isItalic == other.isItalic &&
           self.headingLevel == other.headingLevel;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + [self.text hash];
    result = prime * result + (NSUInteger)(self.bounds.origin.x + self.bounds.origin.y + self.bounds.size.width + self.bounds.size.height);
    result = prime * result + self.pageIndex;
    result = prime * result + [self.fontName hash];
    result = prime * result + (NSUInteger)self.fontSize;
    result = prime * result + (self.isBold ? 1 : 0);
    result = prime * result + (self.isItalic ? 1 : 0);
    result = prime * result + self.headingLevel;
    
    return result;
}

@end