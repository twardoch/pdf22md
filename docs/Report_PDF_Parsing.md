# Mastering PDF Parsing with Swift on macOS – PDFKit and CoreGraphics

Welcome to *Mastering PDF Parsing with Swift on macOS*. This guide focuses on command-line workflows for reading and parsing PDF files using **PDFKit** and **CoreGraphics**. We'll explore how to extract text and images (especially embedded raster images) from PDFs, compare approaches using PDFKit vs CoreGraphics, and cover best practices for performance, memory management, and error handling.

Throughout this book, you'll find step-by-step explanations, sample code snippets, and practical use cases to help you build CLI tools for PDF processing.

## Chapter 1: Overview of PDFKit and CoreGraphics

**PDFKit** is Apple's high-level PDF framework introduced on iOS 11 and long available on macOS. It's built on top of CoreGraphics and provides object-oriented classes like `PDFDocument` and `PDFPage` to simplify common tasks. `PDFDocument` allows loading a PDF from file or URL and offers methods for reading text, searching content, and managing pages. PDFKit serves as a modern API for PDF operations without needing to deal with low-level PDF internals.

**CoreGraphics** is a lower-level 2D graphics framework (often called Quartz on macOS) that includes PDF support. APIs like `CGPDFDocument` and `CGPDFPage` give you direct access to the PDF file's structure. This means you can parse content streams and extract elements such as text runs or images by interacting with dictionaries and streams inside the PDF. CoreGraphics offers fine-grained control but requires understanding the PDF format (e.g., the internal **"Resources → XObject"** hierarchy for images) and writing more code to traverse PDF objects.

**Summary:** PDFKit provides a convenient high-level interface ideal for most text extraction and page-level operations, while CoreGraphics offers low-level access useful for advanced tasks like extracting embedded images. We'll leverage both APIs, playing to their strengths for various PDF parsing needs.

## Chapter 2: Setting Up Swift for macOS Command-Line Tools

Before coding, set up your development environment for a Swift-based CLI tool on macOS. You have two options:

* **Using Xcode:** Xcode includes a template for Command Line Tool projects. Open Xcode, choose *File → New Project*, select **Command Line Tool**, then choose Swift as the language. Xcode creates a `main.swift` file for you.

* **Using Swift Package Manager (SwiftPM):** Create an executable Swift package via Terminal with `swift package init --type executable`. This generates a Swift package with a Sources folder containing a `main.swift`. You can open this package in Xcode or build/run it with SwiftPM commands. Ensure you have the macOS SDK available (by installing Xcode or Command Line Tools).

Regardless of method, make sure you have Apple's Command Line Tools or Xcode installed, as they provide the Swift compiler and necessary SDKs.

**Command-Line Input:** Our PDF parsing tool needs to accept file paths or other parameters. Swift's `CommandLine` API makes it easy to retrieve arguments. The first argument (`CommandLine.arguments[0]`) is the program's name, subsequent entries are user arguments. For instance, if a user runs `./pdfparser input.pdf`, then `CommandLine.arguments[1]` is `"input.pdf"`. Handle cases where required arguments are missing and provide usage instructions:

```swift
import Foundation
import PDFKit

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Usage: \(args[0]) <PDF-file-path>")
    exit(1)
}
let pdfPath = args[1]
let fileURL = URL(fileURLWithPath: pdfPath)

guard let pdfDoc = PDFDocument(url: fileURL) else {
    print("Error: Could not open PDF at path \(pdfPath)")
    exit(1)
}
print("Opened PDF '\(pdfPath)' with \(pdfDoc.pageCount) pages.")
```

In the above code, we import **PDFKit** and use `PDFDocument(url:)` to load the PDF file. We also import **Foundation** because we use `URL` and other utilities. With our CLI tool set up and able to open a PDF, we're ready to explore reading content.

