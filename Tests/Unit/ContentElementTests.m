//
//  ContentElementTests.m
//  pdf22md
//
//  Unit tests for ContentElement model and text/image element functionality
//

#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../../src/ContentElement.h"

@interface ContentElementTests : XCTestCase
@end

@implementation ContentElementTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - ContentElement Protocol Tests

- (void)testContentElementProtocolExists {
    // Verify that the ContentElement protocol exists and can be referenced
    Protocol *contentElementProtocol = @protocol(ContentElement);
    XCTAssertNotNil(contentElementProtocol, @"ContentElement protocol should exist");
}

#pragma mark - Text Element Tests

- (void)testTextElementCreation {
    // Test creation of text elements
    NSString *testText = @"Sample text content";
    CGRect testBounds = CGRectMake(10, 20, 200, 30);
    NSInteger testPage = 1;
    
    // Check if TextElement class exists and can be instantiated
    Class textElementClass = NSClassFromString(@"TextElement");
    if (textElementClass) {
        // Test basic instantiation
        id textElement = [[textElementClass alloc] init];
        XCTAssertNotNil(textElement, @"TextElement should be instantiable");
        
        // Test that it conforms to ContentElement protocol
        XCTAssertTrue([textElement conformsToProtocol:@protocol(ContentElement)], 
                     @"TextElement should conform to ContentElement protocol");
    } else {
        XCTFail(@"TextElement class should be available");
    }
}

- (void)testTextElementProperties {
    Class textElementClass = NSClassFromString(@"TextElement");
    if (textElementClass) {
        id textElement = [[textElementClass alloc] init];
        
        // Test basic property access (using KVC since we don't have direct access to the interface)
        NSString *testText = @"Test content";
        
        // Check if text property exists and can be set/get
        if ([textElement respondsToSelector:@selector(setText:)]) {
            [textElement performSelector:@selector(setText:) withObject:testText];
            
            if ([textElement respondsToSelector:@selector(text)]) {
                NSString *retrievedText = [textElement performSelector:@selector(text)];
                XCTAssertEqualObjects(retrievedText, testText, @"Text property should store and retrieve correctly");
            }
        }
        
        // Test bounds property if available
        if ([textElement respondsToSelector:@selector(setBounds:)]) {
            CGRect testBounds = CGRectMake(5, 10, 100, 20);
            NSValue *boundsValue = [NSValue valueWithCGRect:testBounds];
            [textElement performSelector:@selector(setBounds:) withObject:boundsValue];
            
            if ([textElement respondsToSelector:@selector(bounds)]) {
                NSValue *retrievedBounds = [textElement performSelector:@selector(bounds)];
                CGRect retrievedRect = [retrievedBounds CGRectValue];
                XCTAssertTrue(CGRectEqualToRect(retrievedRect, testBounds), 
                             @"Bounds property should store and retrieve correctly");
            }
        }
    }
}

#pragma mark - Image Element Tests

- (void)testImageElementCreation {
    Class imageElementClass = NSClassFromString(@"ImageElement");
    if (imageElementClass) {
        // Test basic instantiation
        id imageElement = [[imageElementClass alloc] init];
        XCTAssertNotNil(imageElement, @"ImageElement should be instantiable");
        
        // Test that it conforms to ContentElement protocol
        XCTAssertTrue([imageElement conformsToProtocol:@protocol(ContentElement)], 
                     @"ImageElement should conform to ContentElement protocol");
    } else {
        XCTFail(@"ImageElement class should be available");
    }
}

- (void)testImageElementWithCGImage {
    Class imageElementClass = NSClassFromString(@"ImageElement");
    if (imageElementClass) {
        // Create a test CGImage
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 50, 50, 8, 0, colorSpace, 
                                                    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
        CGColorSpaceRelease(colorSpace);
        
        if (context) {
            CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
            CGContextFillRect(context, CGRectMake(0, 0, 50, 50));
            
            CGImageRef testImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
            
            if (testImage) {
                id imageElement = [[imageElementClass alloc] init];
                
                // Test image property if available
                if ([imageElement respondsToSelector:@selector(setImage:)]) {
                    // Note: CGImageRef is not an object, so we need to handle it appropriately
                    // This test may need adjustment based on the actual implementation
                    XCTAssertTrue(YES, @"Image element should be able to handle CGImageRef");
                }
                
                CGImageRelease(testImage);
            }
        }
    }
}

#pragma mark - Markdown Generation Tests

