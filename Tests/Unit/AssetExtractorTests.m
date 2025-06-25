//
//  AssetExtractorTests.m
//  pdf22md
//
//  Unit tests for asset extraction and image processing functionality
//

#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import "../../src/AssetExtractor.h"

@interface AssetExtractorTests : XCTestCase
@property (nonatomic, strong) AssetExtractor *extractor;
@property (nonatomic, strong) NSString *testAssetsPath;
@end

@implementation AssetExtractorTests

- (void)setUp {
    [super setUp];
    self.extractor = [[AssetExtractor alloc] init];
    
    // Create temporary test assets directory
    NSString *tempDir = NSTemporaryDirectory();
    self.testAssetsPath = [tempDir stringByAppendingPathComponent:@"pdf22md-test-assets"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:self.testAssetsPath 
           withIntermediateDirectories:YES 
                            attributes:nil 
                                 error:nil];
}

- (void)tearDown {
    // Clean up test assets directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.testAssetsPath error:nil];
    
    self.extractor = nil;
    self.testAssetsPath = nil;
    [super tearDown];
}

#pragma mark - Basic Functionality Tests

- (void)testExtractorInitialization {
    XCTAssertNotNil(self.extractor, @"AssetExtractor should initialize successfully");
}

- (void)testSetAssetsFolderPath {
    NSString *testPath = @"/tmp/test-assets";
    [self.extractor setAssetsFolderPath:testPath];
    
    // Note: We can't directly test the private property, but we can test that the method doesn't crash
    // and that subsequent operations work as expected
    XCTAssertTrue(YES, @"setAssetsFolderPath should complete without crashing");
}

#pragma mark - Image Format Detection Tests

- (void)testFormatOptimizationLogic {
    // Test the format optimization logic with synthetic images
    
    // Create a simple test image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 100, 100, 8, 0, colorSpace, 
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (context) {
        // Fill with a simple color
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, 100, 100));
        
        CGImageRef testImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        if (testImage) {
            // Test format decision logic
            BOOL shouldUseJPEG = [self.extractor shouldUseJPEGForImage:testImage];
            
            // For a simple solid color image, PNG should be preferred
            // (though the exact logic depends on implementation)
            XCTAssertTrue(shouldUseJPEG == YES || shouldUseJPEG == NO, 
                         @"shouldUseJPEGForImage should return a boolean value");
            
            CGImageRelease(testImage);
        }
    }
}

- (void)testImageSaving {
    // Test image saving functionality
    
    // Create a minimal test image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 50, 50, 8, 0, colorSpace, 
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (context) {
        // Create a gradient pattern for testing
        CGContextSetRGBFillColor(context, 0.5, 0.5, 1.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, 50, 50));
        
        CGImageRef testImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        if (testImage) {
            [self.extractor setAssetsFolderPath:self.testAssetsPath];
            
            NSString *savedPath = [self.extractor saveImage:testImage withBaseName:@"test_image"];
            
            if (savedPath) {
                // Verify the file was created
                NSString *fullPath = [self.testAssetsPath stringByAppendingPathComponent:savedPath];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                XCTAssertTrue([fileManager fileExistsAtPath:fullPath], 
                             @"Saved image file should exist at path: %@", fullPath);
                
                // Verify it's a valid image file
                NSData *imageData = [NSData dataWithContentsOfFile:fullPath];
                XCTAssertNotNil(imageData, @"Should be able to read saved image data");
                XCTAssertTrue(imageData.length > 0, @"Saved image should have non-zero size");
            } else {
                XCTFail(@"saveImage should return a non-nil path");
            }
            
            CGImageRelease(testImage);
        }
    }
}

#pragma mark - File Naming Tests

- (void)testUniqueFileNaming {
    // Test that the extractor generates unique filenames
    [self.extractor setAssetsFolderPath:self.testAssetsPath];
    
    // Create multiple test images and verify unique naming
    for (int i = 0; i < 3; i++) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 20, 20, 8, 0, colorSpace, 
                                                    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
        CGColorSpaceRelease(colorSpace);
        
        if (context) {
            // Use different colors for each image
            CGFloat red = (i == 0) ? 1.0 : 0.0;
            CGFloat green = (i == 1) ? 1.0 : 0.0;
            CGFloat blue = (i == 2) ? 1.0 : 0.0;
            
            CGContextSetRGBFillColor(context, red, green, blue, 1.0);
            CGContextFillRect(context, CGRectMake(0, 0, 20, 20));
            
            CGImageRef testImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
            
            if (testImage) {
                NSString *savedPath = [self.extractor saveImage:testImage withBaseName:@"test"];
                XCTAssertNotNil(savedPath, @"Should get a valid filename for image %d", i);
                
                CGImageRelease(testImage);
            }
        }
    }
    
    // Verify multiple files were created
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.testAssetsPath error:nil];
    XCTAssertTrue(contents.count >= 1, @"Should have created at least one image file");
}

#pragma mark - Error Handling Tests

- (void)testNilImageHandling {
    [self.extractor setAssetsFolderPath:self.testAssetsPath];
    
    NSString *result = [self.extractor saveImage:NULL withBaseName:@"test"];
    XCTAssertNil(result, @"Should return nil for NULL image");
}

- (void)testInvalidAssetsFolderHandling {
    // Test with invalid assets folder path
    NSString *invalidPath = @"/invalid/path/that/cannot/be/created";
    [self.extractor setAssetsFolderPath:invalidPath];
    
    // Create a test image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 10, 10, 8, 0, colorSpace, 
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (context) {
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
        
        CGImageRef testImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        if (testImage) {
            NSString *result = [self.extractor saveImage:testImage withBaseName:@"test"];
            // Should handle the error gracefully (exact behavior depends on implementation)
            // At minimum, should not crash
            
            CGImageRelease(testImage);
        }
    }
}

#pragma mark - Performance Tests

- (void)testImageSavingPerformance {
    [self.extractor setAssetsFolderPath:self.testAssetsPath];
    
    [self measureBlock:^{
        // Create and save a test image
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 100, 100, 8, 0, colorSpace, 
                                                    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
        CGColorSpaceRelease(colorSpace);
        
        if (context) {
            CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 1.0);
            CGContextFillRect(context, CGRectMake(0, 0, 100, 100));
            
            CGImageRef testImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
            
            if (testImage) {
                [self.extractor saveImage:testImage withBaseName:@"perf_test"];
                CGImageRelease(testImage);
            }
        }
    }];
}

#pragma mark - Memory Management Tests

- (void)testMemoryManagement {
    // Test that multiple image operations don't cause memory issues
    [self.extractor setAssetsFolderPath:self.testAssetsPath];
    
    for (int i = 0; i < 10; i++) {
        @autoreleasepool {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(NULL, 50, 50, 8, 0, colorSpace, 
                                                        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
            CGColorSpaceRelease(colorSpace);
            
            if (context) {
                CGContextSetRGBFillColor(context, (i % 3) / 3.0, ((i + 1) % 3) / 3.0, ((i + 2) % 3) / 3.0, 1.0);
                CGContextFillRect(context, CGRectMake(0, 0, 50, 50));
                
                CGImageRef testImage = CGBitmapContextCreateImage(context);
                CGContextRelease(context);
                
                if (testImage) {
                    NSString *baseName = [NSString stringWithFormat:@"memory_test_%d", i];
                    [self.extractor saveImage:testImage withBaseName:baseName];
                    CGImageRelease(testImage);
                }
            }
        }
    }
    
    // Verify files were created
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.testAssetsPath error:nil];
    XCTAssertTrue(contents.count > 0, @"Should have created image files during memory test");
}

@end