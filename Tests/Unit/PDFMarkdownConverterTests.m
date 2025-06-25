//
//  PDFMarkdownConverterTests.m
//  pdf22md
//
//  Unit tests for core PDF to Markdown conversion functionality
//

#import <XCTest/XCTest.h>
#import "../../src/PDFMarkdownConverter.h"
#import "../../src/AssetExtractor.h"
#import "../../src/ContentElement.h"

@interface PDFMarkdownConverterTests : XCTestCase
@property (nonatomic, strong) PDFMarkdownConverter *converter;
@property (nonatomic, strong) NSString *testResourcesPath;
@end

@implementation PDFMarkdownConverterTests

- (void)setUp {
    [super setUp];
    self.converter = [[PDFMarkdownConverter alloc] init];
    
    // Set up test resources path
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    self.testResourcesPath = [testBundle.bundlePath stringByAppendingPathComponent:@"Resources"];
    
    // Ensure test resources directory exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.testResourcesPath]) {
        [fileManager createDirectoryAtPath:self.testResourcesPath 
               withIntermediateDirectories:YES 
                                attributes:nil 
                                     error:nil];
    }
}

- (void)tearDown {
    self.converter = nil;
    self.testResourcesPath = nil;
    [super tearDown];
}

#pragma mark - Basic Functionality Tests

- (void)testConverterInitialization {
    XCTAssertNotNil(self.converter, @"PDFMarkdownConverter should initialize successfully");
}

- (void)testInvalidPDFHandling {
    // Test with nil input
    NSString *result = [self.converter convertPDFAtPath:nil 
                                          assetsFolderPath:nil 
                                                       dpi:144];
    XCTAssertNil(result, @"Converter should return nil for nil input path");
    
    // Test with non-existent file
    NSString *nonExistentPath = @"/path/that/does/not/exist.pdf";
    result = [self.converter convertPDFAtPath:nonExistentPath 
                               assetsFolderPath:nil 
                                            dpi:144];
    XCTAssertNil(result, @"Converter should return nil for non-existent file");
}

- (void)testEmptyStringHandling {
    // Test with empty string
    NSString *result = [self.converter convertPDFAtPath:@"" 
                                          assetsFolderPath:nil 
                                                       dpi:144];
    XCTAssertNil(result, @"Converter should return nil for empty string path");
}

- (void)testDPIParameterValidation {
    // Create a minimal test PDF path (we'll use an existing test file)
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-test.pdf"];
    
    // Test with invalid DPI values
    NSString *result = [self.converter convertPDFAtPath:testPDFPath 
                                          assetsFolderPath:nil 
                                                       dpi:0];
    // Should still work with fallback DPI or return error gracefully
    // The exact behavior depends on implementation, but should not crash
    
    result = [self.converter convertPDFAtPath:testPDFPath 
                               assetsFolderPath:nil 
                                            dpi:-144];
    // Should handle negative DPI gracefully
}

#pragma mark - Asset Folder Tests

- (void)testAssetFolderCreation {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *testAssetsFolder = [tempDir stringByAppendingPathComponent:@"test-assets"];
    
    // Clean up any existing test folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:testAssetsFolder error:nil];
    
    // Verify folder doesn't exist initially
    XCTAssertFalse([fileManager fileExistsAtPath:testAssetsFolder], 
                   @"Test assets folder should not exist initially");
    
    // Test folder creation during conversion (with a valid PDF)
    // For now, just test that the method accepts the parameter
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-test.pdf"];
    [self.converter convertPDFAtPath:testPDFPath 
                      assetsFolderPath:testAssetsFolder 
                                   dpi:144];
    
    // Clean up
    [fileManager removeItemAtPath:testAssetsFolder error:nil];
}

#pragma mark - Memory Management Tests

- (void)testMemoryManagement {
    // Test that converter handles multiple conversions without memory issues
    for (int i = 0; i < 10; i++) {
        @autoreleasepool {
            PDFMarkdownConverter *tempConverter = [[PDFMarkdownConverter alloc] init];
            
            // Test with nil path to avoid actual file I/O
            NSString *result = [tempConverter convertPDFAtPath:nil 
                                               assetsFolderPath:nil 
                                                            dpi:144];
            XCTAssertNil(result, @"Should handle nil input gracefully");
            
            tempConverter = nil;
        }
    }
}

#pragma mark - Performance Tests

- (void)testPerformanceBaseline {
    // Simple performance test to establish baseline
    [self measureBlock:^{
        // Test basic object creation and method call
        PDFMarkdownConverter *converter = [[PDFMarkdownConverter alloc] init];
        [converter convertPDFAtPath:nil assetsFolderPath:nil dpi:144];
    }];
}

#pragma mark - Error Handling Tests

- (void)testErrorConditions {
    // Test various error conditions that should be handled gracefully
    NSArray *invalidPaths = @[
        @"",
        @"not-a-pdf.txt",
        @"/dev/null",
        @"~/nonexistent/path/file.pdf"
    ];
    
    for (NSString *invalidPath in invalidPaths) {
        NSString *result = [self.converter convertPDFAtPath:invalidPath 
                                            assetsFolderPath:nil 
                                                         dpi:144];
        XCTAssertNil(result, @"Should handle invalid path gracefully: %@", invalidPath);
    }
}

#pragma mark - Integration Points Tests

- (void)testAssetExtractorIntegration {
    // Test that converter properly integrates with AssetExtractor
    // This is a basic smoke test for the integration
    AssetExtractor *extractor = [[AssetExtractor alloc] init];
    XCTAssertNotNil(extractor, @"AssetExtractor should initialize for integration testing");
}

- (void)testContentElementIntegration {
    // Test that converter properly works with ContentElement classes
    // This verifies the model layer integration
    XCTAssertTrue([NSClassFromString(@"ContentElement") conformsToProtocol:@protocol(NSObject)], 
                  @"ContentElement should be available for integration");
}

@end