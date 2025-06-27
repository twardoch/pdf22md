//
//  EndToEndConversionTests.m
//  pdf22md-objc
//
//  Integration tests for complete PDF to Markdown conversion pipeline
//

#import <XCTest/XCTest.h>
#import "PDF22MDConverter.h"
#import "PDF22MDConversionOptions.h"
#import "PDF22MDError.h"

@interface EndToEndConversionTests : XCTestCase
@property (nonatomic, strong) PDF22MDConverter *converter;
@property (nonatomic, strong) NSString *testResourcesPath;
@property (nonatomic, strong) NSString *tempOutputPath;
@end

@implementation EndToEndConversionTests

- (void)setUp {
    [super setUp];
    self.converter = [[PDF22MDConverter alloc] init];
    
    // Set up test resources path
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self.testResourcesPath = [bundle.resourcePath stringByAppendingPathComponent:@"Tests/Resources"];
    
    // Create temporary output directory
    self.tempOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"pdf22md-test-output"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempOutputPath 
                              withIntermediateDirectories:YES 
                                               attributes:nil 
                                                    error:nil];
}

- (void)tearDown {
    // Clean up temporary directory
    [[NSFileManager defaultManager] removeItemAtPath:self.tempOutputPath error:nil];
    self.converter = nil;
    [super tearDown];
}

#pragma mark - Complete Workflow Tests

- (void)testSimpleTextDocumentConversion {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-text.pdf"];
    
    // Skip test if resource file doesn't exist
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF 'simple-text.pdf' not found, skipping test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    options.assetsPath = [self.tempOutputPath stringByAppendingPathComponent:@"assets"];
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    XCTAssertNotNil(markdown, @"Should successfully convert simple text PDF");
    XCTAssertNil(error, @"Should not return error for valid PDF conversion");
    
    // Validate markdown structure
    [self validateBasicMarkdownStructure:markdown];
    
    // Check that assets directory was created (even if empty)
    BOOL isDirectory;
    BOOL assetsExist = [[NSFileManager defaultManager] fileExistsAtPath:options.assetsPath 
                                                            isDirectory:&isDirectory];
    XCTAssertTrue(assetsExist && isDirectory, @"Assets directory should be created");
}

- (void)testComplexDocumentWithImages {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"complex-with-images.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF 'complex-with-images.pdf' not found, skipping test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    options.assetsPath = [self.tempOutputPath stringByAppendingPathComponent:@"assets"];
    options.dpi = 200; // Higher DPI for quality
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    XCTAssertNotNil(markdown, @"Should successfully convert complex PDF with images");
    XCTAssertNil(error, @"Should not return error for valid PDF conversion");
    
    // Validate markdown structure
    [self validateBasicMarkdownStructure:markdown];
    
    // Check for image references in markdown
    XCTAssertTrue([markdown containsString:@"!["], @"Should contain image references");
    XCTAssertTrue([markdown containsString:@"assets/"], @"Should reference assets directory");
    
    // Verify that image files were actually created
    NSArray *assetFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:options.assetsPath error:nil];
    XCTAssertTrue(assetFiles.count > 0, @"Should extract at least one asset file");
    
    // Verify image file formats
    for (NSString *filename in assetFiles) {
        XCTAssertTrue([filename hasSuffix:@".png"] || [filename hasSuffix:@".jpg"], 
                      @"Asset files should be PNG or JPG format");
    }
}

- (void)testLargeDocumentPerformance {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"large-document.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF 'large-document.pdf' not found, skipping test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    options.assetsPath = [self.tempOutputPath stringByAppendingPathComponent:@"assets"];
    
    NSDate *startTime = [NSDate date];
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
    
    XCTAssertNotNil(markdown, @"Should successfully convert large PDF");
    XCTAssertNil(error, @"Should not return error for valid large PDF");
    XCTAssertLessThan(elapsed, 30.0, @"Large document conversion should complete within 30 seconds");
    
    NSLog(@"Large document conversion time: %.2f seconds", elapsed);
}

#pragma mark - Error Handling Integration Tests

- (void)testMalformedPDFHandling {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"malformed.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF 'malformed.pdf' not found, skipping test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    // Should either succeed with partial content or fail gracefully
    if (markdown) {
        XCTAssertNil(error, @"If conversion succeeds, should not return error");
        XCTAssertTrue(markdown.length > 0, @"If conversion succeeds, should return content");
    } else {
        XCTAssertNotNil(error, @"If conversion fails, should return meaningful error");
        XCTAssertNotEqual(error.code, 0, @"Error should have meaningful error code");
        XCTAssertTrue(error.localizedDescription.length > 0, @"Error should have description");
    }
}

- (void)testEncryptedPDFHandling {
    // This test would require an encrypted PDF sample
    // For now, we'll test the expected behavior
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"encrypted.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF 'encrypted.pdf' not found, skipping test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    XCTAssertNil(markdown, @"Should not convert encrypted PDF without password");
    XCTAssertNotNil(error, @"Should return error for encrypted PDF");
    XCTAssertEqual(error.code, PDF22MDErrorEncryptedPDF, @"Should return encrypted PDF error code");
}

