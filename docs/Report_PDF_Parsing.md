Thanks! I’ll put together a comprehensive Markdown-format tutorial book for beginner Swift developers on macOS, focused on using `CoreGraphics` and `PDFKit` to read and parse PDFs—exporting them as text and images via mostly CLI-based workflows. I’ll dive deep into the reading and parsing aspects rather than creation.

I’ll get started and update you as soon as the draft is ready.


# Mastering PDF Parsing with Swift on macOS – PDFKit and CoreGraphics

Welcome to *Mastering PDF Parsing with Swift on macOS*, a comprehensive tutorial book for beginner Swift developers. This guide focuses on command-line workflows (no GUI required) for reading and parsing PDF files on macOS using **PDFKit** and **CoreGraphics**. We will explore how to extract text and images (especially embedded raster images) from PDFs, compare approaches using PDFKit vs CoreGraphics, and cover best practices for performance, memory management, and error handling.

Throughout this book, you’ll find step-by-step explanations, sample code snippets, and practical use cases to help you confidently build CLI tools for PDF processing. Let’s dive in!

## Chapter 1: Overview of PDFKit and CoreGraphics

**PDFKit** is Apple’s high-level PDF framework introduced on iOS 11 (and long available on macOS) for viewing and manipulating PDF documents. It is built on top of CoreGraphics. PDFKit provides object-oriented classes like `PDFDocument` (representing an entire PDF file) and `PDFPage` (representing a page) to simplify common tasks. For example, `PDFDocument` allows loading a PDF from file or URL and offers methods for reading text, searching content, and managing pages. In short, PDFKit serves as a modern, easy-to-use API for PDF operations without needing to deal with low-level PDF internals.

**CoreGraphics**, on the other hand, is a lower-level 2D graphics framework (often referred to as Quartz on macOS) that includes PDF support. CoreGraphics APIs like `CGPDFDocument`, `CGPDFPage`, and related functions give you direct access to the PDF file’s structure. This means you can parse the PDF content streams and extract elements such as text runs or images by interacting with dictionaries and streams inside the PDF. CoreGraphics offers fine-grained control and can accomplish tasks PDFKit doesn’t directly expose – but the trade-off is complexity. Using CoreGraphics for PDF parsing requires understanding the PDF format (e.g., the internal **“Resources → XObject”** hierarchy for images) and writing more code to traverse and interpret PDF objects.

**In summary:** PDFKit provides a convenient, high-level interface (backed by CoreGraphics under the hood) that is ideal for most text extraction and page-level operations, whereas CoreGraphics offers a low-level route to the PDF’s guts, useful for advanced tasks like extracting embedded images or custom parsing logic. We’ll leverage both of these APIs in this book, playing to their strengths for various PDF parsing needs.

## Chapter 2: Setting Up Swift for macOS Command-Line Tools

Before we start coding, let’s set up our development environment for a Swift-based CLI tool on macOS. You have a couple of options to create a command-line Swift program:

* **Using Xcode:** Xcode includes a template for Command Line Tool projects. Simply open Xcode, choose *File → New Project*, and select **Command Line Tool**, then choose Swift as the language. Xcode will create a `main.swift` file for you, and you can add additional Swift files as needed. This is a straightforward way to get started with a CLI project in Swift.

* **Using Swift Package Manager (SwiftPM):** You can create an executable Swift package via Terminal. For example, run `swift package init --type executable` in a new directory. This generates a Swift package with a Sources folder containing a `main.swift`. You can open this package in Xcode or build/run it with SwiftPM commands. If you go this route and plan to use PDFKit, ensure you have the macOS SDK available (by installing Xcode or at least the Command Line Tools). PDFKit is included as a system framework on macOS, so no extra library installation is needed – you just need to import it in your code.

Regardless of method, make sure you have Apple’s Command Line Tools or Xcode installed, as they provide the Swift compiler and necessary SDKs. For the examples in this book, we’ll assume you’re either using Xcode’s Command Line Tool template or a SwiftPM executable package.

**Command-Line Input:** Our PDF parsing tool will likely need to accept file paths or other parameters. Swift’s `CommandLine` API makes it easy to retrieve command-line arguments. The first argument (`CommandLine.arguments[0]`) is the program’s name, and subsequent entries are the arguments passed by the user. For instance, if a user runs `./pdfparser input.pdf`, then `CommandLine.arguments[1]` would be `"input.pdf"`. We should handle cases where required arguments are missing and provide usage instructions. Here’s a snippet demonstrating basic argument handling in `main.swift`:

```swift
import Foundation
import PDFKit  // PDFKit is part of macOS frameworks

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Usage: \(args[0]) <PDF-file-path>")
    exit(1)
}
let pdfPath = args[1]
let fileURL = URL(fileURLWithPath: pdfPath)

// Attempt to open the PDF document
guard let pdfDoc = PDFDocument(url: fileURL) else {
    print("Error: Could not open PDF at path \(pdfPath)")
    exit(1)
}
print("Opened PDF '\(pdfPath)' with \(pdfDoc.pageCount) pages.")
```

In the above code, we import **PDFKit** and use `PDFDocument(url:)` to load the PDF file from the given path. We’ll discuss PDFKit usage in detail in the next chapter. We also import **Foundation** because we use `URL` and other basic utilities. With our CLI tool set up and able to open a PDF, we’re ready to explore reading content.

*(Note: When compiling Swift code that uses PDFKit, you might not need any special linker flags if using Xcode. In a pure command-line compile, you may need to link against PDFKit by adding `-framework PDFKit`, but Xcode or SwiftPM usually handle this automatically when you import PDFKit, since it’s an Apple system framework.)*

