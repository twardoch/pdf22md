//
//  PDF22MDFontAnalyzerTests.m
//  pdf22md-objc
//
//  Unit tests for PDF22MDFontAnalyzer heading detection logic
//

#import <XCTest/XCTest.h>
#import "PDF22MDFontAnalyzer.h"

@interface PDF22MDFontAnalyzerTests : XCTestCase
@property (nonatomic, strong) PDF22MDFontAnalyzer *analyzer;
@end

@implementation PDF22MDFontAnalyzerTests

- (void)setUp {
    [super setUp];
    self.analyzer = [[PDF22MDFontAnalyzer alloc] init];
}

- (void)tearDown {
    self.analyzer = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testAnalyzerInitialization {
    XCTAssertNotNil(self.analyzer, @"Font analyzer should initialize successfully");
}

#pragma mark - Font Size Analysis Tests

- (void)testBasicFontSizeAnalysis {
    // Test the core font size analysis functionality
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    
    // Simulate typical document font usage
    fontSizes[@"12.0"] = @100;  // Body text - most frequent
    fontSizes[@"18.0"] = @5;    // Major heading
    fontSizes[@"16.0"] = @8;    // Minor heading
    fontSizes[@"14.0"] = @12;   // Subheading
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    // Test heading level assignment
    NSInteger h1Level = [self.analyzer headingLevelForFontSize:18.0];
    NSInteger h2Level = [self.analyzer headingLevelForFontSize:16.0];
    NSInteger h3Level = [self.analyzer headingLevelForFontSize:14.0];
    NSInteger bodyLevel = [self.analyzer headingLevelForFontSize:12.0];
    
    XCTAssertEqual(h1Level, 1, @"Largest non-body font should be H1");
    XCTAssertEqual(h2Level, 2, @"Second largest font should be H2");
    XCTAssertEqual(h3Level, 3, @"Third largest font should be H3");
    XCTAssertEqual(bodyLevel, 0, @"Most frequent font should be body text (level 0)");
}

- (void)testSingleFontSizeDocument {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"12.0"] = @100;  // Only one font size
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    NSInteger level = [self.analyzer headingLevelForFontSize:12.0];
    XCTAssertEqual(level, 0, @"Single font size should be treated as body text");
}

- (void)testEmptyFontAnalysis {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    NSInteger level = [self.analyzer headingLevelForFontSize:12.0];
    XCTAssertEqual(level, 0, @"Unknown font size should default to body text");
}

#pragma mark - Edge Case Tests

- (void)testVerySmallFontSizes {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"8.0"] = @50;    // Small body text
    fontSizes[@"10.0"] = @5;    // Slightly larger
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    NSInteger smallLevel = [self.analyzer headingLevelForFontSize:8.0];
    NSInteger largerLevel = [self.analyzer headingLevelForFontSize:10.0];
    
    XCTAssertEqual(smallLevel, 0, @"Most frequent small font should be body text");
    XCTAssertEqual(largerLevel, 1, @"Less frequent larger font should be heading");
}

- (void)testVeryLargeFontSizes {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"12.0"] = @100;  // Body text
    fontSizes[@"72.0"] = @1;    // Very large title
    fontSizes[@"48.0"] = @2;    // Large heading
    fontSizes[@"36.0"] = @3;    // Medium heading
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    NSInteger titleLevel = [self.analyzer headingLevelForFontSize:72.0];
    NSInteger h1Level = [self.analyzer headingLevelForFontSize:48.0];
    NSInteger h2Level = [self.analyzer headingLevelForFontSize:36.0];
    
    XCTAssertEqual(titleLevel, 1, @"Largest font should be H1");
    XCTAssertEqual(h1Level, 2, @"Second largest should be H2");
    XCTAssertEqual(h2Level, 3, @"Third largest should be H3");
}

#pragma mark - Frequency Analysis Tests

- (void)testFrequencyBasedBodyTextDetection {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"12.0"] = @200;  // Very frequent - clearly body text
    fontSizes[@"14.0"] = @150;  // Also frequent - might be body text too
    fontSizes[@"18.0"] = @5;    // Infrequent - heading
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    NSInteger mostFrequentLevel = [self.analyzer headingLevelForFontSize:12.0];
    NSInteger secondFrequentLevel = [self.analyzer headingLevelForFontSize:14.0];
    NSInteger infrequentLevel = [self.analyzer headingLevelForFontSize:18.0];
    
    XCTAssertEqual(mostFrequentLevel, 0, @"Most frequent font should be body text");
    // The second most frequent could be body or heading depending on algorithm
    XCTAssertTrue(infrequentLevel > 0, @"Infrequent large font should be a heading");
}

#pragma mark - Heading Level Limits Tests

- (void)testMaximumHeadingLevels {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"12.0"] = @100;  // Body
    
    // Add many different heading sizes
    for (int i = 1; i <= 10; i++) {
        fontSizes[[NSString stringWithFormat:@"%.1f", 12.0 + i * 2]] = @(10 - i);
    }
    
    [self.analyzer analyzeFontSizes:fontSizes];
    
    // Check that we don't exceed H6 (level 6)
    NSInteger maxLevel = 0;
    for (NSString *sizeStr in fontSizes.allKeys) {
        CGFloat size = [sizeStr floatValue];
        NSInteger level = [self.analyzer headingLevelForFontSize:size];
        if (level > maxLevel) {
            maxLevel = level;
        }
    }
    
    XCTAssertLessThanOrEqual(maxLevel, 6, @"Should not exceed H6 (level 6)");
}

#pragma mark - Performance Tests

- (void)testLargeFontSetPerformance {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    
    // Create a large set of font sizes to test performance
    for (int i = 8; i <= 72; i++) {
        fontSizes[[NSString stringWithFormat:@"%.1f", (CGFloat)i]] = @(arc4random() % 100 + 1);
    }
    
    NSDate *startTime = [NSDate date];
    [self.analyzer analyzeFontSizes:fontSizes];
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
    
    XCTAssertLessThan(elapsed, 1.0, @"Font analysis should complete within 1 second for large font set");
}

#pragma mark - Algorithm Consistency Tests

- (void)testConsistentResults {
    NSMutableDictionary *fontSizes = [NSMutableDictionary dictionary];
    fontSizes[@"12.0"] = @100;
    fontSizes[@"16.0"] = @10;
    fontSizes[@"20.0"] = @5;
    
    // Run analysis multiple times
    [self.analyzer analyzeFontSizes:fontSizes];
    NSInteger firstRun16 = [self.analyzer headingLevelForFontSize:16.0];
    NSInteger firstRun20 = [self.analyzer headingLevelForFontSize:20.0];
    
    [self.analyzer analyzeFontSizes:fontSizes];
    NSInteger secondRun16 = [self.analyzer headingLevelForFontSize:16.0];
    NSInteger secondRun20 = [self.analyzer headingLevelForFontSize:20.0];
    
    XCTAssertEqual(firstRun16, secondRun16, @"Font analysis should be consistent across runs");
    XCTAssertEqual(firstRun20, secondRun20, @"Font analysis should be consistent across runs");
}

@end