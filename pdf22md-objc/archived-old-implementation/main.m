#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import "PDFMarkdownConverter.h"
#import "PDF22MDErrorHelper.h"

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
            NSURL *pdfURL = [NSURL fileURLWithPath:inputPath];
            converter = [[PDFMarkdownConverter alloc] initWithPDFAtURL:pdfURL];
            if (!converter) {
                NSError *error = [PDF22MDErrorHelper invalidPDFErrorWithPath:inputPath];
                NSString *userMessage = [PDF22MDErrorHelper userFriendlyMessageForError:error];
                fprintf(stderr, "%s\n", [userMessage UTF8String]);
                return 1;
            }
        } else {
            // Read from stdin
            NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
            NSData *pdfData = [stdinHandle readDataToEndOfFile];
            
            if (!pdfData || [pdfData length] == 0) {
                NSError *error = [PDF22MDErrorHelper errorWithCode:PDF22MDErrorIOError
                                                        description:@"No PDF data received from stdin"
                                                         suggestion:@"• Pipe a valid PDF file to stdin\n"
                                                                   @"• Example: cat document.pdf | pdf22md > output.md\n"
                                                                   @"• Check that the input source contains PDF data"];
                NSString *userMessage = [PDF22MDErrorHelper userFriendlyMessageForError:error];
                fprintf(stderr, "%s\n", [userMessage UTF8String]);
                return 1;
            }
            
            converter = [[PDFMarkdownConverter alloc] initWithPDFData:pdfData];
            if (!converter) {
                NSError *error = [PDF22MDErrorHelper errorWithCode:PDF22MDErrorInvalidPDF
                                                        description:@"Failed to create PDF document from stdin data"
                                                         suggestion:@"• Ensure the piped data is a valid PDF file\n"
                                                                   @"• Verify the PDF is not corrupted\n"
                                                                   @"• Check if the PDF is password-protected"];
                NSString *userMessage = [PDF22MDErrorHelper userFriendlyMessageForError:error];
                fprintf(stderr, "%s\n", [userMessage UTF8String]);
                return 1;
            }
        }
        
        // Perform conversion
        __block NSString *markdown = nil;
        __block NSError *conversionError = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [converter convertWithAssetsFolderPath:assetsPath
                                rasterizedDPI:dpi
                                   completion:^(NSString *result, NSError *error) {
            markdown = result;
            conversionError = error;
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (conversionError) {
            NSString *userMessage = [PDF22MDErrorHelper userFriendlyMessageForError:conversionError];
            fprintf(stderr, "%s\n", [userMessage UTF8String]);
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
                NSError *enhancedError = [PDF22MDErrorHelper ioErrorWithPath:outputPath operation:@"write"];
                if (writeError) {
                    enhancedError = [PDF22MDErrorHelper errorWithCode:PDF22MDErrorIOError
                                                           description:[NSString stringWithFormat:@"Failed to write output file: %@", outputPath]
                                                            suggestion:@"• Check if you have write permissions for the directory\n"
                                                                      @"• Ensure sufficient disk space\n"
                                                                      @"• Verify the path is correct and accessible\n"
                                                                      @"• Check if the file is locked by another application"
                                                       underlyingError:writeError];
                }
                NSString *userMessage = [PDF22MDErrorHelper userFriendlyMessageForError:enhancedError];
                fprintf(stderr, "%s\n", [userMessage UTF8String]);
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