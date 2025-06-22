#import "ContentElement.h"

@implementation TextElement

- (NSString *)markdownRepresentation {
    if (!self.text || [self.text length] == 0) {
        return nil;
    }
    
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedText length] == 0) {
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

- (void)dealloc {
    // No need to release CGImageRef here as ARC doesn't manage it
}

@end

@implementation ImageElement

- (NSString *)markdownRepresentation {
    if (!self.assetRelativePath) {
        return @"![Image](image-not-saved)";
    }
    
    return [NSString stringWithFormat:@"![Image](%@)", self.assetRelativePath];
}

- (void)dealloc {
    if (self.image) {
        CGImageRelease(self.image);
    }
}

@end