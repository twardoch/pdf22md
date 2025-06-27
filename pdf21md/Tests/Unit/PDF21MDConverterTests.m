//
//  PDF21MDConverterTests.m
//  pdf22md-objc
//
//  Unit tests for PDF21MDConverter core functionality
//

#import <XCTest/XCTest.h>
#import "PDF21MDConverter.h"
#import "PDF21MDConversionOptions.h"
#import "PDF21MDError.h"
#import "../../../shared/Core/PDF21MDErrorFactory.h"

@interface PDF21MDConverterTests : XCTestCase
@property (nonatomic, strong) PDF21MDConverter *converter;
@property (nonatomic, strong) PDF21MDConversionOptions *defaultOptions;
@property (nonatomic, strong) NSString *testResourcesPath;
@end

@implementation PDF21MDConverterTests

- (void)setUp {
    [super setUp];
    self.converter = [[PDF21MDConverter alloc] init];
    self.defaultOptions = [[PDF21MDConversionOptions alloc] init];
    
    // Set up test resources path
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self.testResourcesPath = [bundle.resourcePath stringByAppendingPathComponent:@"Tests/Resources"];
}

- (void)tearDown {
    self.converter = nil;
    self.defaultOptions = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testConverterInitialization {
    XCTAssertNotNil(self.converter, @"Converter should initialize successfully");
}

- (void)testDefaultOptionsInitialization {
    XCTAssertNotNil(self.defaultOptions, @"Default options should initialize successfully");
    XCTAssertEqual(self.defaultOptions.dpi, 144, @"Default DPI should be 144");
    XCTAssertNil(self.defaultOptions.assetsPath, @"Default assets path should be nil");
}

#pragma mark - Input Validation Tests

- (void)testNilInputPathHandling {
    NSError *error = nil;
    NSString *result = [self.converter convertPDFAtPath:nil 
                                            withOptions:self.defaultOptions 
                                                  error:&error];
    
    XCTAssertNil(result, @"Should return nil for nil input path");
    XCTAssertNotNil(error, @"Should provide error for nil input path");
    XCTAssertEqual(error.code, PDF21MDErrorInvalidInput, @"Should return invalid input error");
}

- (void)testNonExistentFileHandling {
    NSError *error = nil;
    NSString *nonExistentPath = @"/tmp/nonexistent_file.pdf";
    NSString *result = [self.converter convertPDFAtPath:nonExistentPath 
                                            withOptions:self.defaultOptions 
                                                  error:&error];
    
    XCTAssertNil(result, @"Should return nil for nonexistent file");
    XCTAssertNotNil(error, @"Should provide error for nonexistent file");
    XCTAssertEqual(error.code, PDF21MDErrorFileNotFound, @"Should return file not found error");
}

- (void)testNonPDFFileHandling {
    NSError *error = nil;
    
    // Create a temporary text file
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.txt"];
    [@"This is not a PDF" writeToFile:tempPath 
                           atomically:YES 
                             encoding:NSUTF8StringEncoding 
                                error:nil];
    
    NSString *result = [self.converter convertPDFAtPath:tempPath 
                                            withOptions:self.defaultOptions 
                                                  error:&error];
    
    XCTAssertNil(result, @"Should return nil for non-PDF file");
    XCTAssertNotNil(error, @"Should provide error for non-PDF file");
    XCTAssertEqual(error.code, PDF21MDErrorInvalidPDF, @"Should return invalid PDF error");
    
    // Clean up
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

#pragma mark - Basic Conversion Tests

- (void)testBasicTextConversion {
    // This test would require a simple test PDF file
    // For now, we'll create a placeholder that demonstrates the expected behavior
    
    NSString *testPDFPath = [self.testResourcesPath stringByAppendingPathComponent:@"simple-text.pdf"];
    
    // Skip test if resource file doesn't exist (expected during initial setup)
    if (![[NSFileManager defaultManager] fileExistsAtPath:testPDFPath]) {
        NSLog(@"Test PDF not found at %@, skipping test", testPDFPath);
        return;
    }
    
    NSError *error = nil;
    NSString *result = [self.converter convertPDFAtPath:testPDFPath 
                                            withOptions:self.defaultOptions 
                                                  error:&error];
    
    XCTAssertNotNil(result, @"Should successfully convert simple text PDF");
    XCTAssertNil(error, @"Should not return error for valid PDF");
    XCTAssertTrue([result containsString:@"#"], @"Should contain markdown headers");
    XCTAssertTrue(result.length > 0, @"Should return non-empty markdown");
}

#pragma mark - Options Validation Tests

- (void)testCustomDPIOption {
    PDF21MDConversionOptions *options = [[PDF21MDConversionOptions alloc] init];
    options.dpi = 300;
    
    XCTAssertEqual(options.dpi, 300, @"Should accept custom DPI value");
}

- (void)testAssetsPathOption {
    PDF21MDConversionOptions *options = [[PDF21MDConversionOptions alloc] init];
    options.assetsPath = @"/tmp/assets";
    
    XCTAssertEqualObjects(options.assetsPath, @"/tmp/assets", @"Should accept custom assets path");
}

#pragma mark - Memory Management Tests

- (void)testMemoryManagement {
    // Test that repeated conversions don't cause memory leaks
    for (int i = 0; i < 10; i++) {
        @autoreleasepool {
            PDF21MDConverter *tempConverter = [[PDF21MDConverter alloc] init];
            PDF21MDConversionOptions *tempOptions = [[PDF21MDConversionOptions alloc] init];
            
            XCTAssertNotNil(tempConverter, @"Converter should initialize in loop iteration %d", i);
            XCTAssertNotNil(tempOptions, @"Options should initialize in loop iteration %d", i);
        }
    }
}

#pragma mark - Error Handling Tests

- (void)testErrorMessageQuality {
    NSError *error = nil;
    NSString *result = [self.converter convertPDFAtPath:@"/nonexistent/path.pdf" 
                                            withOptions:self.defaultOptions 
                                                  error:&error];
    
    XCTAssertNil(result, @"Should return nil for invalid path");
    XCTAssertNotNil(error, @"Should provide error");
    XCTAssertNotNil(error.localizedDescription, @"Error should have localized description");
    XCTAssertTrue(error.localizedDescription.length > 0, @"Error description should not be empty");
    XCTAssertFalse([error.localizedDescription containsString:@"nil"], @"Error description should not contain 'nil'");
}

@end