*(Note: When compiling Swift code that uses PDFKit, you might not need special linker flags if using Xcode. In pure command-line compilation, add `-framework PDFKit`, but Xcode or SwiftPM usually handle this automatically when importing PDFKit, since it's an Apple system framework.)*

## Chapter 3: Reading PDFs with PDFKit

PDFKit makes reading PDF files straightforward – it abstracts away file format details and lets you work with familiar objects. The central class is `PDFDocument`, representing a PDF file's contents. Create a `PDFDocument` by providing a file URL or `Data` object. Once you have an instance, you can query it for information and get `PDFPage` objects for page-specific content.

Let's walk through basic PDF reading operations:

* **Opening a PDF:** We saw `PDFDocument(url: fileURL)` above. This initializer returns an optional `PDFDocument?` – it's `nil` if the file can't be opened. Check for nil and handle errors appropriately:

  ```swift
  if let pdfDoc = PDFDocument(url: fileURL) {
      print("PDF opened. Pages: \(pdfDoc.pageCount)")
  } else {
      print("Failed to open PDF.")
  }
  ```

  A `PDFDocument` can also be created from `Data`, but file URL is most common in CLI contexts.

* **Basic Document Info:** Once open, get information like page count with the `pageCount` property. You can also access metadata if needed (`pdfDoc.documentAttributes` contains title/author info), but for parsing, pages are key.

* **Accessing Pages:** Use `pdfDoc.page(at: index)` to get a `PDFPage` object. **Note:** PDFKit uses zero-based indexing. So `page(at: 0)` gives the first page, while `pageCount` is 1-based (if `pageCount == 10`, the last page is index 9). Always ensure the index is within bounds:

  ```swift
  if let firstPage = pdfDoc.page(at: 0) {
      let size = firstPage.bounds(for: .mediaBox).size
      print("First page size: \(size.width)x\(size.height) points")
  }
  ```

  Here we used `bounds(for: .mediaBox)` to get page dimensions. PDF pages define several boxes (media, crop, bleed, etc.), and `.mediaBox` is the full page size.

* **Encrypted PDFs:** PDF documents can be password-protected. Check `pdfDoc.isEncrypted` to see if the PDF requires a password, then call `pdfDoc.unlock(withPassword: "password")` with the correct password. You can also query `pdfDoc.isLocked` before and after unlocking. Handle encrypted PDFs in your CLI tool (perhaps by prompting the user for a password):

  ```swift
  if pdfDoc.isEncrypted && !pdfDoc.isUnlocked {
      // prompt for password or handle accordingly
  }
  ```

At this point, you should be comfortable opening a PDF and iterating through its pages with PDFKit. Next, we'll leverage this to extract text.

## Chapter 4: Extracting Text from PDFs

Extracting text is one of the most common PDF parsing tasks. PDFKit shines here with simple APIs, though there are important nuances to be aware of.

### 4.1 Text Extraction with PDFKit

PDFKit provides high-level interfaces for text retrieval:

* **Whole-document text:** `PDFDocument` has a `string` property that returns all text as a single string:

  ```swift
  if let allText = pdfDoc.string {
      print("Document text: \n\(allText)")
  }
  ```

  This concatenates text from all pages. Be cautious with very large PDFs – it allocates one giant string.

* **Per-page text:** Each `PDFPage` has a `string` property returning that page's text. Iterate through pages to gather text incrementally:

  ```swift
  for i in 0..<pdfDoc.pageCount {
      guard let page = pdfDoc.page(at: i) else { continue }
      let text = page.string ?? ""
      print("Page \(i+1): \(text.prefix(100))...")
  }
  ```

* **Preserving text attributes:** Use `PDFPage.attributedString` if you need style information (fonts, bold/italic, etc.). This returns an `NSAttributedString` containing text plus attributes. For plain text extraction, `string` usually suffices.

* **Searching within text:** PDFKit supports search via `PDFDocument.findString(_:)` which returns `PDFSelection` results. Use `selection?.string` to get context or `selection?.pages` to see locations.

* **Selections by coordinates:** Extract text by coordinates with `PDFPage.selection(for: CGRect)` or related methods. This requires understanding PDF coordinate systems.

**Example – Dumping all text:**

```swift
import PDFKit
var fullText = ""
for pageIndex in 0..<pdfDoc.pageCount {
    if let page = pdfDoc.page(at: pageIndex), let pageText = page.string {
        fullText += pageText + "\n"
    }
}
print(fullText)
```

#### Text Extraction Caveats

While PDFKit makes text extraction easy, output may not always appear in expected reading order. PDFs store text placement instructions rather than linear content, so extracted text might be jumbled. For example, multi-column PDFs might return text column by column rather than in reading order.

Additionally, scanned PDFs (image-only) will return empty text because there's no actual text layer. In those cases, you'd need OCR – beyond PDFKit's scope.

Finally, text extraction may include hidden characters or artifacts (hyphenation, ligatures as separate characters). PDFKit's output is usually fine, but perfect reconstruction might require post-processing.

Despite these caveats, PDFKit covers most scenarios where you want to programmatically extract text with minimal effort.

### 4.2 Text Extraction with CoreGraphics

CoreGraphics provides `CGPDFContentStream` and `CGPDFScanner` to parse PDF content streams. This requires defining callbacks for text operators (`Tj`, `TJ`) and handling font encoding. It's possible but complex – you'd need to interpret PDF drawing operators and reconstruct strings.

PDFKit essentially does this work internally and gives you results in one call. For nearly all applications, leveraging PDFKit is the smart choice.

## Chapter 5: Extracting Images from PDFs

Images embedded in PDFs require CoreGraphics – PDFKit offers no simple one-call solution. We'll navigate the PDF's structure to extract embedded images.

### 5.1 Understanding Embedded Images vs. Rendered Graphics

A PDF can contain images placed by the creator (stored as image XObjects) or vector graphics that look like images but aren't extractable as image files. Only actual image XObject streams can be extracted directly.

### 5.2 Extracting Images with CoreGraphics

Here's the approach to extract images from a PDF page:

1. **Open the PDF with CGPDFDocument:**

   ```swift
   guard let cgDoc = CGPDFDocument(fileURL as CFURL) else {
       // handle error
   }
   ```

2. **Get the desired page:** PDF pages in CGPDFDocument are 1-indexed:

   ```swift
   let pageNumber = 1
   guard let cgPage = cgDoc.page(at: pageNumber) else { ... }
   ```

3. **Get the page's dictionary:**

   ```swift
   guard let pageDict = cgPage.dictionary else { ... }
   ```

4. **Get the Resources dictionary:**

   ```swift
   var resDict: CGPDFDictionaryRef? = nil
   CGPDFDictionaryGetDictionary(pageDict, "Resources", &resDict)
   guard let resources = resDict else { ... }
   ```

5. **Get the XObject dictionary:**

   ```swift
   var xObjDict: CGPDFDictionaryRef? = nil
   CGPDFDictionaryGetDictionary(resources, "XObject", &xObjDict)
   guard let xObject = xObjDict else { ... }
   ```

6. **Iterate over XObject entries and filter images:**

   ```swift
   CGPDFDictionaryApplyBlock(xObject) { key, object, _ in
       var streamRef: CGPDFStreamRef? = nil
       if CGPDFObjectGetValue(object, .stream, &streamRef), 
          let stream = streamRef {
           if let streamDict = CGPDFStreamGetDictionary(stream) {
               var subtypeName: UnsafePointer<Int8>? = nil
               CGPDFDictionaryGetName(streamDict, "Subtype", &subtypeName)
               if subtypeName != nil && String(cString: subtypeName!) == "Image" {
                   // We found an image XObject
               }
           }
       }
       return true
   }
   ```

7. **Extract image data from the stream:**

   ```swift
   var format: CGPDFDataFormat = .raw
   if let dataRef = CGPDFStreamCopyData(stream, &format) {
       let imageData = dataRef as Data
       // Now `imageData` holds the bytes
   }
   ```

8. **Convert or save the image data:**

   ```swift
   try? imageData.write(to: URL(fileURLWithPath: "outputImage.jpg"))
   ```

Complete example for page 1:

```swift
import PDFKit
import CoreGraphics

func extractImages(from pdfPath: String) {
    guard let doc = CGPDFDocument(URL(fileURLWithPath: pdfPath) as CFURL) else {
        print("Unable to open PDF.")
        return
    }
    guard let page = doc.page(at: 1) else {
        print("No such page.")
        return
    }
    guard let pageDict = page.dictionary else {
        print("No page dictionary.")
        return
    }
    var resDict: CGPDFDictionaryRef? = nil
    guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resDict), let resources = resDict else {
        print("No resources on page.")
        return
    }
    var xObjDict: CGPDFDictionaryRef? = nil
    guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjDict), let xObject = xObjDict else {
        print("No XObject on page.")
        return
    }
    
    CGPDFDictionaryApplyBlock(xObject) { keyPtr, object, _ in
        var streamRef: CGPDFStreamRef? = nil
        if CGPDFObjectGetValue(object, .stream, &streamRef), let stream = streamRef {
            if let streamDict = CGPDFStreamGetDictionary(stream) {
                var subtypePtr: UnsafePointer<Int8>? = nil
                CGPDFDictionaryGetName(streamDict, "Subtype", &subtypePtr)
                if let subtype = subtypePtr, String(cString: subtype) == "Image" {
                    var format = CGPDFDataFormat.raw
                    if let cfData = CGPDFStreamCopyData(stream, &format) {
                        let data = cfData as Data
                        let name = String(cString: keyPtr)
                        print("Extracted image \(name), \(data.count) bytes, format \(format)")
                        let fileExt = (format == .jpegEncoded ? "jpg" : (format == .JPEG2000 ? "jp2" : "bin"))
                        let outURL = URL(fileURLWithPath: "\(name).\(fileExt)")
                        try? data.write(to: outURL)
                    }
                }
            }
        }
        return true
    }
}
```

### 5.3 Extracting Images with PDFKit

PDFKit doesn't have an explicit API for listing images. However, you can get a `PDFPage`'s `pageRef` (which is `CGPDFPage`) and reuse the CoreGraphics approach.

### 5.4 Example Use-Case: Saving PDF Images to Disk

A CLI tool could loop through pages, find all image XObjects, retrieve data, determine format, and save each image with names like `<PDFName>_page_<n>_image_<m>.jpg`.

### 5.5 Handling Edge Cases

* **No images on a page:** XObject dictionary might be empty or nonexistent
* **Multiple images:** Code catches them all via apply block
* **Image format issues:** Raw format files might not be directly viewable
* **Performance:** Be mindful of memory usage with image-heavy PDFs

## Chapter 6: PDFKit vs CoreGraphics – Choosing the Right Tool

**Ease of Use:** PDFKit is far easier for text operations. CoreGraphics deals with raw references requiring manual checks and conversions.

**Capabilities:** PDFKit covers most common needs but doesn't expose everything (like direct image listing). CoreGraphics exposes PDF objects directly, allowing extraction of content PDFKit doesn't surface.

**Performance:** Both use the same underlying engine. Differences are negligible for extraction tasks.

**Memory Management:** PDFKit relies on Swift's ARC. CoreGraphics functions often return unmanaged objects requiring careful handling.

**Advanced Features:** PDFKit includes high-level features like selection highlighting. CoreGraphics is purely data-focused.

**Compatibility:** PDFKit available on macOS 10.4+ and iOS 11+. CoreGraphics PDF API available on all Apple platforms.

**When to Use What:**

* Use **PDFKit** for:
  * Quick text extraction or searching
  * Basic metadata and page count
  * Page manipulation or annotations
  * Rendering pages to images
  * Any scenario with high-level API support

* Use **CoreGraphics** for:
  * Extracting content PDFKit doesn't surface
  * Fine-grained control over PDF content streams
  * Edge case performance optimization
  * Non-Apple platform compatibility

Often, you'll use both – PDFKit for text and CoreGraphics for images.

## Chapter 7: Best Practices for Performance, Memory Management, and Error Handling

### 7.1 Performance Considerations

* **Process Only What You Need:** Use random access to pages. Don't loop unnecessarily through entire documents.
* **Avoid Repeated Expensive Calls:** Cache results when possible.
* **Use Autorelease Pools:** Wrap iterations in autoreleasepool blocks for long-running loops.
* **Large Data Handling:** Write large data to files promptly rather than accumulating in memory.
* **Leverage PDFKit's Features:** Extract text once and process externally for better performance.

### 7.2 Memory Management

* **Release PDFs When Done:** Set references to nil when finished.
* **Beware of Large Object Lifetimes:** Process one PDF at a time to avoid memory spikes.
* **CoreGraphics Streams:** Handle CFData carefully – write to file promptly.
* **No Modify in Place:** CoreGraphics is read-only. PDFKit modifications create new structures.

### 7.3 Error Handling and Edge Cases

* **Graceful Handling of Bad PDFs:** Code defensively with guards/ifs.
* **Encrypted PDFs:** Detect encryption and handle password prompts.
* **Unicode and Encoding:** PDFKit usually handles encoding properly.
* **Image Color Spaces:** Handle non-standard color spaces appropriately.
* **Logging and Progress:** Provide feedback for long operations.
* **Testing on Various PDFs:** Test with diverse PDF types.
* **Cleanup:** Handle partial outputs on errors.

### 7.4 Example: Complete CLI Tool

A complete CLI tool would:
1. Parse arguments for input PDF, output directory, options
2. Open PDF with PDFDocument and/or CGPDFDocument
3. Extract text incrementally to file or stdout
4. Extract images with meaningful naming
5. Handle errors gracefully
6. Manage memory carefully
7. Flush file handles and exit

Example run:
```
$ pdfparser --text --images input.pdf --output-dir out
```

This produces `out/input.txt` and image files like `out/input_page1_image1.jpg`.

## Conclusion

This tutorial covered harnessing Swift on macOS for command-line PDF parsing, focusing on text and image extraction. You learned about **PDFKit**'s convenient APIs for text extraction and **CoreGraphics** for low-level image parsing. We discussed when to use each approach and provided best practices for efficient, robust PDF CLI tools.

With this knowledge, you can build powerful PDF processing tools. Consider extending to annotations, form data, or PDF creation, or integrate into larger macOS apps.

**Sources:**
* Apple Developer Documentation – PDFKit and CoreGraphics References
* Nutrient Blog – PDF Text Extraction and Image Extraction articles
* Stack Overflow – PDFKit usage Q&A
* smittytone.net – macOS CLI tool best practices
* Tech Holding Blog – iOS PDFKit overview
* PSPDFKit/Nutrient Articles – PDFKit vs advanced PDF SDK features