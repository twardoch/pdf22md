//
//  pdf21md-benchmark.m
//  pdf21md Performance Benchmarking Tool
//
//  Comprehensive performance validation and benchmarking for pdf21md
//

#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import "../Core/PDF21MDConverter.h"
#import "../Core/PDF21MDConversionOptions.h"
#import "../Core/PDF21MDError.h"

#ifndef VERSION
#define VERSION "1.0.0"
#endif

// ANSI color codes for output
#define COLOR_RESET   "\033[0m"
#define COLOR_RED     "\033[31m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_BLUE    "\033[34m"
#define COLOR_MAGENTA "\033[35m"
#define COLOR_CYAN    "\033[36m"

typedef struct {
    NSTimeInterval totalTime;
    NSTimeInterval conversionTime;
    NSTimeInterval markdownTime;
    NSTimeInterval assetTime;
    NSUInteger pageCount;
    NSUInteger imageCount;
    NSUInteger fileSize;
    NSUInteger outputSize;
    NSUInteger peakMemory;
    double pagesPerSecond;
    double mbPerSecond;
} BenchmarkResult;

@interface PDF21MDBenchmark : NSObject

@property (nonatomic, strong) NSMutableArray<NSValue *> *results;
@property (nonatomic, strong) NSString *corpusPath;
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, assign) BOOL verbose;
@property (nonatomic, assign) BOOL compareMode;
@property (nonatomic, assign) BOOL memoryProfile;
@property (nonatomic, assign) NSInteger iterations;

- (void)runBenchmarks;
- (void)printResults;
- (void)saveResultsToJSON:(NSString *)path;
- (BenchmarkResult)benchmarkPDF:(NSString *)pdfPath;
- (NSUInteger)getCurrentMemoryUsage;
- (void)compareWithBaseline:(NSString *)baselinePath;

@end

@implementation PDF21MDBenchmark

- (instancetype)init {
    self = [super init];
    if (self) {
        _results = [NSMutableArray array];
        _iterations = 1;
        _verbose = NO;
        _compareMode = NO;
        _memoryProfile = NO;
    }
    return self;
}

- (void)runBenchmarks {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *pdfFiles = nil;
    
    if (self.corpusPath) {
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:self.corpusPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                // Benchmark all PDFs in corpus directory
                NSError *error = nil;
                NSArray *files = [fileManager contentsOfDirectoryAtPath:self.corpusPath error:&error];
                if (error) {
                    fprintf(stderr, "%sError reading corpus directory: %s%s\n", 
                            COLOR_RED, error.localizedDescription.UTF8String, COLOR_RESET);
                    return;
                }
                
                NSPredicate *pdfPredicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.pdf'"];
                pdfFiles = [[files filteredArrayUsingPredicate:pdfPredicate] 
                            sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
                
                printf("%s📊 Benchmarking %lu PDFs from corpus%s\n", 
                       COLOR_CYAN, (unsigned long)pdfFiles.count, COLOR_RESET);
            } else {
                // Single file provided via corpus path
                pdfFiles = @[[self.corpusPath lastPathComponent]];
                self.corpusPath = [self.corpusPath stringByDeletingLastPathComponent];
                if (self.corpusPath.length == 0) {
                    self.corpusPath = @".";
                }
            }
        } else {
            fprintf(stderr, "%sError: Path not found: %s%s\n", 
                    COLOR_RED, self.corpusPath.UTF8String, COLOR_RESET);
            return;
        }
    } else {
        // Single file benchmark
        pdfFiles = @[@"test.pdf"];
    }
    
    printf("%s════════════════════════════════════════════════════════════════%s\n",
           COLOR_BLUE, COLOR_RESET);
    
    for (NSString *pdfFile in pdfFiles) {
        NSString *fullPath = self.corpusPath ? 
            [self.corpusPath stringByAppendingPathComponent:pdfFile] : pdfFile;
        
        if (![fileManager fileExistsAtPath:fullPath]) {
            fprintf(stderr, "%s⚠️  Skipping non-existent file: %s%s\n", 
                    COLOR_YELLOW, fullPath.UTF8String, COLOR_RESET);
            continue;
        }
        
        printf("\n%sBenchmarking: %s%s\n", COLOR_MAGENTA, pdfFile.UTF8String, COLOR_RESET);
        
        // Run multiple iterations for averaging
        BenchmarkResult avgResult = {0};
        NSMutableArray *iterationResults = [NSMutableArray array];
        
        for (NSInteger i = 0; i < self.iterations; i++) {
            if (self.iterations > 1) {
                printf("  Iteration %ld/%ld...\n", (long)(i + 1), (long)self.iterations);
            }
            
            BenchmarkResult result = [self benchmarkPDF:fullPath];
            [iterationResults addObject:[NSValue valueWithBytes:&result 
                                                        objCType:@encode(BenchmarkResult)]];
            
            // Accumulate for averaging
            avgResult.totalTime += result.totalTime;
            avgResult.conversionTime += result.conversionTime;
            avgResult.markdownTime += result.markdownTime;
            avgResult.assetTime += result.assetTime;
            avgResult.pageCount = result.pageCount;
            avgResult.imageCount = result.imageCount;
            avgResult.fileSize = result.fileSize;
            avgResult.outputSize += result.outputSize;
            avgResult.peakMemory = MAX(avgResult.peakMemory, result.peakMemory);
            
            // Cool down between iterations
            if (i < self.iterations - 1) {
                [NSThread sleepForTimeInterval:0.5];
            }
        }
        
        // Calculate averages
        avgResult.totalTime /= self.iterations;
        avgResult.conversionTime /= self.iterations;
        avgResult.markdownTime /= self.iterations;
        avgResult.assetTime /= self.iterations;
        avgResult.outputSize /= self.iterations;
        avgResult.pagesPerSecond = avgResult.pageCount / avgResult.totalTime;
        avgResult.mbPerSecond = (avgResult.fileSize / 1024.0 / 1024.0) / avgResult.totalTime;
        
        [self.results addObject:[NSValue valueWithBytes:&avgResult 
                                              objCType:@encode(BenchmarkResult)]];
        
        // Print immediate results
        [self printResult:avgResult forFile:pdfFile];
    }
    
    printf("%s════════════════════════════════════════════════════════════════%s\n\n",
           COLOR_BLUE, COLOR_RESET);
}

