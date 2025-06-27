#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import "../Core/PDF21MDConverter.h"
#import "../Core/PDF21MDConversionOptions.h"

#ifndef VERSION
#define VERSION "1.0.0"
#endif

void printUsage(const char *programName) {
    fprintf(stderr, "Usage: %s [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi] [-v] [-h] [--debug]\n", programName);
    fprintf(stderr, "  Converts PDF documents to Markdown format\n");
    fprintf(stderr, "  -i <path>: Input PDF file (default: stdin)\n");
    fprintf(stderr, "  -o <path>: Output Markdown file (default: stdout)\n");
    fprintf(stderr, "  -a <path>: Assets folder for extracted images\n");
    fprintf(stderr, "  -d <dpi>: DPI for rasterizing vector graphics (default: 144)\n");
    fprintf(stderr, "  -v: Display version information\n");
    fprintf(stderr, "  -h: Display this help message\n");
    fprintf(stderr, "  --debug: Enable debug output for troubleshooting\n");
}

void printVersion() {
    printf("pdf21md version %s\n", VERSION);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *inputPath = nil;
        NSString *outputPath = nil;
        NSString *assetsPath = nil;
        CGFloat dpi = 144.0;
        BOOL debugMode = NO;
        
        // Check for --debug flag and filter it out for getopt
        char **filtered_argv = malloc(argc * sizeof(char*));
        int filtered_argc = 0;
        
        for (int i = 0; i < argc; i++) {
            if (strcmp(argv[i], "--debug") == 0) {
                debugMode = YES;
            } else {
                filtered_argv[filtered_argc++] = (char*)argv[i];
            }
        }
        
        // Parse command line arguments
        int opt;
        optind = 1; // Reset getopt
        while ((opt = getopt(filtered_argc, filtered_argv, "i:o:a:d:hvV")) != -1) {
            switch (opt) {
                case 'i':
                    inputPath = [NSString stringWithUTF8String:optarg];
                    break;
                case 'o':
                    outputPath = [NSString stringWithUTF8String:optarg];
                    break;
                case 'a':
                    assetsPath = [NSString stringWithUTF8String:optarg];
                    break;
                case 'd':
                    dpi = atof(optarg);
                    if (dpi <= 0) {
                        fprintf(stderr, "Invalid DPI value: %s\n", optarg);
                        return 1;
                    }
                    break;
                case 'h':
                    printUsage(argv[0]);
                    return 0;
                case 'v':
                case 'V':
                    printVersion();
                    return 0;
                default:
                    printUsage(argv[0]);
                    return 1;
            }
        }
        
        // Free the filtered argv
        free(filtered_argv);
        
        if (debugMode) {
            fprintf(stderr, "[DEBUG] Input path: %s\n", inputPath ? [inputPath UTF8String] : "(stdin)");
            fprintf(stderr, "[DEBUG] Output path: %s\n", outputPath ? [outputPath UTF8String] : "(stdout)");
            fprintf(stderr, "[DEBUG] Assets path: %s\n", assetsPath ? [assetsPath UTF8String] : "(none)");
            fprintf(stderr, "[DEBUG] DPI: %.1f\n", dpi);
        }
        
        // Initialize converter
        PDF21MDConverter *converter = nil;
        
        if (inputPath) {
            // Read from file
            NSURL *pdfURL = [NSURL fileURLWithPath:inputPath];
            if (debugMode) {
                fprintf(stderr, "[DEBUG] Loading PDF from: %s\n", [inputPath UTF8String]);
            }
            converter = [[PDF21MDConverter alloc] initWithPDFURL:pdfURL];
            if (!converter) {
                fprintf(stderr, "Failed to load PDF from: %s\n", [inputPath UTF8String]);
                return 1;
            }
            if (debugMode) {
                fprintf(stderr, "[DEBUG] PDF loaded successfully\n");
            }
        } else {
            // Read from stdin
            NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
            NSData *pdfData = [stdinHandle readDataToEndOfFile];
            
            if (!pdfData || [pdfData length] == 0) {
                fprintf(stderr, "No PDF data received from stdin\n");
                return 1;
            }
            
            converter = [[PDF21MDConverter alloc] initWithPDFData:pdfData];
            if (!converter) {
                fprintf(stderr, "Failed to create PDF document from stdin data\n");
                return 1;
            }
        }
        
        // Create conversion options
        PDF21MDConversionOptionsBuilder *builder = [[PDF21MDConversionOptionsBuilder alloc] init];
        builder.assetsFolderPath = assetsPath;
        builder.rasterizationDPI = dpi;
        builder.extractImages = (assetsPath != nil);
        
        if (debugMode) {
            fprintf(stderr, "[DEBUG] Extract images: %s\n", (assetsPath != nil) ? "YES" : "NO");
        }
        
        // Add progress handler for interactive terminals (or debug mode)
        if (isatty(STDERR_FILENO) || debugMode) {
            builder.progressHandler = ^(NSInteger currentPage, NSInteger totalPages) {
                if (debugMode) {
                    fprintf(stderr, "[DEBUG] Processing page %ld of %ld...\n", (long)currentPage, (long)totalPages);
                } else {
                    fprintf(stderr, "\rProcessing page %ld of %ld...", (long)currentPage, (long)totalPages);
                    fflush(stderr);
                }
            };
        }
        
        PDF21MDConversionOptions *options = [builder build];
        
        if (debugMode) {
            fprintf(stderr, "[DEBUG] Starting conversion...\n");
        }
        
        // Perform conversion
        __block NSString *markdown = nil;
        __block NSError *conversionError = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [converter convertWithOptions:options
                           completion:^(NSString *result, NSError *error) {
            markdown = result;
            conversionError = error;
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Wait for completion
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (isatty(STDERR_FILENO) && options.progressHandler && !debugMode) {
            fprintf(stderr, "\n"); // Clear progress line
        }
        
        if (debugMode) {
            fprintf(stderr, "[DEBUG] Conversion completed\n");
        }
        
        if (conversionError) {
            fprintf(stderr, "Conversion failed: %s\n", 
                    [[conversionError localizedDescription] UTF8String]);
            return 1;
        }
        
        if (debugMode) {
            if (markdown) {
                NSUInteger length = [markdown length];
                NSString *preview = length > 100 ? [markdown substringToIndex:100] : markdown;
                // Replace newlines with literal \n for debug output
                preview = [preview stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
                fprintf(stderr, "[DEBUG] Markdown generated: %lu characters\n", (unsigned long)length);
                fprintf(stderr, "[DEBUG] Markdown preview: %s%s\n", [preview UTF8String], 
                        length > 100 ? "..." : "");
            } else {
                fprintf(stderr, "[DEBUG] ERROR: Markdown is nil!\n");
            }
        }
        
        // Write output
        if (outputPath) {
            // Write to file
            if (debugMode) {
                fprintf(stderr, "[DEBUG] Writing to file: %s\n", [outputPath UTF8String]);
                
                // Check if parent directory exists
                NSString *parentDir = [outputPath stringByDeletingLastPathComponent];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                BOOL isDirectory;
                if ([fileManager fileExistsAtPath:parentDir isDirectory:&isDirectory] && isDirectory) {
                    fprintf(stderr, "[DEBUG] Parent directory exists: %s\n", [parentDir UTF8String]);
                } else {
                    fprintf(stderr, "[DEBUG] WARNING: Parent directory does not exist: %s\n", [parentDir UTF8String]);
                }
                
                // Check if we can write to the directory
                if ([fileManager isWritableFileAtPath:parentDir]) {
                    fprintf(stderr, "[DEBUG] Parent directory is writable\n");
                } else {
                    fprintf(stderr, "[DEBUG] WARNING: Parent directory is not writable\n");
                }
            }
            
            NSError *writeError = nil;
            BOOL success = [markdown writeToFile:outputPath
                                      atomically:YES
                                        encoding:NSUTF8StringEncoding
                                           error:&writeError];
            if (!success) {
                fprintf(stderr, "Failed to write output file: %s\n",
                        [[writeError localizedDescription] UTF8String]);
                return 1;
            }
            
            if (debugMode) {
                fprintf(stderr, "[DEBUG] File write successful\n");
                
                // Verify the file was written
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:outputPath]) {
                    NSDictionary *attributes = [fileManager attributesOfItemAtPath:outputPath error:nil];
                    NSNumber *fileSize = attributes[NSFileSize];
                    fprintf(stderr, "[DEBUG] Output file created, size: %lld bytes\n", [fileSize longLongValue]);
                } else {
                    fprintf(stderr, "[DEBUG] ERROR: Output file was not created!\n");
                }
            }
        } else {
            // Write to stdout
            NSFileHandle *stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
            NSData *markdownData = [markdown dataUsingEncoding:NSUTF8StringEncoding];
            [stdoutHandle writeData:markdownData];
            
            // Add newline if not present
            if (![markdown hasSuffix:@"\n"]) {
                [stdoutHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
        
        return 0;
    }
}