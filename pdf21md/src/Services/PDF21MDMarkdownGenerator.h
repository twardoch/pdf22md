#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDF21MDContentElement;
@class PDF21MDConversionOptions;

/**
 * Metadata structure for YAML frontmatter generation.
 */
@interface PDF21MDDocumentMetadata : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *author;
@property (nonatomic, copy, nullable) NSString *subject;
@property (nonatomic, copy, nullable) NSArray<NSString *> *keywords;
@property (nonatomic, copy, nullable) NSString *creator;
@property (nonatomic, copy, nullable) NSString *producer;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSDate *modificationDate;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, copy, nullable) NSString *pdfVersion;
@property (nonatomic, strong, nullable) PDFOutline *outline;
@end

/**
 * Generates Markdown output from PDF content elements.
 */
@interface PDF21MDMarkdownGenerator : NSObject

/**
 * Conversion options affecting markdown generation.
 */
@property (nonatomic, strong, readonly) PDF21MDConversionOptions *options;

/**
 * Initializes the generator with conversion options.
 *
 * @param options The conversion options to use
 * @return A new generator instance
 */
- (instancetype)initWithOptions:(PDF21MDConversionOptions *)options NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Generates a complete markdown document from content elements.
 *
 * @param elements Array of content elements in reading order
 * @param metadata Document metadata for frontmatter
 * @return The generated markdown string
 */
- (NSString *)generateMarkdownFromElements:(NSArray<id<PDF21MDContentElement>> *)elements
                              withMetadata:(nullable PDF21MDDocumentMetadata *)metadata;

/**
 * Generates YAML frontmatter from document metadata.
 *
 * @param metadata The document metadata
 * @return YAML frontmatter string, or nil if includeMetadata is NO
 */
- (nullable NSString *)generateYAMLFrontmatter:(PDF21MDDocumentMetadata *)metadata;

/**
 * Generates markdown content from elements without frontmatter.
 *
 * @param elements Array of content elements
 * @return The markdown content
 */
- (NSString *)generateMarkdownContent:(NSArray<id<PDF21MDContentElement>> *)elements;

/**
 * Extracts metadata from a PDF document.
 *
 * @param document The PDF document
 * @return Populated metadata object
 */
+ (PDF21MDDocumentMetadata *)extractMetadataFromDocument:(PDFDocument *)document;

/**
 * Escapes a string for safe inclusion in YAML.
 *
 * @param string The string to escape
 * @return The escaped string
 */
+ (NSString *)escapeYAMLString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END