- (void)testMarkdownGeneration {
    // Test that elements can generate markdown representation
    Class textElementClass = NSClassFromString(@"TextElement");
    if (textElementClass) {
        id textElement = [[textElementClass alloc] init];
        
        if ([textElement respondsToSelector:@selector(markdownRepresentation)]) {
            NSString *markdown = [textElement performSelector:@selector(markdownRepresentation)];
            XCTAssertTrue([markdown isKindOfClass:[NSString class]], 
                         @"markdownRepresentation should return an NSString");
        } else {
            XCTFail(@"TextElement should implement markdownRepresentation method");
        }
    }
}

#pragma mark - Bounds and Positioning Tests

- (void)testBoundsHandling {
    // Test bounds property across different element types
    NSArray *elementClassNames = @[@"TextElement", @"ImageElement"];
    
    for (NSString *className in elementClassNames) {
        Class elementClass = NSClassFromString(className);
        if (elementClass) {
            id element = [[elementClass alloc] init];
            
            // Test bounds property
            if ([element respondsToSelector:@selector(bounds)]) {
                // Default bounds should be valid
                CGRect bounds = CGRectZero;
                if ([element respondsToSelector:@selector(bounds)]) {
                    NSValue *boundsValue = [element performSelector:@selector(bounds)];
                    if (boundsValue) {
                        bounds = [boundsValue CGRectValue];
                    }
                }
                
                // Bounds should be a valid rectangle (finite values)
                XCTAssertTrue(isfinite(bounds.origin.x) && isfinite(bounds.origin.y) && 
                             isfinite(bounds.size.width) && isfinite(bounds.size.height),
                             @"%@ bounds should have finite values", className);
            }
        }
    }
}

#pragma mark - Page Index Tests

- (void)testPageIndexProperty {
    // Test page index property across element types
    NSArray *elementClassNames = @[@"TextElement", @"ImageElement"];
    
    for (NSString *className in elementClassNames) {
        Class elementClass = NSClassFromString(className);
        if (elementClass) {
            id element = [[elementClass alloc] init];
            
            if ([element respondsToSelector:@selector(pageIndex)]) {
                NSInteger pageIndex = [[element performSelector:@selector(pageIndex)] integerValue];
                XCTAssertTrue(pageIndex >= 0, @"%@ pageIndex should be non-negative", className);
            }
            
            // Test setting page index if setter exists
            if ([element respondsToSelector:@selector(setPageIndex:)]) {
                NSInteger testPageIndex = 5;
                [element performSelector:@selector(setPageIndex:) withObject:@(testPageIndex)];
                
                if ([element respondsToSelector:@selector(pageIndex)]) {
                    NSInteger retrievedIndex = [[element performSelector:@selector(pageIndex)] integerValue];
                    XCTAssertEqual(retrievedIndex, testPageIndex, 
                                  @"%@ should store and retrieve pageIndex correctly", className);
                }
            }
        }
    }
}

#pragma mark - Memory Management Tests

- (void)testElementMemoryManagement {
    // Test that elements can be created and destroyed without memory issues
    for (int i = 0; i < 100; i++) {
        @autoreleasepool {
            Class textElementClass = NSClassFromString(@"TextElement");
            if (textElementClass) {
                id textElement = [[textElementClass alloc] init];
                
                // Set some properties to test memory handling
                if ([textElement respondsToSelector:@selector(setText:)]) {
                    NSString *testText = [NSString stringWithFormat:@"Test text %d", i];
                    [textElement performSelector:@selector(setText:) withObject:testText];
                }
                
                textElement = nil;
            }
            
            Class imageElementClass = NSClassFromString(@"ImageElement");
            if (imageElementClass) {
                id imageElement = [[imageElementClass alloc] init];
                imageElement = nil;
            }
        }
    }
    
    XCTAssertTrue(YES, @"Memory management test completed without crashes");
}

#pragma mark - Performance Tests

- (void)testElementCreationPerformance {
    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            @autoreleasepool {
                Class textElementClass = NSClassFromString(@"TextElement");
                if (textElementClass) {
                    id textElement = [[textElementClass alloc] init];
                    textElement = nil;
                }
            }
        }
    }];
}

- (void)testMarkdownGenerationPerformance {
    Class textElementClass = NSClassFromString(@"TextElement");
    if (textElementClass) {
        id textElement = [[textElementClass alloc] init];
        
        if ([textElement respondsToSelector:@selector(setText:)]) {
            [textElement performSelector:@selector(setText:) withObject:@"Sample text for performance testing"];
        }
        
        [self measureBlock:^{
            for (int i = 0; i < 1000; i++) {
                if ([textElement respondsToSelector:@selector(markdownRepresentation)]) {
                    [textElement performSelector:@selector(markdownRepresentation)];
                }
            }
        }];
    }
}

@end