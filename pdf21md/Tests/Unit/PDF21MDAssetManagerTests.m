//
//  PDF21MDAssetManagerTests.m
//  pdf22md-objc
//
//  Unit tests for PDF21MDAssetManager image extraction and management
//

#import <XCTest/XCTest.h>
#import "PDF21MDAssetManager.h"
#import "PDF21MDImageElement.h"
#import "PDF21MDError.h"

@interface PDF21MDAssetManagerTests : XCTestCase
@property (nonatomic, strong) PDF21MDAssetManager *assetManager;
@property (nonatomic, strong) NSString *tempAssetsPath;
@end

@implementation PDF21MDAssetManagerTests

- (void)setUp {
    [super setUp];
    
    // Create temporary assets directory
    self.tempAssetsPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test-assets"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempAssetsPath 
                              withIntermediateDirectories:YES 
                                               attributes:nil 
                                                    error:nil];
    
    self.assetManager = [[PDF21MDAssetManager alloc] initWithAssetsPath:self.tempAssetsPath];
}

- (void)tearDown {
    // Clean up temporary directory
    [[NSFileManager defaultManager] removeItemAtPath:self.tempAssetsPath error:nil];
    self.assetManager = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testAssetManagerInitialization {
    XCTAssertNotNil(self.assetManager, @"Asset manager should initialize successfully");
}

- (void)testInitializationWithNilPath {
    PDF21MDAssetManager *manager = [[PDF21MDAssetManager alloc] initWithAssetsPath:nil];
    XCTAssertNotNil(manager, @"Asset manager should handle nil assets path");
}

- (void)testAssetsDirectoryCreation {
    NSString *newPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"new-assets"];
    PDF21MDAssetManager *manager = [[PDF21MDAssetManager alloc] initWithAssetsPath:newPath];
    
    NSError *error = nil;
    BOOL success = [manager ensureAssetsDirectoryExists:&error];
    
    XCTAssertTrue(success, @"Should successfully create assets directory");
    XCTAssertNil(error, @"Should not return error when creating valid directory");
    
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:newPath isDirectory:&isDirectory];
    XCTAssertTrue(exists && isDirectory, @"Assets directory should exist and be a directory");
    
    // Clean up
    [[NSFileManager defaultManager] removeItemAtPath:newPath error:nil];
}

#pragma mark - Image Processing Tests

- (void)testImageElementCreation {
    // Create a simple test image (1x1 pixel)
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 1, 1, 8, 4, colorSpace, kCGImageAlphaZero);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    PDF21MDImageElement *element = [[PDF21MDImageElement alloc] initWithImage:cgImage 
                                                                        bounds:CGRectMake(0, 0, 100, 100) 
                                                                    pageNumber:1];
    
    XCTAssertNotNil(element, @"Should create image element successfully");
    XCTAssertEqual(element.pageNumber, 1, @"Page number should be set correctly");
    XCTAssertEqualWithAccuracy(element.bounds.size.width, 100.0, 0.1, @"Width should be set correctly");
    
    // Clean up
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