#pragma mark - Memory Stress Tests

- (void)testMemoryStabilityUnderLoad {
    // Test multiple conversions to ensure memory stability
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    options.assetsPath = [self.tempOutputPath stringByAppendingPathComponent:@"stress-assets"];
    
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-text.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF not found, creating minimal test for memory stability");
        return;
    }
    
    // Run multiple conversions
    for (int i = 0; i < 5; i++) {
        @autoreleasepool {
            NSError *error = nil;
            NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                                      withOptions:options 
                                                            error:&error];
            
            XCTAssertNotNil(markdown, @"Conversion %d should succeed", i + 1);
            XCTAssertNil(error, @"Conversion %d should not return error", i + 1);
        }
    }
}

#pragma mark - Output Validation Tests

- (void)testMarkdownOutputQuality {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-text.pdf"];
    
    if (![self fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF not found, skipping output quality test");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    
    NSError *error = nil;
    NSString *markdown = [self.converter convertPDFAtPath:testPDFPath 
                                              withOptions:options 
                                                    error:&error];
    
    XCTAssertNotNil(markdown, @"Should produce markdown output");
    
    if (markdown) {
        [self validateAdvancedMarkdownStructure:markdown];
    }
}

- (void)testExpectedOutputComparison {
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-text.pdf"];
    NSString *expectedPath = [self.testResourcesPath stringByAppendingPathComponent:@"expected-outputs/simple-text.md"];
    
    if (![self fileExistsAtPath:testPDFPath] || ![self fileExistsAtPath:expectedPath]) {
        NSLog(@"Test files not found, skipping expected output comparison");
        return;
    }
    
    PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
    
    NSError *error = nil;
    NSString *actualMarkdown = [self.converter convertPDFAtPath:testPDFPath 
                                                    withOptions:options 
                                                          error:&error];
    
    NSString *expectedMarkdown = [NSString stringWithContentsOfFile:expectedPath 
                                                           encoding:NSUTF8StringEncoding 
                                                              error:nil];
    
    XCTAssertNotNil(actualMarkdown, @"Should produce actual markdown");
    XCTAssertNotNil(expectedMarkdown, @"Should load expected markdown");
    
    if (actualMarkdown && expectedMarkdown) {
        // Normalize whitespace for comparison
        NSString *normalizedActual = [self normalizeWhitespace:actualMarkdown];
        NSString *normalizedExpected = [self normalizeWhitespace:expectedMarkdown];
        
        XCTAssertEqualObjects(normalizedActual, normalizedExpected, 
                              @"Actual output should match expected output");
    }
}

#pragma mark - Helper Methods

- (BOOL)fileExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)validateBasicMarkdownStructure:(NSString *)markdown {
    XCTAssertTrue(markdown.length > 0, @"Markdown should not be empty");
    
    // Should not contain raw PDF artifacts
    XCTAssertFalse([markdown containsString:@"%%PDF"], @"Should not contain PDF header");
    XCTAssertFalse([markdown containsString:@"endobj"], @"Should not contain PDF objects");
    
    // Should be valid UTF-8
    NSData *data = [markdown dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(data, @"Markdown should be valid UTF-8");
}

- (void)validateAdvancedMarkdownStructure:(NSString *)markdown {
    [self validateBasicMarkdownStructure:markdown];
    
    // Check for proper markdown formatting
    NSArray *lines = [markdown componentsSeparatedByString:@"\n"];
    
    BOOL hasHeadings = NO;
    BOOL hasContent = NO;
    
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([trimmed hasPrefix:@"#"]) {
            hasHeadings = YES;
            // Validate heading format
            XCTAssertTrue([trimmed rangeOfString:@"# "].location != NSNotFound ||
                         [trimmed rangeOfString:@"## "].location != NSNotFound ||
                         [trimmed rangeOfString:@"### "].location != NSNotFound,
                         @"Headings should have proper spacing");
        }
        
        if (trimmed.length > 0 && ![trimmed hasPrefix:@"#"] && ![trimmed hasPrefix:@"!"]) {
            hasContent = YES;
        }
    }
    
    // Don't require headings for all documents, but if present, they should be formatted correctly
    if (hasHeadings) {
        XCTAssertTrue(hasContent, @"Document with headings should also have content");
    }
}

- (NSString *)normalizeWhitespace:(NSString *)text {
    // Normalize line endings and excessive whitespace for comparison
    NSString *normalized = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    // Remove trailing whitespace from lines
    NSMutableArray *lines = [[normalized componentsSeparatedByString:@"\n"] mutableCopy];
    for (NSInteger i = 0; i < lines.count; i++) {
        lines[i] = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return [lines componentsJoinedByString:@"\n"];
}

@end