## Chapter 3: Reading PDFs with PDFKit

PDFKit makes reading PDF files extremely straightforward – it abstracts away the file format details and lets you work with familiar objects. The central class is `PDFDocument`, which represents a PDF file’s contents. You can create a `PDFDocument` by providing a file URL or `Data` object for an existing PDF. Once you have a `PDFDocument` instance, you can query it for various information and get `PDFPage` objects to delve into page-specific content.

Let’s walk through basic PDF reading operations using PDFKit:

* **Opening a PDF:** We saw a glimpse above with `PDFDocument(url: fileURL)`. This initializer will return an optional `PDFDocument?` – it will be `nil` if the file can’t be opened (e.g., if the path is wrong or the file is not a valid PDF). Always check for nil and handle errors appropriately. On success, you have a `PDFDocument` object to work with. For example:

  ```swift
  if let pdfDoc = PDFDocument(url: fileURL) {
      print("PDF opened. Pages: \(pdfDoc.pageCount)")
  } else {
      print("Failed to open PDF.")
  }
  ```

  A `PDFDocument` can also be created from `Data` (e.g., if you downloaded a PDF from the internet), but in a CLI context, file URL is most common. According to Apple’s docs, `PDFDocument` represents PDF data and provides methods for writing, searching, and selecting PDF content. Essentially, it loads the PDF file and manages access to its pages and contents.

* **Basic Document Info:** Once open, you can get information like the number of pages with the `pageCount` property. You can also access metadata if needed (e.g., `pdfDoc.documentAttributes` might contain title/author info), but for parsing content, the key property is pages.

* **Accessing Pages:** Use `pdfDoc.page(at: index)` to get a `PDFPage` object for a given page index. **Note:** PDFKit uses zero-based indexing for pages. So, `page(at: 0)` gives the first page, while `pageCount` is a 1-based count of total pages (e.g., if `pageCount == 10`, the last page is index 9). Always ensure the index is within bounds. A `PDFPage` lets you inspect that page’s content, including text, graphics, and annotations (for our needs, mainly text extraction). For example:

  ```swift
  if let firstPage = pdfDoc.page(at: 0) {
      let size = firstPage.bounds(for: .mediaBox).size
      print("First page size: \(size.width)x\(size.height) points")
  }
  ```

  Here we used `bounds(for: .mediaBox)` to get the page dimensions. PDF pages define several boxes (media, crop, bleed, etc.), and `.mediaBox` is the full page size. This might be useful if, say, you want to understand page layout or coordinate space for advanced text extraction (PDFKit coordinates are in page points with origin at bottom-left by default).

* **Encrypted PDFs:** PDF documents can be password-protected. If `PDFDocument(url:)` opens an encrypted PDF, it might succeed but mark the document locked, or it might fail to open depending on the PDFKit version. You should check `pdfDoc.isEncrypted` to see if the PDF requires a password, and if so, call `pdfDoc.unlock(withPassword: "password")` with the correct password to decrypt it. You can also query `pdfDoc.isLocked` before and after unlocking. Always handle the case of an encrypted PDF in your CLI tool (perhaps by prompting the user for a password or by reading from input securely). With CoreGraphics, a similar concept exists (you’d use `CGPDFDocumentUnlockWithPassword`), but with PDFKit it’s nicely wrapped in the `unlock` method.

* **Navigation and Outline:** PDFKit also supports document navigation features such as outlines (table of contents) via `PDFOutline`, and page labels (some PDFs have logical page names or numbers via `page.label`). While these are important for a full PDF reader, our focus here is on content extraction, so we won’t dive deeply into outlines or user navigation. We will, however, use page indices and counts to loop through content when needed.

At this point, you should be comfortable opening a PDF and iterating through its pages with PDFKit. Next, we’ll leverage this to extract text from the pages, which is a primary goal of PDF parsing.

## Chapter 4: Extracting Text from PDFs

Extracting text is one of the most common PDF parsing tasks. PDFKit shines here with simple APIs to get the textual content of a document or page. However, there are important nuances and limitations to be aware of, which we’ll discuss. We’ll also contrast this with how one *would* extract text using CoreGraphics (though that low-level approach is generally more complex and rarely needed thanks to PDFKit).

### 4.1 Text Extraction with PDFKit

PDFKit provides a high-level interface to retrieve text:

* **Whole-document text:** Easiest of all, `PDFDocument` has a property `string` (of type `String?`) that returns *all* the text in the PDF document as a single string. This is very convenient if you just need the raw text content without layout. For example:

  ```swift
  if let allText = pdfDoc.string {
      print("Document text: \n\(allText)")
  }
  ```

  Under the hood, this likely concatenates text from all pages. Using `pdfDoc.string` can be done in one line, but be cautious with very large PDFs (it will allocate one giant string). For moderately sized documents, this is fine.

* **Per-page text:** Each `PDFPage` has a `string` property as well, returning the text on that page. You can iterate through pages and gather text page by page. This is useful if you need to preserve some page-wise structure or insert page breaks markers in output. It’s also helpful if you want to process pages incrementally (e.g., stream out text one page at a time). Example:

  ```swift
  for i in 0..<pdfDoc.pageCount {
      guard let page = pdfDoc.page(at: i) else { continue }
      let text = page.string ?? ""
      print("Page \(i+1): \(text.prefix(100))...")  // print first 100 chars for demo
  }
  ```

  This will retrieve each page’s text separately. The `?? ""` ensures we don’t attempt to print `nil` if a page had no text.

