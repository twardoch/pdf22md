//
//  SimpleConverterTest.m
//  pdf22md-objc
//
//  Simple test without XCTest framework dependency
//

#import <Foundation/Foundation.h>
#import "Core/PDF22MDConverter.h"
#import "Core/PDF22MDConversionOptions.h"
#import "Core/PDF22MDError.h"

// Simple assertion macro for non-XCTest testing
#define ASSERT(condition, message) \
    if (!(condition)) { \
        printf("❌ ASSERT FAILED: %s - %s\n", #condition, message); \
        return 1; \
    } else { \
        printf("✅ ASSERT PASSED: %s\n", #condition); \
    }

int main(int argc, char *argv[]) {
    @autoreleasepool {
        printf("🧪 Running Simple Converter Tests\n");
        printf("==================================\n");
        
        // Test 1: Options initialization
        PDF22MDConversionOptions *options = [[PDF22MDConversionOptions alloc] init];
        ASSERT(options != nil, "Options should initialize successfully");
        ASSERT(options.rasterizationDPI == 144.0, "Default DPI should be 144");
        
        // Test 2: Default options creation
        PDF22MDConversionOptions *defaultOptions = [PDF22MDConversionOptions defaultOptions];
        ASSERT(defaultOptions != nil, "Default options should initialize successfully");
        
        // Test 3: Error handling for nil URL
        PDF22MDConverter *converter = [[PDF22MDConverter alloc] initWithPDFURL:nil];
        ASSERT(converter == nil, "Should return nil for nil URL");
        
        // Test 4: Error handling for non-existent file  
        NSURL *nonExistentURL = [NSURL fileURLWithPath:@"/nonexistent/file.pdf"];
        converter = [[PDF22MDConverter alloc] initWithPDFURL:nonExistentURL];
        ASSERT(converter == nil, "Should return nil for non-existent file");
        
        // Test 5: Error helper methods
        NSError *testError = [PDF22MDErrorHelper invalidPDFError];
        ASSERT(testError != nil, "Error helper should create error");
        ASSERT(testError.localizedDescription != nil, "Error should have localized description");
        ASSERT(testError.localizedDescription.length > 0, "Error description should not be empty");
        
        // Test 6: File not found error
        NSError *fileError = [PDF22MDErrorHelper fileNotFoundErrorWithPath:@"/test/path"];
        ASSERT(fileError != nil, "Should create file not found error");
        ASSERT(fileError.code == PDF22MDErrorFileNotFound, "Should have correct error code");
        
        printf("\n🎉 All simple tests passed!\n");
        return 0;
    }
}