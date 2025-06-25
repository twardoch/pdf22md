#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import "../Core/PDF22MDConverter.h"
#import "../Core/PDF22MDConversionOptions.h"

#ifndef VERSION
#define VERSION "1.0.0"
#endif

void printUsage(const char *programName) {
    fprintf(stderr, "Usage: %s [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi] [-v] [-h]\n", programName);
    fprintf(stderr, "  Converts PDF documents to Markdown format\n");
    fprintf(stderr, "  -i <path>: Input PDF file (default: stdin)\n");
    fprintf(stderr, "  -o <path>: Output Markdown file (default: stdout)\n");
    fprintf(stderr, "  -a <path>: Assets folder for extracted images\n");
    fprintf(stderr, "  -d <dpi>: DPI for rasterizing vector graphics (default: 144)\n");
    fprintf(stderr, "  -v: Display version information\n");
    fprintf(stderr, "  -h: Display this help message\n");
}

void printVersion() {
    printf("pdf22md version %s\n", VERSION);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *inputPath = nil;
        NSString *outputPath = nil;
        NSString *assetsPath = nil;
        CGFloat dpi = 144.0;
        
        // Parse command line arguments
        int opt;
        while ((opt = getopt(argc, (char * const *)argv, "i:o:a:d:hvV")) != -1) {
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
        
        // Initialize converter
        PDF22MDConverter *converter = nil;
        
        if (inputPath) {
            // Read from file
            NSURL *pdfURL = [NSURL fileURLWithPath:inputPath];
            converter = [[PDF22MDConverter alloc] initWithPDFURL:pdfURL];
            if (!converter) {
                fprintf(stderr, "Failed to load PDF from: %s\n", [inputPath UTF8String]);
                return 1;
            }
        } else {
            // Read from stdin
            NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
            NSData *pdfData = [stdinHandle readDataToEndOfFile];
            
            if (!pdfData || [pdfData length] == 0) {
                fprintf(stderr, "No PDF data received from stdin\n");
                return 1;
            }
            
            converter = [[PDF22MDConverter alloc] initWithPDFData:pdfData];
            if (!converter) {
                fprintf(stderr, "Failed to create PDF document from stdin data\n");
                return 1;
            }
        }
        
        // Create conversion options
        PDF22MDConversionOptionsBuilder *builder = [[PDF22MDConversionOptionsBuilder alloc] init];
        builder.assetsFolderPath = assetsPath;
        builder.rasterizationDPI = dpi;
        builder.extractImages = (assetsPath != nil);
        
        // Add progress handler for interactive terminals
        if (isatty(STDERR_FILENO)) {
            builder.progressHandler = ^(NSInteger currentPage, NSInteger totalPages) {
                fprintf(stderr, "\rProcessing page %ld of %ld...", (long)currentPage, (long)totalPages);
                fflush(stderr);
            };
        }
        
        PDF22MDConversionOptions *options = [builder build];
        
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
        
        if (isatty(STDERR_FILENO) && options.progressHandler) {
            fprintf(stderr, "\n"); // Clear progress line
        }
        
        if (conversionError) {
            fprintf(stderr, "Conversion failed: %s\n", 
                    [[conversionError localizedDescription] UTF8String]);
            return 1;
        }
        
        // Write output
        if (outputPath) {
            // Write to file
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