- (BenchmarkResult)benchmarkPDF:(NSString *)pdfPath {
    BenchmarkResult result = {0};
    
    // Get file size
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:pdfPath error:&error];
    result.fileSize = [attrs[NSFileSize] unsignedIntegerValue];
    
    // Memory baseline
    NSUInteger memStart = [self getCurrentMemoryUsage];
    
    // Start total timing
    NSDate *startTime = [NSDate date];
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    
    // Load PDF
    if (self.verbose) {
        printf("  Loading PDF from: %s\n", pdfPath.UTF8String);
    }
    
    NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
    PDF21MDConverter *converter = [[PDF21MDConverter alloc] initWithPDFURL:pdfURL];
    
    if (!converter) {
        fprintf(stderr, "%sError: Failed to load PDF from %s%s\n", COLOR_RED, pdfPath.UTF8String, COLOR_RESET);
        return result;
    }
    
    result.pageCount = converter.document.pageCount;
    
    // Configure options using builder
    PDF21MDConversionOptionsBuilder *builder = [[PDF21MDConversionOptionsBuilder alloc] init];
    if (self.outputPath) {
        NSString *assetDir = [[self.outputPath stringByDeletingLastPathComponent] 
                              stringByAppendingPathComponent:@"benchmark-assets"];
        builder.assetsFolderPath = assetDir;
        builder.extractImages = YES;
    }
    builder.rasterizationDPI = 144.0;
    
    PDF21MDConversionOptions *options = [builder build];
    
    // Conversion timing
    uint64_t convStart = mach_absolute_time();
    __block NSString *markdown = nil;
    __block NSError *convError = nil;
    
    if (self.verbose) {
        printf("  Starting conversion with %lu pages...\n", (unsigned long)result.pageCount);
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [converter convertWithOptions:options completion:^(NSString *output, NSError *error) {
        if (self.verbose) {
            if (error) {
                printf("  Conversion completed with error: %s\n", error.localizedDescription.UTF8String);
            } else {
                printf("  Conversion completed successfully, output length: %lu\n", (unsigned long)output.length);
            }
        }
        markdown = output;
        convError = error;
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Wait with timeout
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);
    if (dispatch_semaphore_wait(semaphore, timeout) != 0) {
        fprintf(stderr, "%sError: Conversion timed out after 30 seconds%s\n", COLOR_RED, COLOR_RESET);
        return result;
    }
    
    uint64_t convEnd = mach_absolute_time();
    
    // Calculate times
    result.conversionTime = (double)(convEnd - convStart) * timebase.numer / timebase.denom / 1e9;
    
    if (convError) {
        fprintf(stderr, "%sConversion error: %s%s\n", 
                COLOR_RED, convError.localizedDescription.UTF8String, COLOR_RESET);
        return result;
    }
    
    // Output size
    result.outputSize = [markdown lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    // Peak memory
    result.peakMemory = [self getCurrentMemoryUsage] - memStart;
    
    // Total time
    result.totalTime = -[startTime timeIntervalSinceNow];
    result.pagesPerSecond = result.pageCount / result.totalTime;
    result.mbPerSecond = (result.fileSize / 1024.0 / 1024.0) / result.totalTime;
    
    // Count images if assets were extracted
    if (options.assetsFolderPath) {
        NSArray *assets = [[NSFileManager defaultManager] 
                           contentsOfDirectoryAtPath:options.assetsFolderPath error:nil];
        result.imageCount = assets.count;
    }
    
    // Save output if requested
    if (self.outputPath && markdown) {
        [markdown writeToFile:self.outputPath 
                   atomically:YES 
                     encoding:NSUTF8StringEncoding 
                        error:nil];
    }
    
    return result;
}

- (void)printResult:(BenchmarkResult)result forFile:(NSString *)filename {
    printf("\n%s📄 %s%s\n", COLOR_GREEN, filename.UTF8String, COLOR_RESET);
    printf("  Pages:        %lu\n", (unsigned long)result.pageCount);
    printf("  File size:    %.2f MB\n", result.fileSize / 1024.0 / 1024.0);
    printf("  Output size:  %.2f KB\n", result.outputSize / 1024.0);
    printf("  Images:       %lu\n", (unsigned long)result.imageCount);
    printf("\n");
    printf("  %s⏱  Performance:%s\n", COLOR_CYAN, COLOR_RESET);
    printf("  Total time:   %.3f seconds\n", result.totalTime);
    printf("  Conversion:   %.3f seconds (%.1f%%)\n", 
           result.conversionTime, (result.conversionTime / result.totalTime) * 100);
    printf("  Pages/sec:    %.1f\n", result.pagesPerSecond);
    printf("  MB/sec:       %.2f\n", result.mbPerSecond);
    
    if (result.peakMemory > 0) {
        printf("\n  %s💾 Memory:%s\n", COLOR_CYAN, COLOR_RESET);
        printf("  Peak usage:   %.1f MB\n", result.peakMemory / 1024.0 / 1024.0);
    }
}

- (NSUInteger)getCurrentMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0;
}

- (void)printResults {
    if (self.results.count == 0) return;
    
    printf("\n%s📊 BENCHMARK SUMMARY%s\n", COLOR_CYAN, COLOR_RESET);
    printf("%s════════════════════════════════════════════════════════════════%s\n",
           COLOR_BLUE, COLOR_RESET);
    
    // Calculate aggregates
    double totalPages = 0;
    double totalTime = 0;
    double totalSize = 0;
    double avgPagesPerSec = 0;
    double avgMBPerSec = 0;
    NSUInteger maxMemory = 0;
    
    for (NSValue *value in self.results) {
        BenchmarkResult result;
        [value getValue:&result];
        
        totalPages += result.pageCount;
        totalTime += result.totalTime;
        totalSize += result.fileSize;
        avgPagesPerSec += result.pagesPerSecond;
        avgMBPerSec += result.mbPerSecond;
        maxMemory = MAX(maxMemory, result.peakMemory);
    }
    
    NSUInteger count = self.results.count;
    avgPagesPerSec /= count;
    avgMBPerSec /= count;
    
    printf("\n%sDocuments processed: %lu%s\n", COLOR_GREEN, (unsigned long)count, COLOR_RESET);
    printf("Total pages:         %.0f\n", totalPages);
    printf("Total size:          %.1f MB\n", totalSize / 1024.0 / 1024.0);
    printf("Total time:          %.2f seconds\n", totalTime);
    printf("\n");
    printf("%sAverage performance:%s\n", COLOR_MAGENTA, COLOR_RESET);
    printf("Pages per second:    %.1f\n", avgPagesPerSec);
    printf("MB per second:       %.2f\n", avgMBPerSec);
    printf("Peak memory usage:   %.1f MB\n", maxMemory / 1024.0 / 1024.0);
    
    // Performance rating
    printf("\n%sPerformance Rating: ", COLOR_YELLOW);
    if (avgPagesPerSec >= 50) {
        printf("⚡️ BLAZINGLY FAST");
    } else if (avgPagesPerSec >= 20) {
        printf("🚀 VERY FAST");
    } else if (avgPagesPerSec >= 10) {
        printf("✅ FAST");
    } else if (avgPagesPerSec >= 5) {
        printf("👍 GOOD");
    } else {
        printf("🐌 NEEDS OPTIMIZATION");
    }
    printf("%s\n\n", COLOR_RESET);
}

- (void)saveResultsToJSON:(NSString *)path {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    output[@"timestamp"] = [NSDate date];
    output[@"version"] = @(VERSION);
    output[@"platform"] = @{
        @"os": [[NSProcessInfo processInfo] operatingSystemVersionString],
        @"processors": @([[NSProcessInfo processInfo] processorCount]),
        @"memory": @([[NSProcessInfo processInfo] physicalMemory])
    };
    
    NSMutableArray *results = [NSMutableArray array];
    for (NSValue *value in self.results) {
        BenchmarkResult result;
        [value getValue:&result];
        
        [results addObject:@{
            @"pageCount": @(result.pageCount),
            @"fileSize": @(result.fileSize),
            @"outputSize": @(result.outputSize),
            @"imageCount": @(result.imageCount),
            @"totalTime": @(result.totalTime),
            @"conversionTime": @(result.conversionTime),
            @"pagesPerSecond": @(result.pagesPerSecond),
            @"mbPerSecond": @(result.mbPerSecond),
            @"peakMemory": @(result.peakMemory)
        }];
    }
    
    output[@"results"] = results;
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:output 
                                                       options:NSJSONWritingPrettyPrinted 
                                                         error:&error];
    if (!error) {
        [jsonData writeToFile:path atomically:YES];
        printf("%sSaved results to: %s%s\n", COLOR_GREEN, path.UTF8String, COLOR_RESET);
    } else {
        fprintf(stderr, "%sError saving results: %s%s\n", 
                COLOR_RED, error.localizedDescription.UTF8String, COLOR_RESET);
    }
}