* **Preserving text attributes:** If you need not just the plain text but also style information (fonts, bold/italic, etc.), use `PDFPage.attributedString` property. This returns an `NSAttributedString` containing the page’s text plus attributes like font, color, etc. For example, if you wanted to find bold text or specific font usage, the attributed string would be the place to look. You could iterate through its attributes to identify those spans. In most cases, though, plain text (`string`) suffices for parsing content.

* **Searching within text:** PDFKit supports search via the `PDFDocument.findString(_:)` method which returns an array of `PDFSelection` results. A `PDFSelection` in PDFKit represents a selection of text (potentially spanning pages). We won’t heavily cover search, but be aware you can search for keywords and get selections, then use `selection?.string` to get the context or `selection?.pages` to see where it occurs. This can be handy if your tool is meant to find certain terms in PDFs.

* **Selections by coordinates:** PDFKit can also extract text by coordinates. For instance, if you know a rectangle area on the page (in PDF coordinates) that you want the text from, you can use `PDFPage.selection(for: CGRect)` or related methods (`selectionForRange`, etc.) to get a `PDFSelection`. This is advanced usage (for cases like extracting text in specific table cells or regions) and requires understanding PDF coordinate systems. It’s beyond our current scope, but it’s good to know these APIs exist for more granular control.

**Example – Dumping all text:** Putting it together, here’s how we might extract all text from a PDF in a CLI tool and output it:

```swift
import PDFKit
// ... assume pdfDoc is already a PDFDocument
var fullText = ""
for pageIndex in 0..<pdfDoc.pageCount {
    if let page = pdfDoc.page(at: pageIndex), let pageText = page.string {
        fullText += pageText + "\n"
    }
}
print(fullText)
```

This loop accumulates text from each page and prints it (adding a newline between pages for separation). In practice, you might write the text to a file rather than print to console if the content is large.

#### Text Extraction Caveats

While PDFKit makes it *easy* to get text, the output may not always appear in the reading order you expect. PDFs don’t store text in a linear, paragraph-by-paragraph fashion – they store instructions for placing text on the page at coordinates. The consequence is that extracted text might be *“jumbled”* or out of logical order in some cases. For example, if a PDF has multiple columns, PDFKit might return text column by column or in an order that doesn’t correspond to how you’d read it. If the PDF content stream intermixes text from different parts of the page, the plain text extraction will reflect that order. As one developer noted, grouping text that is visually in columns or tables into a coherent order is a non-trivial task – it requires higher-level understanding that PDFKit (and even macOS Preview) might not fully have.

Additionally, if a PDF is essentially a scanned image (no real text layer), then `PDFDocument.string` will be empty because there’s no text to extract (the text is just part of an image). In those cases, you’d need OCR to get text, which is beyond PDFKit’s scope.

Finally, consider that text extraction may include hidden characters or artifacts (like hyphenation, ligatures as separate characters, etc.). For most use cases, PDFKit’s output is fine, but if you need perfectly reconstructed content, you might need to post-process the text or use more sophisticated libraries that retain layout.

Despite these caveats, PDFKit covers **the majority of scenarios where you want to programmatically extract text from a PDF with minimal effort**. It spares you from dealing with the PDF content stream and text encoding details, which we’ll see is quite complex if attempted via CoreGraphics.

### 4.2 A Note on Text Extraction with CoreGraphics

For completeness, let’s discuss how one would extract text using CoreGraphics (Quartz) directly, and why you’d typically avoid this in favor of PDFKit:

CoreGraphics provides a type `CGPDFContentStream` and functions like `CGPDFScanner` that can parse PDF page content streams (the raw drawing commands in the PDF). Using these requires you to define callbacks for PDF text showing operators (such as `Tj`, `TJ` which show text in PDF) and accumulate characters. You also have to handle font encoding to Unicode, etc. In short, it’s *possible* to get text by scanning a PDF’s content stream, but **“this requires in-depth knowledge about the structure of PDF documents”**. It’s a major undertaking – you’d need to interpret the PDF drawing operators and reconstruct strings. Apple’s documentation on PDF parsing (Core Graphics) can be a starting point if you truly want to dig into this, but implementing a full text extractor from scratch is error-prone.

PDFKit essentially does all that work internally and gives you the results in one call. As the Nutrient blog concluded, *“PDFKit has convenient APIs for working with text that are much easier and far less error-prone than using CGPDFScanner, as with PDFKit one is not required to have intricate knowledge of the PDF document structure”*. For nearly all applications, leveraging PDFKit is the smart choice for text extraction on Apple platforms. Only in very specialized cases (or on non-Apple platforms where PDFKit isn’t available) would you resort to the CoreGraphics scanning approach.

To summarize this chapter: **Use PDFKit to extract text whenever you can.** It’s one or two lines of code to get what you need, whereas the alternative is writing a mini PDF interpreter. Now, let’s move on to extracting images, where PDFKit’s conveniences are fewer and we might have to roll up our sleeves with CoreGraphics.

## Chapter 5: Extracting Images from PDFs

Images (raster graphics) embedded in PDFs are another common element you may want to extract – for instance, pulling out all photos from a document. Unlike text, PDFKit does **not** offer a simple one-call solution to get images. We’ll need to delve into the PDF’s structure using CoreGraphics to accomplish this. In this chapter, we’ll describe how to extract embedded images from PDF pages. We’ll also discuss the limitations (for example, not everything that looks like an image in a PDF is extractable as an image file).

### 5.1 Understanding Embedded Images vs. Rendered Graphics

