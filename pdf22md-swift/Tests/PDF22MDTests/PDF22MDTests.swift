import XCTest
@testable import PDF22MD

final class PDF22MDTests: XCTestCase {
    
    // MARK: - TextElement Tests
    
    func testTextElementCreation() {
        let element = TextElement(
            text: "Hello, World!",
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            pageIndex: 0
        )
        
        XCTAssertEqual(element.text, "Hello, World!")
        XCTAssertEqual(element.pageIndex, 0)
        XCTAssertEqual(element.headingLevel, 0)
        XCTAssertFalse(element.isBold)
        XCTAssertFalse(element.isItalic)
    }
    
    func testTextElementMarkdownGeneration() {
        // Test regular text
        let regularText = TextElement(
            text: "Regular paragraph text",
            bounds: CGRect.zero,
            pageIndex: 0
        )
        XCTAssertEqual(regularText.markdownRepresentation(), "Regular paragraph text")
        
        // Test heading
        var heading = TextElement(
            text: "Chapter Title",
            bounds: CGRect.zero,
            pageIndex: 0
        )
        heading.headingLevel = 1
        XCTAssertEqual(heading.markdownRepresentation(), "# Chapter Title")
        
        // Test bold text
        let boldText = TextElement(
            text: "Bold text",
            bounds: CGRect.zero,
            pageIndex: 0,
            fontName: "Arial-Bold",
            fontSize: 12.0,
            isBold: true,
            isItalic: false
        )
        XCTAssertEqual(boldText.markdownRepresentation(), "**Bold text**")
        
        // Test italic text
        let italicText = TextElement(
            text: "Italic text",
            bounds: CGRect.zero,
            pageIndex: 0,
            fontName: "Arial-Italic",
            fontSize: 12.0,
            isBold: false,
            isItalic: true
        )
        XCTAssertEqual(italicText.markdownRepresentation(), "*Italic text*")
        
        // Test bold italic text
        let boldItalicText = TextElement(
            text: "Bold italic text",
            bounds: CGRect.zero,
            pageIndex: 0,
            fontName: "Arial-BoldItalic",
            fontSize: 12.0,
            isBold: true,
            isItalic: true
        )
        XCTAssertEqual(boldItalicText.markdownRepresentation(), "***Bold italic text***")
    }
    
    func testTextElementEquality() {
        let element1 = TextElement(
            text: "Test text",
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            pageIndex: 0
        )
        
        let element2 = TextElement(
            text: "Test text",
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            pageIndex: 0
        )
        
        XCTAssertEqual(element1, element2)
    }
    
    // MARK: - ConversionOptions Tests
    
    func testConversionOptionsDefaults() {
        let options = ConversionOptions()
        
        XCTAssertNil(options.assetsFolderPath)
        XCTAssertEqual(options.rasterizationDPI, 144.0)
        XCTAssertTrue(options.includeMetadata)
        XCTAssertTrue(options.extractImages)
        XCTAssertTrue(options.preserveOutline)
        XCTAssertEqual(options.headingFontSizeThreshold, 2.0)
        XCTAssertEqual(options.maxHeadingLevel, 6)
    }
    
    func testConversionOptionsValidation() {
        var options = ConversionOptions()
        
        // Valid options should not throw
        XCTAssertNoThrow(try options.validate())
        
        // Invalid DPI should throw
        options.rasterizationDPI = -1
        XCTAssertThrowsError(try options.validate()) { error in
            XCTAssertTrue(error is PDFError)
            if case .invalidConfiguration = error as! PDFError {
                // Expected error type
            } else {
                XCTFail("Expected invalidConfiguration error")
            }
        }
        
        // Reset to valid value
        options.rasterizationDPI = 144.0
        
        // Invalid max heading level should throw
        options.maxHeadingLevel = 0
        XCTAssertThrowsError(try options.validate())
        
        options.maxHeadingLevel = 7
        XCTAssertThrowsError(try options.validate())
    }
    
    func testConversionOptionsBuilder() {
        let options = ConversionOptionsBuilder()
            .assetsFolderPath("/tmp/assets")
            .rasterizationDPI(300.0)
            .includeMetadata(false)
            .extractImages(true)
            .maxHeadingLevel(3)
            .build()
        
        XCTAssertEqual(options.assetsFolderPath, "/tmp/assets")
        XCTAssertEqual(options.rasterizationDPI, 300.0)
        XCTAssertFalse(options.includeMetadata)
        XCTAssertTrue(options.extractImages)
        XCTAssertEqual(options.maxHeadingLevel, 3)
    }
    