- (void)compareWithBaseline:(NSString *)baselinePath {
    // Implementation for comparing with baseline results
    printf("%sComparison with baseline not yet implemented%s\n", COLOR_YELLOW, COLOR_RESET);
}

@end

// Main function
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        PDF21MDBenchmark *benchmark = [[PDF21MDBenchmark alloc] init];
        
        // Parse command line arguments
        NSString *corpusPath = nil;
        NSString *outputPath = nil;
        NSString *jsonPath = nil;
        NSString *comparePath = nil;
        
        for (int i = 1; i < argc; i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            
            if ([arg isEqualToString:@"--corpus"] && i + 1 < argc) {
                corpusPath = [NSString stringWithUTF8String:argv[++i]];
                benchmark.corpusPath = corpusPath;
            } else if ([arg isEqualToString:@"--output"] && i + 1 < argc) {
                outputPath = [NSString stringWithUTF8String:argv[++i]];
                benchmark.outputPath = outputPath;
            } else if ([arg isEqualToString:@"--json"] && i + 1 < argc) {
                jsonPath = [NSString stringWithUTF8String:argv[++i]];
            } else if ([arg isEqualToString:@"--compare"] && i + 1 < argc) {
                comparePath = [NSString stringWithUTF8String:argv[++i]];
                benchmark.compareMode = YES;
            } else if ([arg isEqualToString:@"--iterations"] && i + 1 < argc) {
                benchmark.iterations = atoi(argv[++i]);
            } else if ([arg isEqualToString:@"--memory-profile"]) {
                benchmark.memoryProfile = YES;
            } else if ([arg isEqualToString:@"--verbose"]) {
                benchmark.verbose = YES;
            } else if ([arg isEqualToString:@"--help"]) {
                printf("pdf21md-benchmark - Performance benchmarking tool for pdf21md\n\n");
                printf("Usage: pdf21md-benchmark [OPTIONS] [PDF_FILE]\n\n");
                printf("Options:\n");
                printf("  --corpus PATH         Benchmark all PDFs in directory\n");
                printf("  --output PATH         Save converted markdown output\n");
                printf("  --json PATH          Save results to JSON file\n");
                printf("  --compare PATH       Compare with baseline JSON\n");
                printf("  --iterations N       Number of iterations (default: 1)\n");
                printf("  --memory-profile     Enable detailed memory profiling\n");
                printf("  --verbose            Verbose output\n");
                printf("  --help               Show this help\n\n");
                printf("Examples:\n");
                printf("  pdf21md-benchmark test.pdf\n");
                printf("  pdf21md-benchmark --corpus ./test-pdfs/ --json results.json\n");
                printf("  pdf21md-benchmark --compare baseline.json current.json\n");
                return 0;
            } else if (!corpusPath && ![arg hasPrefix:@"-"]) {
                // Argument is the PDF file
                corpusPath = arg;
            }
        }
        
        if (!corpusPath && !comparePath) {
            fprintf(stderr, "Error: Please specify a PDF file or use --corpus\n");
            fprintf(stderr, "Use --help for usage information\n");
            return 1;
        }
        
        // Set corpus path if single file provided
        if (corpusPath && !benchmark.corpusPath) {
            benchmark.corpusPath = corpusPath;
        }
        
        printf("%s🚀 pdf21md Performance Benchmark v%s%s\n", COLOR_CYAN, VERSION, COLOR_RESET);
        printf("%s════════════════════════════════════════════════════════════════%s\n",
               COLOR_BLUE, COLOR_RESET);
        
        if (comparePath) {
            [benchmark compareWithBaseline:comparePath];
        } else {
            [benchmark runBenchmarks];
            [benchmark printResults];
            
            if (jsonPath) {
                [benchmark saveResultsToJSON:jsonPath];
            }
        }
        
        return 0;
    }
}