First, it’s important to clarify what we mean by *“extracting images.”* A PDF can contain images that were placed by the document’s creator (e.g., a JPEG photograph on a page). These are stored in the PDF file as image XObjects (external objects) within the page’s resources. Those are the **embedded raster images** we aim to extract in original form. In contrast, a PDF can also have vector drawings or text that, when rendered, *look* like graphics but are not raster images – those cannot be simply “extracted” as image files; they’d have to be rasterized via rendering. Additionally, if a PDF is just one big image (like a scanned page), extracting that image is feasible (it’s an embedded image), but if the page is drawn with vector instructions, there is no JPEG/PNG to extract – you’d have to render the page to an image if needed.

**Key point:** Not all content that looks like an image in a PDF is a discrete image object. Some are vector graphics defined by drawing commands. Only actual image XObject streams can be extracted directly. With that in mind, let’s proceed to extraction.

### 5.2 Extracting Images with CoreGraphics

CoreGraphics provides the necessary functions to navigate the PDF object hierarchy and obtain image data. Here’s the general approach to extract images from a given PDF page:

1. **Open the PDF with CGPDFDocument:** Even if we originally loaded the PDF with PDFKit, we can use the same file with CGPDFDocument. For example:

   ```swift
   guard let cgDoc = CGPDFDocument(fileURL as CFURL) else {
       // handle error
   }
   ```

   This gives a low-level representation of the PDF. (If you already have a `PDFPage` via PDFKit, you can get its underlying `CGPDFPage` with `pdfPage.pageRef`, skipping directly to step 3.)

2. **Get the desired page:** PDF pages in CGPDFDocument are 1-indexed (note: this is different from PDFKit’s 0-indexing). So:

   ```swift
   let pageNumber = 1 // for first page, or any page of interest
   guard let cgPage = cgDoc.page(at: pageNumber) else { ... }
   ```

   Now `cgPage` is a `CGPDFPage` object.

3. **Get the page’s dictionary:** Each page has an associated dictionary of entries (in PDF terms, this is the page’s object dictionary). We need it to access the resources. In Swift, we can get it via:

   ```swift
   guard let pageDict = cgPage.dictionary else { ... }
   ```

   This `pageDict` is of type `CGPDFDictionaryRef` (a Core Foundation PDF dictionary reference).

4. **Get the Resources dictionary:** PDF page dictionaries usually have a key `"Resources"` pointing to another dictionary that includes fonts, images, and other resources used on the page. We retrieve it:

   ```swift
   var resDict: CGPDFDictionaryRef? = nil
   CGPDFDictionaryGetDictionary(pageDict, "Resources", &resDict)
   guard let resources = resDict else { ... }
   ```

   Now `resources` is the resources dictionary.

5. **Get the XObject dictionary:** Within resources, images are typically stored as *external objects*, under the `"XObject"` key:

   ```swift
   var xObjDict: CGPDFDictionaryRef? = nil
   CGPDFDictionaryGetDictionary(resources, "XObject", &xObjDict)
   guard let xObject = xObjDict else { ... }
   ```

   `xObject` now refers to the dictionary of all XObjects on the page – these could include images (Subtype "Image") and other forms (Subtype "Form" for embedded PDFs). We want the images.

6. **Iterate over XObject entries and filter images:** Each entry in `xObject` might be an image. They typically have names like "Im0", "Im1", etc., but not guaranteed. We will iterate through all entries:

   ```swift
   CGPDFDictionaryApplyBlock(xObject) { key, object, _ in
       // key: UnsafePointer<Int8> (the name of the object)
       // object: CGPDFObjectRef (the value, which could be stream or other type)
       var streamRef: CGPDFStreamRef? = nil
       if CGPDFObjectGetValue(object, .stream, &streamRef), 
          let stream = streamRef {
           // It's a stream object – possibly an image stream.
           if let streamDict = CGPDFStreamGetDictionary(stream) {
               // Check the subtype of the stream
               var subtypeName: UnsafePointer<Int8>? = nil
               CGPDFDictionaryGetName(streamDict, "Subtype", &subtypeName)
               if subtypeName != nil && String(cString: subtypeName!) == "Image" {
                   // We found an image XObject
                   // ... (we will extract data below)
               }
           }
       }
       return true // continue iteration
   }
   ```

   The `CGPDFDictionaryApplyBlock` in Swift iterates through each key-value in the dictionary. We attempt to get each value as a stream (`CGPDFObjectGetValue(..., .stream, &streamRef)`). If that succeeds, we have a `CGPDFStreamRef`. We then get the stream’s own dictionary (`streamDict`) to read its subtype. If the `"Subtype"` name is `"Image"`, we have indeed an image object. At that point, we can extract it.

7. **Extract the image data from the stream:** For an image XObject, the raw image data (after any filters/decoding) can be obtained via `CGPDFStreamCopyData`:

   ```swift
   var format: CGPDFDataFormat = .raw
   if let dataRef = CGPDFStreamCopyData(stream, &format) {
       let imageData = dataRef as Data  // bridging CFData to Swift Data
       // Now `imageData` holds the bytes of the image.
       // We can determine the format from `format`.
   }
   ```

   The `format` tells us the encoding: `.raw` means the image data is raw bitmap data (not encoded – maybe needs interpretation with color space info), `.jpegEncoded` means it’s JPEG compressed data, `.JPEG2000` for JPEG 2000, etc. Often, PDF images are stored with compression (JPEG), so the data might already be a valid JPEG file bytes. If `format` is `.jpegEncoded` or `.JPEG2000`, you could directly write `imageData` to a file with a `.jpg` or `.jp2` extension. If it’s `.raw`, you would need to also get details like width, height, bits per component, color space from the `streamDict` (keys like `"Width"`, `"Height"`, `"ColorSpace"`, etc.) and construct an image from the raw data (this is an advanced case – not all raw data extraction is trivial, but many PDFs will use JPEG which simplifies things).

