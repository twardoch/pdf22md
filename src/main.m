#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import "PDFMarkdownConverter.h"

#ifndef VERSION
#define VERSION "dev"
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
        PDFMarkdownConverter *converter = nil;
        
        if (inputPath) {
            // Read from file
            fprintf(stderr, "DEBUG: Loading PDF from file: %s\n", [inputPath UTF8String]);
            NSURL *pdfURL = [NSURL fileURLWithPath:inputPath];
            converter = [[PDFMarkdownConverter alloc] initWithPDFAtURL:pdfURL];
            if (!converter) {
                fprintf(stderr, "Failed to load PDF from: %s\n", [inputPath UTF8String]);
                return 1;
            }
            fprintf(stderr, "DEBUG: PDF loaded successfully\n");
        } else {
            // Read from stdin
            NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
            NSData *pdfData = [stdinHandle readDataToEndOfFile];
            
            if (!pdfData || [pdfData length] == 0) {
                fprintf(stderr, "No PDF data received from stdin\n");
                return 1;
            }
            
            converter = [[PDFMarkdownConverter alloc] initWithPDFData:pdfData];
            if (!converter) {
                fprintf(stderr, "Failed to create PDF document from stdin data\n");
                return 1;
            }
        }
        
        // Perform conversion
        fprintf(stderr, "DEBUG: Starting conversion with assetsPath=%s, dpi=%.1f\n", 
                assetsPath ? [assetsPath UTF8String] : "nil", dpi);
        __block NSString *markdown = nil;
        __block NSError *conversionError = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [converter convertWithAssetsFolderPath:assetsPath
                                rasterizedDPI:dpi
                                   completion:^(NSString *result, NSError *error) {
            fprintf(stderr, "DEBUG: Conversion completed\n");
            markdown = result;
            conversionError = error;
            dispatch_semaphore_signal(semaphore);
        }];
        
        fprintf(stderr, "DEBUG: Waiting for conversion to complete...\n");
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        fprintf(stderr, "DEBUG: Conversion finished\n");
        
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
        }
        
        return 0;
    }
}