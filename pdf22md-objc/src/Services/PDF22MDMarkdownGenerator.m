#import "PDF22MDMarkdownGenerator.h"
#import "../Core/PDF22MDConversionOptions.h"
#import "../Models/PDF22MDContentElement.h"
#import "../Models/PDF22MDTextElement.h"

// Version string - should match the compiled version
#ifndef PDF22MD_VERSION
#define PDF22MD_VERSION "1.0.0"
#endif

@implementation PDF22MDDocumentMetadata
@end

@implementation PDF22MDMarkdownGenerator

#pragma mark - Initialization

- (instancetype)initWithOptions:(PDF22MDConversionOptions *)options {
    self = [super init];
    if (self) {
        _options = options;
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)generateMarkdownFromElements:(NSArray<id<PDF22MDContentElement>> *)elements
                              withMetadata:(nullable PDF22MDDocumentMetadata *)metadata {
    NSMutableString *markdown = [NSMutableString string];
    
    // Add YAML frontmatter if enabled
    if (self.options.includeMetadata && metadata) {
        NSString *frontmatter = [self generateYAMLFrontmatter:metadata];
        if (frontmatter) {
            [markdown appendString:frontmatter];
            [markdown appendString:@"\n"];
        }
    }
    
    // Generate content
    NSString *content = [self generateMarkdownContent:elements];
    [markdown appendString:content];
    
    // Clean up extra newlines
    NSString *finalMarkdown = [markdown stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return finalMarkdown;
}

- (nullable NSString *)generateYAMLFrontmatter:(PDF22MDDocumentMetadata *)metadata {
    if (!self.options.includeMetadata) {
        return nil;
    }
    
    NSMutableString *yaml = [NSMutableString string];
    [yaml appendString:@"---\n"];
    
    // Basic metadata
    if (metadata.title && metadata.title.length > 0) {
        [yaml appendFormat:@"title: \"%@\"\n", [[self class] escapeYAMLString:metadata.title]];
    }
    
    if (metadata.author && metadata.author.length > 0) {
        [yaml appendFormat:@"author: \"%@\"\n", [[self class] escapeYAMLString:metadata.author]];
    }
    
    if (metadata.subject && metadata.subject.length > 0) {
        [yaml appendFormat:@"subject: \"%@\"\n", [[self class] escapeYAMLString:metadata.subject]];
    }
    
    // Keywords
    if (metadata.keywords && metadata.keywords.count > 0) {
        [yaml appendString:@"keywords:\n"];
        for (NSString *keyword in metadata.keywords) {
            [yaml appendFormat:@"  - \"%@\"\n", [[self class] escapeYAMLString:keyword]];
        }
    }
    
    // Creator and producer
    if (metadata.creator && metadata.creator.length > 0) {
        [yaml appendFormat:@"creator: \"%@\"\n", [[self class] escapeYAMLString:metadata.creator]];
    }
    
    if (metadata.producer && metadata.producer.length > 0) {
        [yaml appendFormat:@"producer: \"%@\"\n", [[self class] escapeYAMLString:metadata.producer]];
    }
    
    // Dates
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    
    if (metadata.creationDate) {
        [yaml appendFormat:@"created: %@\n", [formatter stringFromDate:metadata.creationDate]];
    }
    
    if (metadata.modificationDate) {
        [yaml appendFormat:@"modified: %@\n", [formatter stringFromDate:metadata.modificationDate]];
    }
    
    // PDF specific metadata
    [yaml appendString:@"pdf_metadata:\n"];
    [yaml appendFormat:@"  page_count: %ld\n", (long)metadata.pageCount];
    
    if (metadata.pdfVersion && metadata.pdfVersion.length > 0) {
        [yaml appendFormat:@"  version: \"%@\"\n", metadata.pdfVersion];
    }
    
    // Outline/bookmarks
    if (self.options.preserveOutline && metadata.outline && [metadata.outline numberOfChildren] > 0) {
        [yaml appendString:@"  outline:\n"];
        [self appendOutlineToYAML:yaml outline:metadata.outline indent:@"    "];
    }
    
    // Conversion metadata
    [yaml appendString:@"conversion:\n"];
    [yaml appendString:@"  tool: \"pdf22md\"\n"];
    [yaml appendFormat:@"  version: \"%s\"\n", PDF22MD_VERSION];
    [yaml appendFormat:@"  date: %@\n", [formatter stringFromDate:[NSDate date]]];
    
    [yaml appendString:@"---\n"];
    
    return yaml;
}

- (NSString *)generateMarkdownContent:(NSArray<id<PDF22MDContentElement>> *)elements {
    NSMutableString *content = [NSMutableString string];
    
    id<PDF22MDContentElement> previousElement = nil;
    
    for (id<PDF22MDContentElement> element in elements) {
        NSString *elementMarkdown = [element markdownRepresentation];
        
        if (elementMarkdown && elementMarkdown.length > 0) {
            // Add appropriate spacing between elements
            if (previousElement) {
                // Check if we need extra spacing (e.g., between paragraphs)
                if ([self shouldAddExtraSpacingBetween:previousElement and:element]) {
                    [content appendString:@"\n\n"];
                } else {
                    [content appendString:@"\n"];
                }
            }
            
            [content appendString:elementMarkdown];
            previousElement = element;
        }
    }
    
    return content;
}

+ (PDF22MDDocumentMetadata *)extractMetadataFromDocument:(PDFDocument *)document {
    PDF22MDDocumentMetadata *metadata = [[PDF22MDDocumentMetadata alloc] init];
    
    // Get document attributes
    NSDictionary *attributes = [document documentAttributes];
    
    metadata.title = attributes[PDFDocumentTitleAttribute];
    metadata.author = attributes[PDFDocumentAuthorAttribute];
    metadata.subject = attributes[PDFDocumentSubjectAttribute];
    metadata.keywords = attributes[PDFDocumentKeywordsAttribute];
    metadata.creator = attributes[PDFDocumentCreatorAttribute];
    metadata.producer = attributes[PDFDocumentProducerAttribute];
    metadata.creationDate = attributes[PDFDocumentCreationDateAttribute];
    metadata.modificationDate = attributes[PDFDocumentModificationDateAttribute];
    
    metadata.pageCount = [document pageCount];
    metadata.outline = [document outlineRoot];
    
    // Try to extract PDF version
    metadata.pdfVersion = [self extractPDFVersionFromAttributes:attributes];
    
    return metadata;
}

+ (NSString *)escapeYAMLString:(NSString *)string {
    // Escape quotes and backslashes for YAML
    NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
    return escaped;
}

#pragma mark - Private Methods

- (void)appendOutlineToYAML:(NSMutableString *)yaml outline:(PDFOutline *)outline indent:(NSString *)indent {
    for (NSUInteger i = 0; i < [outline numberOfChildren]; i++) {
        PDFOutline *child = [outline childAtIndex:i];
        NSString *label = [child label];
        
        if (label && label.length > 0) {
            [yaml appendFormat:@"%@- title: \"%@\"\n", indent, [[self class] escapeYAMLString:label]];
            
            PDFDestination *destination = [child destination];
            if (destination) {
                PDFPage *page = [destination page];
                if (page) {
                    // Note: We need the document to get page index, so this is an approximation
                    [yaml appendFormat:@"%@  page: %ld\n", indent, (long)1];
                }
            }
            
            if ([child numberOfChildren] > 0) {
                [yaml appendFormat:@"%@  children:\n", indent];
                NSString *newIndent = [indent stringByAppendingString:@"    "];
                [self appendOutlineToYAML:yaml outline:child indent:newIndent];
            }
        }
    }
}

+ (NSString *)extractPDFVersionFromAttributes:(NSDictionary *)attributes {
    // Look for PDF version in various attribute keys
    for (NSString *key in attributes) {
        id value = attributes[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)value;
            
            // Look for PDF version patterns
            NSRange pdfRange = [stringValue rangeOfString:@"PDF-" options:NSCaseInsensitiveSearch];
            if (pdfRange.location != NSNotFound) {
                // Extract version number after "PDF-"
                NSString *versionPart = [stringValue substringFromIndex:pdfRange.location];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"PDF-?(\\d+\\.\\d+)"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
                NSTextCheckingResult *match = [regex firstMatchInString:versionPart
                                                               options:0
                                                                 range:NSMakeRange(0, versionPart.length)];
                if (match && match.numberOfRanges > 1) {
                    return [versionPart substringWithRange:[match rangeAtIndex:1]];
                }
            }
        }
    }
    
    return nil;
}

- (BOOL)shouldAddExtraSpacingBetween:(id<PDF22MDContentElement>)element1 
                                 and:(id<PDF22MDContentElement>)element2 {
    // Add extra spacing between different element types
    if ([element1 class] != [element2 class]) {
        return YES;
    }
    
    // Add extra spacing after headings
    if ([element1 isKindOfClass:[PDF22MDTextElement class]]) {
        PDF22MDTextElement *textElement = (PDF22MDTextElement *)element1;
        if (textElement.headingLevel > 0) {
            return YES;
        }
    }
    
    // Add extra spacing between elements on different pages
    if (element1.pageIndex != element2.pageIndex) {
        return YES;
    }
    
    // Check vertical distance between elements
    CGFloat verticalDistance = fabs(CGRectGetMinY(element1.bounds) - CGRectGetMaxY(element2.bounds));
    if (verticalDistance > 20.0) { // Significant gap
        return YES;
    }
    
    return NO;
}

@end