8. **Convert or save the image data:** Depending on what you want to do, you can:

   * Create a platform image object (like `NSImage` on macOS) from the data. For example, `let nsImage = NSImage(data: imageData)`. This works if the data is in a format NSImage recognizes (JPEG, PNG, TIFF, etc.). If `format` was `.raw`, NSImage might not directly init from it; you’d have to manually create a CGImage with the pixel data.
   * Save to a file:

     ```swift
     try? imageData.write(to: URL(fileURLWithPath: "outputImage.jpg"))
     ```

     (Ensure you choose the correct file extension based on `format` or PDF filters. If it’s raw, perhaps save as TIFF or BMP after constructing an image.)

Putting it all together, a simplified code to extract all images from page 1 of a PDF might look like this:

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
    // Iterate over XObject entries
    CGPDFDictionaryApplyBlock(xObject) { keyPtr, object, _ in
        // keyPtr is a C string for the object name
        var streamRef: CGPDFStreamRef? = nil
        if CGPDFObjectGetValue(object, .stream, &streamRef), let stream = streamRef {
            if let streamDict = CGPDFStreamGetDictionary(stream) {
                var subtypePtr: UnsafePointer<Int8>? = nil
                CGPDFDictionaryGetName(streamDict, "Subtype", &subtypePtr)
                if let subtype = subtypePtr, String(cString: subtype) == "Image" {
                    // We found an image stream
                    var format = CGPDFDataFormat.raw
                    if let cfData = CGPDFStreamCopyData(stream, &format) {
                        let data = cfData as Data
                        let name = String(cString: keyPtr)  // image object name like "Im0"
                        print("Extracted image \(name), \(data.count) bytes, format \(format)")
                        // Save the image data to file for demonstration
                        let fileExt = (format == .jpegEncoded ? "jpg" : (format == .JPEG2000 ? "jp2" : "bin"))
                        let outURL = URL(fileURLWithPath: "\(name).\(fileExt)")
                        try? data.write(to: outURL)
                    }
                }
            }
        }
        return true  // continue to next object
    }
}
```

This code will iterate through all XObjects on the first page, and for each image found, it writes it out to a file named by its object key (e.g., "Im0.jpg", "Im1.jpg", etc.). We choose a file extension based on the data format for convenience.

In a real-world tool, you might iterate through all pages (outer loop over page index, inner loop over XObjects) to extract images from every page, similar to how we did for text. You’d also want to handle duplicate images or very small images (some PDFs might have tiny images for icons, etc., depending on your needs).

A few things to be cautious about:

* The example above assumes `CGPDFDictionaryApplyBlock` is available (it is on macOS 10.14+ and iOS 12+). If you target older systems, you would use `CGPDFDictionaryApplyFunction` with an unsafe pointer and context instead.
* We only checked for `"Subtype" == "Image"`, but that’s the main indicator of an image XObject. No further filtering is needed for basic usage.
* We used `CGPDFObjectGetValue(object, .stream, &streamRef)` which elegantly checks if the object is a stream. In pure C, you might first get the type then cast; this helper makes it concise.

### 5.3 Extracting Images with PDFKit (via PDFPage)

As mentioned, PDFKit doesn’t have an explicit API like “give me all images on this page.” However, PDFKit can work in tandem with CoreGraphics. If you have a `PDFPage` from PDFKit, you can get its `pageRef`, which is the `CGPDFPage`. From there, you can essentially reuse the CoreGraphics approach above on that `CGPDFPage`. This might be slightly simpler in a context where you’re already dealing with PDFPage objects (for example, you enumerated pages with PDFKit, and for each page you want to extract images – you can call page.pageRef and then do the CG extraction).

To illustrate, using PDFKit and CG together:

```swift
if let pdfPage = pdfDoc.page(at: 0) {
    if let cgPage = pdfPage.pageRef {
        // from cgPage, follow steps to get dictionary, resources, etc.
        // (effectively the same as above, starting from cgPage.dictionary)
    }
}
```

Thus, you can leverage PDFKit for high-level tasks and drop to CoreGraphics only when needed for images. This hybrid approach is often convenient.

### 5.4 Example Use-Case: Saving PDF Images to Disk

Imagine you have a PDF full of photographs and you want to save each photo as a JPEG file. Using the concepts above, you can write a CLI tool (`pdfimages` perhaps) that does exactly that. It would:

* Open the PDF with PDFKit or CGPDFDocument.
* Loop through pages.
* For each page, find all image XObjects.
* Retrieve the image data and determine its format.
* Save each image to a file (maybe name it like `<PDFName>_page_<n>_image_<m>.jpg`).

The code we sketched out can be extended to loop pages easily. We already wrote the images with names like "Im0.jpg" which resets each page; you could integrate page number into the name to avoid collisions and know origin.

**Important note:** The extraction will retrieve the images in their original form. If a PDF’s image was downsampled or heavily compressed, that’s what you get. If you need a higher resolution than what’s embedded, you’re out of luck – you’d have to have the source image or vector data. Conversely, if you just want an image of the page *as it looks*, including text and drawings, that’s a different task: rendering the page to an image (which PDFKit and CoreGraphics both can do by drawing the PDF to a graphics context). But here we specifically focus on extracting the actual images that were placed into the PDF.

### 5.5 Handling Edge Cases

* **No images on a page:** Then the XObject dictionary might be empty or nonexistent. Our code above prints “No XObject on page” in that case. It’s not an error, just means nothing to extract.
* **Multiple images on one page:** The code as written will catch them all via the apply block and save them individually.
* **Image format issues:** If `format` is `.raw`, the saved `.bin` file might not be directly viewable. That case requires constructing an image manually. For completeness, if you encounter this: the `streamDict` will have keys like `"Width"`, `"Height"`, `"BitsPerComponent"`, `"ColorSpace"` etc. You’d use those to create a `CGDataProvider` from `data`, then a `CGColorSpace` (if ColorSpace is DeviceRGB, DeviceGray, etc.), and then make a `CGImage` with `CGImage(width:height:bitsPerComponent:bitsPerPixel:bytesPerRow:space:bitmapInfo:provider:decode:shouldInterpolate:intent:)`. That is beyond our current scope, but be aware it can be done. In many cases, PDF images will be compressed (JPEG), thus not raw.
* **Performance:** Extracting images with CG is relatively fast for typical PDFs, but extremely image-heavy PDFs could have dozens or hundreds of images. Ensure you handle memory by not keeping large image data in memory longer than needed (write to disk or process it, then free). The code above processes one image at a time in the loop.

Now that we’ve covered both text and image extraction, let’s compare the PDFKit vs CoreGraphics approaches and then discuss some best practices for building efficient, reliable PDF parsing tools.

## Chapter 6: PDFKit vs CoreGraphics – Choosing the Right Tool

We have explored using **PDFKit** for high-level tasks and **CoreGraphics** for low-level extraction. It’s important to understand the differences and when to use each.

**Ease of Use:** PDFKit is far easier for operations like reading text. It provides one-line methods to get text content, whereas CoreGraphics would require implementing a full PDF content parser (not recommended). Similarly, PDFKit provides classes to represent pages, selections, annotations, etc., making it straightforward to navigate and manipulate PDF content in an object-oriented way. CoreGraphics deals with raw references and CFTypes, requiring manual checks and conversions (as we saw with image extraction). For a beginner or for rapid development, PDFKit is generally the go-to choice for anything it supports.

**Capabilities:** PDFKit covers most common needs: extracting text, searching text, rendering pages, reading metadata, and even writing/modifying pages (inserting or removing pages, adding annotations). However, PDFKit does **not** expose everything. For example, as we saw, there’s no direct API to list images or vector drawings on a page. CoreGraphics, on the other hand, exposes the PDF at the object level – you can access dictionaries for any PDF object, streams for raw data, etc. This means with CoreGraphics you can extract content that PDFKit doesn’t directly offer (like embedded images), or you can access lower-level info (like raw annotation dictionaries, content streams) if needed for specialized parsing.

**Performance:** Both PDFKit and CoreGraphics are built on the same underlying engine (PDFKit uses CoreGraphics internally). For basic operations, performance is similar. However, PDFKit might add a slight overhead due to object creation (e.g., making PDFPage objects, etc.). CoreGraphics can be more memory-efficient if you only need a specific piece of data, because you can avoid loading entire pages through PDFKit’s abstractions. For instance, if you only wanted the number of pages, `CGPDFDocument` can get it without creating many objects; PDFKit’s `pageCount` is probably equally quick though. In practice, both are fast for reading content. If you were doing bulk processing of many PDFs, you might profile to see if PDFKit’s conveniences have any cost. Generally, using PDFKit for text extraction is not a bottleneck – the heavy work (parsing the PDF) happens in native code either way.

Where performance might differ is when manipulating or rendering PDFs. PDFKit can render pages via `PDFPage.draw(with:to:)`, which is again a wrapper around CoreGraphics drawing. For extraction tasks, the differences are negligible.

**Memory Management:** PDFKit being a high-level API means you rely on Swift’s ARC to manage `PDFDocument` and `PDFPage` objects. These likely hold references to underlying CG structures. CoreGraphics functions, by contrast, often return unmanaged objects (though Swift’s bridging might auto-handle some). We should be mindful to not leak `CGPDFDocument` or large CFData objects. Typically, if you store them in variables and those variables go out of scope, they’ll be released. One advantage of PDFKit is that it will cache or handle data for you (for example, `PDFDocument` might not keep all page content in memory at once – it can lazy load). CoreGraphics will only load things on demand too, but if you, say, retrieve a huge image stream as Data, you need to be careful with it (especially on iOS devices with limited memory).

**Advanced Features:** PDFKit includes some high-level features built-in, such as selection highlighting, find with highlights, etc., which are more relevant in a GUI context. CoreGraphics has none of that – it’s purely data. If you needed to, for example, build an algorithm to detect paragraphs or do layout analysis, you might combine PDFKit’s text extraction with your own logic, or even drop to CoreGraphics to get positional data of each text chunk (through `CGPDFScanner`). That’s very advanced though. Generally, if PDFKit can do it, use PDFKit. If it cannot, then consider CoreGraphics or a third-party PDF library.

**Compatibility:** PDFKit is available on macOS (10.4 and later) and iOS (11 and later). CoreGraphics PDF API is available on all Apple platforms (and is C-based, so even usable from other languages on Apple). If you ever needed to support other OS (Linux, Windows), PDFKit isn’t an option there – you’d need a cross-platform PDF library or parse PDF yourself. But if you’re targeting macOS specifically (as this book assumes), PDFKit plus CoreGraphics is a powerful combo.

**Summary of When to Use What:**

* Use **PDFKit** for:

  * Quick extraction of all text or searching text in PDFs.
  * Basic PDF metadata (title, author) and page count.
  * Manipulating PDF pages (reordering, adding, removing) or annotations (notes, highlights) – which we didn’t cover here but PDFKit can do.
  * Rendering pages to images or PDF view display in a Mac/iOS app.
  * Any scenario where a high-level API exists for what you need (to avoid re-inventing the wheel).

* Use **CoreGraphics** for:

  * Extracting content that PDFKit doesn’t surface (images, detailed font info, vector path data, etc.).
  * Fine-grained control or custom processing of PDF content streams.
  * Possibly for performance in edge cases (batch processing where avoiding object overhead is critical – though this is rare).
  * When working in a context where PDFKit is unavailable (e.g., lower-level code or maybe command-line without linking PDFKit, though on macOS you can always link it).

Often, you’ll use both. For example, you might use PDFKit to get text because it’s easy, and also use CoreGraphics to get images on the same pages. The good news is they interoperate (via `pageRef` on `PDFPage`) so you don’t have to open the file twice if you don’t want to – but even if you did (opening with PDFKit and CGPDFDocument separately), it’s not a big issue.

In the end, PDFKit is a friendly API for most tasks, and CoreGraphics is your escape hatch for the tough stuff. Knowing both allows you to build robust PDF tools on macOS.

## Chapter 7: Best Practices for Performance, Memory Management, and Error Handling

When building command-line PDF parsing tools (or any PDF processing code), adhering to some best practices will make your programs more efficient and reliable. This chapter compiles a set of tips and practices:

### 7.1 Performance Considerations

* **Process Only What You Need:** PDFs can be large (hundreds of pages). If you only need text from certain pages or images from the first few pages, do not loop over the entire document unnecessarily. Both PDFKit and CoreGraphics allow random access to pages. For instance, you can directly get `page(at: 50)` without reading pages 1–49 first (internally it will skip to that object). Take advantage of that to avoid needless work.

* **Avoid Repeated Expensive Calls:** If using PDFKit’s `findString` in a loop or repeatedly scanning the same content, consider caching results. Similarly, if you need to extract all text and all images, you might traverse the document once and handle both rather than, say, reading text in one pass and then images in another separate full pass.

* **Background Processing:** In a CLI tool, this is less of an issue since you likely just run to completion. But if integrating PDF parsing into a larger app (like a GUI or server), do heavy PDF work on background threads/queues. PDFKit is generally thread-safe for reading as long as you don’t manipulate the same objects from multiple threads concurrently. CoreGraphics CGPDFDocument is also thread-safe for reading different pages, but not explicitly documented for parallel use – safest is to use one thread per document or use locks if multi-threading.

* **Use Autorelease Pools (if needed):** In Swift CLI, long-running loops that create many intermediate objects (like `PDFPage` or `Data`) might not release memory immediately if references persist. If you’re processing thousands of pages, consider wrapping each iteration in an autoreleasepool block (especially if using Objective-C based API like PDFKit classes) to force cleanup of temporary objects sooner. For example:

  ```swift
  for i in 0..<pdfDoc.pageCount {
      autoreleasepool {
          if let page = pdfDoc.page(at: i) {
             let text = page.string  // use it
          }
      }
  }
  ```

  This is a tip more relevant for Objective-C, but can apply to Swift when using frameworks that might allocate Objective-C objects under the hood.

* **Large Data Handling:** If extracting very large images or text, be mindful when concatenating data. For text, using `String` concatenation in a loop (like `fullText += pageText`) can be less efficient due to repeated allocations. Consider using an `NSMutableString` or writing to a file/`OutputStream` progressively. For images, as soon as you have the `Data`, if you don’t need it in memory, write it to disk and free it (set the reference to nil) to avoid accumulating huge data in RAM.

* **Leverage PDFKit’s Features:** If performance of text search is a concern (e.g., searching across many PDFs), note that PDFKit itself doesn’t index – it will search brute-force. For advanced use, external libraries or indexing might be needed. But since this is about extraction, an alternative is to extract text and then do text processing outside PDFKit, which can be faster if you do it once and reuse results.

### 7.2 Memory Management

* **Release PDFs When Done:** If you open a `PDFDocument` or `CGPDFDocument`, and you’re done with it, set the reference to nil so it can be deallocated. In CLI tools, the program often exits after finishing, so memory will be freed anyway. But if you had a long-running tool that opens many PDFs sequentially, make sure to free each before moving to the next to avoid piling up memory usage.

* **Beware of Large Object Lifetimes:** A `PDFDocument` may cache data for performance (for example, rendered page images or parsed content). If you open many PDFs simultaneously, memory could spike. It might be better to process one at a time. If you need concurrency for speed, consider processing in parallel only if memory can handle it.

* **CoreGraphics Streams:** The `CGPDFStreamCopyData` gives you a CFData. In Swift, we bridged it to `Data`. Make sure large `Data` objects are handled carefully – maybe write to file promptly. Also, if you loop inside `CGPDFDictionaryApplyBlock` and accumulate images in an array, you might consume a lot of memory if the PDF has many images. Instead, consider processing each image (e.g., saving to disk) and then discarding it before moving to the next.

* **No Modify in Place:** CoreGraphics `CGPDFDocument` is effectively read-only (immutable). You cannot modify it (except unlocking with a password). PDFKit’s `PDFDocument` *can* modify (like insert pages) but that creates a new PDF or alters structure in memory. So there's generally no concern of accidentally altering the source file – unless you explicitly write out changes with `PDFDocument.write(to:)`. Our focus is reading, so we naturally won’t be modifying. This is just to note that memory usage is mostly for reading and parsing buffers, not for storing large changed versions of PDFs.

### 7.3 Error Handling and Edge Cases

* **Graceful Handling of Bad PDFs:** Sometimes PDFs can be corrupted or have unusual structure. `PDFDocument` might return nil or have a pageCount but some pages can’t be accessed. Always code defensively: use guards/ifs when accessing pages or content. If `page(at:)` returns nil for a valid index, handle it (maybe log a warning and continue).

* **Encrypted PDFs:** We touched on this, but ensure your tool can detect encryption. With PDFKit:

  ```swift
  if pdfDoc.isEncrypted && !pdfDoc.isUnlocked {
      // prompt for password or handle accordingly
  }
  ```

  With CGPDFDocument:

  ```swift
  if cgDoc.isEncrypted && !cgDoc.isUnlocked {
      // use CGPDFDocumentUnlockWithPassword(cgDoc, password) if possible
  }
  ```

  If you cannot unlock (no password provided or wrong password), decide how your tool responds – maybe skip content extraction or output an error message.

* **Unicode and Encoding:** Text extraction via PDFKit usually yields proper Unicode. But occasionally, PDFs might have custom character encoding that PDFKit handles internally. If you notice odd characters, it might be due to missing font information or encoding quirks. There’s not a lot you can do with PDFKit in such cases, but it’s good to be aware. CoreGraphics extraction (if you implemented it) would require manually decoding those encodings via the font’s ToUnicode map – a complex task. This is another reason to trust PDFKit’s output where possible.

* **Image Color Spaces:** If you extract images, some might not be in standard RGB. PDF could have images in CMYK or grayscale or with weird color profiles. Our code above didn’t explicitly handle color space beyond writing raw data. If an image `format` is raw, you would need the ColorSpace entry (for example, it might be DeviceCMYK which means 4 channels). If you write raw CMYK data and label it .png, it wouldn’t be directly viewable. Ideally, for raw data, convert it to a standard format (like create a CGImage and then output a PNG or JPEG). This is an edge case unless you know your PDFs contain such images.

* **Logging and Progress:** For large tasks, provide feedback. In a CLI, that could be as simple as printing “Processing page X of Y” or “Found 5 images on page 10”. This helps the user know the tool is working, especially if it takes several seconds or more.

* **Testing on Various PDFs:** PDFs can vary *wildly*. Test your tool on a variety: a text-only PDF, an image-heavy PDF, a scanned PDF (image-only), a PDF with columns or complex layout, a PDF with attachments or forms (which we didn’t cover – PDFKit can handle form fields too via `PDFAnnotation`), etc. This will help you catch any assumptions in your code. For instance, some PDF might not have a Resources dictionary (rare, but maybe an empty page?). Our code would handle that by printing “No resources on page.” That’s fine, but we know it’s not a crash at least.

* **Cleanup**: If your tool writes output files (like extracted images or text), consider cleaning up partial outputs if an error occurs halfway. Or at least clearly name outputs so the user can identify which came from which PDF and avoid overwriting files from a previous run by accident.

### 7.4 Example: Bringing It All Together

To illustrate best practices, let’s sketch how a complete CLI tool might work when extracting text and images:

1. **Argument parsing** – get input PDF path, output directory, maybe options flags (like `--text` or `--images` to choose what to extract).
2. **Open PDF** – with PDFDocument (for text) and/or CGPDFDocument (for images). If fails, print error and exit.
3. **If text extraction enabled** – use PDFKit to get text. If the PDF is huge, perhaps write incrementally: open a file for writing the text, loop pages and append text per page to the file. That way memory usage stays low. Or if just printing to stdout, you can stream it out per page.
4. **If image extraction enabled** – loop through pages and use CG as demonstrated. Perhaps count images and save files with meaningful names. Maybe also generate a summary like “Extracted 12 images from 10 pages.”
5. **Handle errors** – if any page fails to process, continue to next, but note it. If an image fails to write, warn the user.
6. **Memory** – ensure any large data isn’t kept around unnecessarily (e.g., don’t store all text in a giant string if you could stream to a file).
7. **Close and exit** – not much to explicitly close in Swift, but you might flush file handles.

This approach will yield a robust tool. For example, a hypothetical run:

```
$ pdfparser --text --images input.pdf --output-dir out
```

This could produce `out/input.txt` containing all text and image files like `out/input_page1_image1.jpg`, etc.

The user of your tool can then use the text for indexing or searching and the images for analysis or reuse.

## Conclusion

In this tutorial book, we covered how to harness Swift on macOS to read and parse PDFs from the command line, focusing on text and image extraction. You learned about **PDFKit**, Apple’s high-level PDF framework, which makes tasks like extracting text as simple as calling a property or method. You also delved into **CoreGraphics** for low-level PDF parsing to extract embedded images, exploring the PDF object structure (page dictionaries, resources, XObjects). Along the way, we discussed differences between these approaches – PDFKit’s ease and CoreGraphics’ control – and provided guidance on when to use each. Finally, we highlighted best practices to ensure your PDF CLI tools run efficiently and handle edge cases gracefully.

With this knowledge, you can build powerful PDF processing tools. As a next step, you might consider extending your skills to other PDF features (annotations, form data extraction, PDF creation if needed, etc.) or even integrate this functionality into a larger macOS app or automation script. Swift’s performance and Apple’s PDF libraries give you a solid foundation to work with one of the world’s most important document formats.

Happy coding, and happy parsing! By mastering PDFKit and CoreGraphics, you have opened the door to a wide range of PDF automation and analysis tasks on macOS – all from the command line and all with the power of Swift.

**Sources:**

* Apple Developer Documentation – PDFKit and CoreGraphics (Quartz) References
* Nutrient Blog – *PDF Text Extraction in Swift*
* Nutrient Blog – *Extracting Images from a PDF in Swift*
* Stack Overflow – Various Q\&A on PDFKit usage and PDF parsing
* smittytone.net – *Writing macOS CLI tools in Swift* (for CLI setup best practices)
* Tech Holding Blog – *Managing PDFs in iOS using PDFKit* (overview of PDFKit features)
* PSPDFKit/Nutrient Articles – Insights on PDFKit vs advanced PDF SDK features