    // MARK: - FontAnalyzer Tests
    
    func testFontKeyGeneration() {
        let key1 = FontAnalyzer.fontKey(forFontName: "Arial", fontSize: 12.0)
        let key2 = FontAnalyzer.fontKey(forFontName: "Arial", fontSize: 12.0)
        let key3 = FontAnalyzer.fontKey(forFontName: "Arial", fontSize: 14.0)
        let key4 = FontAnalyzer.fontKey(forFontName: nil, fontSize: 12.0)
        
        XCTAssertEqual(key1, key2)
        XCTAssertNotEqual(key1, key3)
        XCTAssertEqual(key4, "12.0-Unknown")
    }
    
    func testFontAnalyzerBasicFunctionality() {
        let analyzer = FontAnalyzer()
        
        let elements: [ContentElement] = [
            TextElement(
                text: "Body text",
                bounds: CGRect.zero,
                pageIndex: 0,
                fontName: "Arial",
                fontSize: 12.0,
                isBold: false,
                isItalic: false
            ),
            TextElement(
                text: "Heading",
                bounds: CGRect.zero,
                pageIndex: 0,
                fontName: "Arial-Bold",
                fontSize: 18.0,
                isBold: true,
                isItalic: false
            )
        ]
        
        analyzer.analyzeElements(elements)
        let stats = analyzer.getSortedFontStatistics()
        
        XCTAssertEqual(stats.count, 2)
        // Should be sorted by font size (largest first)
        XCTAssertEqual(stats[0].fontSize, 18.0)
        XCTAssertEqual(stats[1].fontSize, 12.0)
    }
    
    // MARK: - PDFError Tests
    
    func testPDFErrorMessages() {
        let invalidPDFError = PDFError.invalidPDF(reason: "Corrupted file")
        XCTAssertEqual(invalidPDFError.errorDescription, "Invalid or corrupted PDF file: Corrupted file")
        
        let assetError = PDFError.assetCreationFailed(path: "/tmp/test", reason: "No permission")
        XCTAssertEqual(assetError.errorDescription, "Failed to create or save asset at /tmp/test: No permission")
        
        let pageError = PDFError.pageProcessingFailed(page: 5, reason: "Malformed content")
        XCTAssertEqual(pageError.errorDescription, "Failed to process page 6: Malformed content")
        
        let cancelledError = PDFError.cancelled
        XCTAssertEqual(cancelledError.errorDescription, "Operation was cancelled")
    }
    
    // MARK: - MarkdownGenerator Tests
    
    func testMarkdownGeneratorBasic() {
        let options = ConversionOptions()
        let generator = MarkdownGenerator(options: options)
        
        let elements: [ContentElement] = [
            TextElement(text: "First paragraph", bounds: CGRect.zero, pageIndex: 0),
            TextElement(text: "Second paragraph", bounds: CGRect.zero, pageIndex: 0)
        ]
        
        let markdown = generator.generateMarkdownContent(from: elements)
        XCTAssertTrue(markdown.contains("First paragraph"))
        XCTAssertTrue(markdown.contains("Second paragraph"))
    }
    
    func testYAMLEscaping() {
        let options = ConversionOptions()
        let generator = MarkdownGenerator(options: options)
        
        // Test string escaping
        let testString = "Test \"quotes\" and\nnewlines"
        let escaped = generator.generateYAMLFrontmatter(DocumentMetadata(pageCount: 1))
        
        // Basic YAML structure should be present
        XCTAssertTrue(escaped?.contains("---") == true)
        XCTAssertTrue(escaped?.contains("pdf_metadata:") == true)
        XCTAssertTrue(escaped?.contains("page_count: 1") == true)
    }
    
    // MARK: - Performance Tests
    
    func testTextElementPerformance() {
        measure {
            for i in 0..<1000 {
                let element = TextElement(
                    text: "Performance test text \(i)",
                    bounds: CGRect(x: 0, y: CGFloat(i), width: 100, height: 20),
                    pageIndex: i % 10
                )
                _ = element.markdownRepresentation()
            }
        }
    }
    
    func testFontAnalyzerPerformance() {
        let analyzer = FontAnalyzer()
        let elements = (0..<1000).map { i in
            TextElement(
                text: "Text \(i)",
                bounds: CGRect.zero,
                pageIndex: 0,
                fontName: "Arial",
                fontSize: CGFloat(12 + (i % 6)),
                isBold: i % 2 == 0,
                isItalic: i % 3 == 0
            )
        }
        
        measure {
            analyzer.analyzeElements(elements)
            _ = analyzer.getSortedFontStatistics()
        }
    }
}