- (void)testImageFormatSelection {
    // Test PNG selection for images with transparency
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 10, 10, 8, 40, colorSpace, kCGImageAlphaFirst);
    CGImageRef transparentImage = CGBitmapContextCreateImage(context);
    
    NSString *format = [self.assetManager preferredFormatForImage:transparentImage];
    XCTAssertEqualObjects(format, @"png", @"Should prefer PNG for images with transparency");
    
    CGImageRelease(transparentImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

- (void)testImageFilenameGeneration {
    NSString *filename1 = [self.assetManager generateFilenameForImageAtIndex:0 withFormat:@"png"];
    NSString *filename2 = [self.assetManager generateFilenameForImageAtIndex:1 withFormat:@"jpg"];
    NSString *filename3 = [self.assetManager generateFilenameForImageAtIndex:99 withFormat:@"png"];
    
    XCTAssertEqualObjects(filename1, @"image_001.png", @"Should generate correct filename for index 0");
    XCTAssertEqualObjects(filename2, @"image_002.jpg", @"Should generate correct filename for index 1");
    XCTAssertEqualObjects(filename3, @"image_100.png", @"Should generate correct filename for index 99");
}

#pragma mark - File Path Tests

- (void)testRelativePathGeneration {
    NSString *filename = @"image_001.png";
    NSString *relativePath = [self.assetManager relativePathForFilename:filename];
    
    NSString *expectedPath = [@"test-assets" stringByAppendingPathComponent:filename];
    XCTAssertEqualObjects(relativePath, expectedPath, @"Should generate correct relative path");
}

- (void)testAbsolutePathGeneration {
    NSString *filename = @"image_001.png";
    NSString *absolutePath = [self.assetManager absolutePathForFilename:filename];
    
    NSString *expectedPath = [self.tempAssetsPath stringByAppendingPathComponent:filename];
    XCTAssertEqualObjects(absolutePath, expectedPath, @"Should generate correct absolute path");
}

#pragma mark - Error Handling Tests

- (void)testInvalidAssetsPathHandling {
    // Try to create assets directory in a location that requires root access
    NSString *invalidPath = @"/usr/bin/invalid-assets";
    PDF21MDAssetManager *manager = [[PDF21MDAssetManager alloc] initWithAssetsPath:invalidPath];
    
    NSError *error = nil;
    BOOL success = [manager ensureAssetsDirectoryExists:&error];
    
    XCTAssertFalse(success, @"Should fail to create directory in invalid location");
    XCTAssertNotNil(error, @"Should return error for invalid directory creation");
    XCTAssertEqual(error.code, PDF21MDErrorAssetFolderCreation, @"Should return appropriate error code");
}

- (void)testNilImageHandling {
    NSString *result = [self.assetManager preferredFormatForImage:NULL];
    XCTAssertEqualObjects(result, @"png", @"Should default to PNG for nil image");
}

#pragma mark - Integration Tests

- (void)testCompleteImageSaveWorkflow {
    // Create a test image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 50, 50, 8, 200, colorSpace, kCGImageAlphaZero);
    
    // Draw something simple
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, 50, 50));
    
    CGImageRef testImage = CGBitmapContextCreateImage(context);
    
    // Test the save workflow
    NSError *error = nil;
    BOOL directoryCreated = [self.assetManager ensureAssetsDirectoryExists:&error];
    XCTAssertTrue(directoryCreated, @"Should create assets directory");
    
    NSString *filename = [self.assetManager generateFilenameForImageAtIndex:0 withFormat:@"png"];
    NSString *absolutePath = [self.assetManager absolutePathForFilename:filename];
    
    // Save image (this would normally be done by the asset manager)
    NSData *imageData = (__bridge_transfer NSData *)CGImagePNGRepresentation(testImage);
    BOOL saved = [imageData writeToFile:absolutePath atomically:YES];
    XCTAssertTrue(saved, @"Should save image successfully");
    
    // Verify file exists
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:absolutePath];
    XCTAssertTrue(fileExists, @"Saved image file should exist");
    
    // Clean up
    CGImageRelease(testImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Performance Tests

- (void)testMultipleImageHandling {
    NSMutableArray *images = [NSMutableArray array];
    
    // Create multiple test images
    for (int i = 0; i < 10; i++) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 10, 10, 8, 40, colorSpace, kCGImageAlphaZero);
        CGImageRef image = CGBitmapContextCreateImage(context);
        
        [images addObject:(__bridge id)image];
        
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    
    NSDate *startTime = [NSDate date];
    
    // Test filename generation for all images
    for (int i = 0; i < images.count; i++) {
        NSString *filename = [self.assetManager generateFilenameForImageAtIndex:i withFormat:@"png"];
        XCTAssertNotNil(filename, @"Should generate filename for image %d", i);
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
    XCTAssertLessThan(elapsed, 1.0, @"Should handle multiple images quickly");
    
    // Clean up images
    for (id image in images) {
        CGImageRelease((__bridge CGImageRef)image);
    }
}

// Helper function for PNG representation (normally would be in asset manager)
CFDataRef CGImagePNGRepresentation(CGImageRef image) {
    CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, NULL);
    
    if (destination) {
        CGImageDestinationAddImage(destination, image, NULL);
        CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    
    return data;
}

@end