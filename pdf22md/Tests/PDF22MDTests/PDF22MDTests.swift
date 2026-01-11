// this_file: pdf22md/Tests/PDF22MDTests/PDF22MDTests.swift

import XCTest
import Foundation
@testable import PDF22MD

final class PDF22MDTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
        // Create temporary test directory
        createTestDirectories()
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up temporary test files
        cleanupTestFiles()
    }
    
    // MARK: - Helper Methods
    
    private func createTestDirectories() {
        let testPath = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        try? FileManager.default.createDirectory(at: testPath, withIntermediateDirectories: true)
    }
    
    private func cleanupTestFiles() {
        let testPath = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        try? FileManager.default.removeItem(at: testPath)
    }
    
    private func getTestResourcePath(_ filename: String) -> URL? {
        let bundle = Bundle.module
        return bundle.url(forResource: filename, withExtension: nil, subdirectory: "test-resources/pdfs")
    }
    
    private func getExpectedOutputPath(_ filename: String) -> URL? {
        let bundle = Bundle.module
        return bundle.url(forResource: filename, withExtension: nil, subdirectory: "test-resources/expected-outputs")
    }
    
    // MARK: - Version Tests
    
    func testVersionInfo() {
        XCTAssertFalse(Version.current.isEmpty, "Version should not be empty")
        XCTAssertFalse(Version.fullVersion.isEmpty, "Full version should not be empty")
        
        // Test that version contains expected format
        let version = Version.current
        XCTAssertTrue(version.contains(".") || version == "dev", "Version should contain dots or be 'dev'")
        
        print("Current version: \(Version.current)")
        print("Full version: \(Version.fullVersion)")
        print("Commit: \(Version.commit)")
        print("Build date: \(Version.buildDate)")
    }
    
    // MARK: - Font Statistics Tests
    
    func testFontStatistics() {
        let stats = FontStatistics()
        
        // Test font registration
        stats.registerFont(name: "Helvetica", size: 12.0)
        stats.registerFont(name: "Helvetica", size: 12.0)
        stats.registerFont(name: "Helvetica", size: 14.0)
        stats.registerFont(name: "Arial", size: 16.0)
        
        // Test font usage counts
        XCTAssertEqual(stats.getUsageCount(name: "Helvetica", size: 12.0), 2)
        XCTAssertEqual(stats.getUsageCount(name: "Helvetica", size: 14.0), 1)
        XCTAssertEqual(stats.getUsageCount(name: "Arial", size: 16.0), 1)
        
        // Test heading level determination
        let level1 = stats.getHeadingLevel(name: "Arial", size: 16.0)
        let level2 = stats.getHeadingLevel(name: "Helvetica", size: 14.0)
        let level3 = stats.getHeadingLevel(name: "Helvetica", size: 12.0)
        
        XCTAssertLessThan(level1, level2, "Larger font should have lower heading level")
        XCTAssertLessThan(level2, level3, "Larger font should have lower heading level")
    }
    
    // MARK: - PDF Element Tests
    
    func testTextElement() {
        let element = TextElement(
            text: "Hello World",
            fontName: "Helvetica",
            fontSize: 12.0,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            isBold: false,
            isItalic: false
        )
        
        XCTAssertEqual(element.text, "Hello World")
        XCTAssertEqual(element.fontName, "Helvetica")
        XCTAssertEqual(element.fontSize, 12.0)
        XCTAssertFalse(element.isBold)
        XCTAssertFalse(element.isItalic)
        
        // Test markdown conversion
        let markdown = element.toMarkdown(headingLevel: 0)
        XCTAssertEqual(markdown, "Hello World")
        
        // Test heading markdown
        let headingMarkdown = element.toMarkdown(headingLevel: 2)
        XCTAssertEqual(headingMarkdown, "## Hello World")
        
        // Test bold text
        let boldElement = TextElement(
            text: "Bold Text",
            fontName: "Helvetica-Bold",
            fontSize: 12.0,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            isBold: true,
            isItalic: false
        )
        let boldMarkdown = boldElement.toMarkdown(headingLevel: 0)
        XCTAssertEqual(boldMarkdown, "**Bold Text**")
    }
    
    func testImageElement() {
        let element = ImageElement(
            imagePath: "test-image.png",
            bounds: CGRect(x: 0, y: 0, width: 200, height: 150)
        )
        
        XCTAssertEqual(element.imagePath, "test-image.png")
        XCTAssertEqual(element.bounds.width, 200)
        XCTAssertEqual(element.bounds.height, 150)
        
        // Test markdown conversion
        let markdown = element.toMarkdown(headingLevel: 0)
        XCTAssertEqual(markdown, "![Image](test-image.png)")
    }
    
    // MARK: - Asset Extractor Tests
    
    func testAssetExtractor() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let assetsDir = tempDir.appendingPathComponent("assets")
        
        let extractor = AssetExtractor(assetsDirectory: assetsDir)
        
        // Test directory creation
        XCTAssertTrue(FileManager.default.fileExists(atPath: assetsDir.path), "Assets directory should be created")
        
        // Test filename generation
        let filename1 = extractor.generateImageFilename(pageIndex: 0, imageIndex: 0)
        let filename2 = extractor.generateImageFilename(pageIndex: 1, imageIndex: 5)
        
        XCTAssertEqual(filename1, "image_000.png")
        XCTAssertEqual(filename2, "image_006.png")
        
        // Test format determination
        XCTAssertTrue(extractor.shouldUseJPEG(hasAlpha: false, colorComplexity: 0.8))
        XCTAssertFalse(extractor.shouldUseJPEG(hasAlpha: true, colorComplexity: 0.8))
        XCTAssertFalse(extractor.shouldUseJPEG(hasAlpha: false, colorComplexity: 0.3))
    }
    
    // MARK: - PDF Processing Tests
    
    func testPDFPageProcessor() {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }
        
        guard let document = CGPDFDocument(testPDFPath as CFURL) else {
            XCTFail("Could not load test PDF document")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let assetsDir = tempDir.appendingPathComponent("assets")
        let assetExtractor = AssetExtractor(assetsDirectory: assetsDir)
        
        let processor = PDFPageProcessor(assetExtractor: assetExtractor, dpi: 144.0)
        
        // Test page count
        let pageCount = document.numberOfPages
        XCTAssertGreaterThan(pageCount, 0, "Test PDF should have at least one page")
        
        // Test page processing
        guard let page = document.page(at: 1) else {
            XCTFail("Could not get first page of test PDF")
            return
        }
        
        let elements = processor.processPage(page, pageIndex: 0)
        XCTAssertGreaterThan(elements.count, 0, "Should extract some elements from the page")
        
        // Verify element types
        let textElements = elements.compactMap { $0 as? TextElement }
        let imageElements = elements.compactMap { $0 as? ImageElement }
        
        XCTAssertGreaterThan(textElements.count, 0, "Should extract some text elements")
        print("Extracted \(textElements.count) text elements and \(imageElements.count) image elements")
        
        // Test element sorting
        let sortedElements = elements.sorted { $0.bounds.minY > $1.bounds.minY }
        XCTAssertEqual(sortedElements.count, elements.count, "All elements should be present after sorting")
    }
    
    // MARK: - Integration Tests
    
    func testBasicConversion() async {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let outputPath = tempDir.appendingPathComponent("output.md")
        let assetsPath = tempDir.appendingPathComponent("assets")
        
        let converter = PDFMarkdownConverter(
            pdfURL: testPDFPath,
            outputPath: outputPath.path,
            assetsPath: assetsPath.path,
            dpi: 144.0
        )
        
        do {
            try await converter.convert()
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path), "Output file should exist")
            
            // Verify content
            let content = try String(contentsOf: outputPath)
            XCTAssertFalse(content.isEmpty, "Output content should not be empty")
            XCTAssertTrue(content.contains("pdf22md"), "Output should contain expected text")
            
            // Verify assets directory exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: assetsPath.path), "Assets directory should exist")
            
            // Count generated images
            let assetFiles = try FileManager.default.contentsOfDirectory(atPath: assetsPath.path)
            let imageFiles = assetFiles.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") }
            XCTAssertGreaterThan(imageFiles.count, 0, "Should generate some image files")
            
            print("Generated \(imageFiles.count) image files")
            
        } catch {
            XCTFail("Conversion failed with error: \(error)")
        }
    }
    
    func testOptimizedConversion() {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let outputPath = tempDir.appendingPathComponent("output-optimized.md")
        let assetsPath = tempDir.appendingPathComponent("assets-optimized")
        
        let converter = PDFMarkdownConverterOptimized(
            pdfURL: testPDFPath,
            outputPath: outputPath.path,
            assetsPath: assetsPath.path,
            dpi: 144.0
        )
        
        do {
            try converter.convert()
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path), "Optimized output file should exist")
            
            // Verify content
            let content = try String(contentsOf: outputPath)
            XCTAssertFalse(content.isEmpty, "Optimized output content should not be empty")
            
        } catch {
            XCTFail("Optimized conversion failed with error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let outputPath = tempDir.appendingPathComponent("perf-output.md")
        let assetsPath = tempDir.appendingPathComponent("perf-assets")
        
        measure {
            let converter = PDFMarkdownConverterOptimized(
                pdfURL: testPDFPath,
                outputPath: outputPath.path,
                assetsPath: assetsPath.path,
                dpi: 144.0
            )
            
            do {
                try converter.convert()
            } catch {
                XCTFail("Performance test conversion failed: \(error)")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidPDFHandling() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let invalidPath = tempDir.appendingPathComponent("nonexistent.pdf")
        let outputPath = tempDir.appendingPathComponent("error-output.md")
        
        let converter = PDFMarkdownConverter(
            pdfURL: invalidPath,
            outputPath: outputPath.path,
            assetsPath: nil,
            dpi: 144.0
        )
        
        do {
            try await converter.convert()
            XCTFail("Should have thrown an error for invalid PDF")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(true, "Correctly handled invalid PDF")
        }
    }
    
    func testInvalidOutputPathHandling() async {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }
        
        let invalidOutputPath = "/root/nonexistent/directory/output.md"
        
        let converter = PDFMarkdownConverter(
            pdfURL: testPDFPath,
            outputPath: invalidOutputPath,
            assetsPath: nil,
            dpi: 144.0
        )
        
        do {
            try await converter.convert()
            XCTFail("Should have thrown an error for invalid output path")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(true, "Correctly handled invalid output path")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyPDF() {
        // Create a minimal PDF with no content
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let emptyPDFPath = tempDir.appendingPathComponent("empty.pdf")
        let outputPath = tempDir.appendingPathComponent("empty-output.md")
        
        // Create minimal PDF data
        let pdfData = Data()
        
        do {
            try pdfData.write(to: emptyPDFPath)
            
            let converter = PDFMarkdownConverterOptimized(
                pdfURL: emptyPDFPath,
                outputPath: outputPath.path,
                assetsPath: nil,
                dpi: 144.0
            )
            
            try converter.convert()
            XCTFail("Should have thrown an error for empty PDF")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(true, "Correctly handled empty PDF")
        }
    }
    
    func testCustomDPI() async {
        guard let testPDFPath = getTestResourcePath("README.pdf") else {
            XCTFail("Could not find test PDF file")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("pdf22md-tests")
        let outputPath = tempDir.appendingPathComponent("custom-dpi-output.md")
        let assetsPath = tempDir.appendingPathComponent("custom-dpi-assets")

        let converter = PDFMarkdownConverter(
            pdfURL: testPDFPath,
            outputPath: outputPath.path,
            assetsPath: assetsPath.path,
            dpi: 300.0 // High DPI
        )

        do {
            try await converter.convert()

            // Verify output exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path), "Custom DPI output should exist")

            // Check if assets were created with higher quality
            let assetFiles = try FileManager.default.contentsOfDirectory(atPath: assetsPath.path)
            let imageFiles = assetFiles.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") }

            // Higher DPI should potentially create larger files
            if !imageFiles.isEmpty {
                let firstImagePath = assetsPath.appendingPathComponent(imageFiles[0])
                let imageData = try Data(contentsOf: firstImagePath)
                XCTAssertGreaterThan(imageData.count, 0, "Image should have data")
            }

        } catch {
            XCTFail("Custom DPI conversion failed: \(error)")
        }
    }

    // MARK: - API Configuration Tests

    func testAPIConfigurationParseValid() {
        // Test valid OpenAI format
        do {
            let config = try APIConfiguration.parse("gpt-4o:sk-xxx123@https://api.openai.com/v1")
            XCTAssertEqual(config.model, "gpt-4o")
            XCTAssertEqual(config.apiKey, "sk-xxx123")
            XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1")
        } catch {
            XCTFail("Failed to parse valid OpenAI config: \(error)")
        }

        // Test local Ollama format (empty API key)
        do {
            let config = try APIConfiguration.parse("llama3:@http://localhost:11434/v1")
            XCTAssertEqual(config.model, "llama3")
            XCTAssertEqual(config.apiKey, "")
            XCTAssertEqual(config.baseURL.absoluteString, "http://localhost:11434/v1")
        } catch {
            XCTFail("Failed to parse valid Ollama config: \(error)")
        }

        // Test Anthropic format
        do {
            let config = try APIConfiguration.parse("claude-3-haiku:sk-ant-xxx@https://api.anthropic.com/v1")
            XCTAssertEqual(config.model, "claude-3-haiku")
            XCTAssertEqual(config.apiKey, "sk-ant-xxx")
            XCTAssertEqual(config.baseURL.absoluteString, "https://api.anthropic.com/v1")
        } catch {
            XCTFail("Failed to parse valid Anthropic config: \(error)")
        }
    }

    func testAPIConfigurationParseInvalid() {
        // Missing @ separator
        XCTAssertThrowsError(try APIConfiguration.parse("gpt-4o:sk-xxx")) { error in
            XCTAssertTrue(error is APIConfigurationError)
        }

        // Missing : separator
        XCTAssertThrowsError(try APIConfiguration.parse("gpt-4o@https://api.openai.com/v1")) { error in
            XCTAssertTrue(error is APIConfigurationError)
        }

        // Empty model name
        XCTAssertThrowsError(try APIConfiguration.parse(":sk-xxx@https://api.openai.com/v1")) { error in
            XCTAssertTrue(error is APIConfigurationError)
        }

        // Invalid URL
        XCTAssertThrowsError(try APIConfiguration.parse("gpt-4o:sk-xxx@not a valid url")) { error in
            XCTAssertTrue(error is APIConfigurationError)
        }
    }

    // MARK: - Text Selection Tests

    func testSelectBestTextPDFPreferred() {
        // PDF text is longer, should prefer PDF
        let (text, source) = AITextProcessor.selectBestText(
            pdfText: "This is a long PDF text with many words and content.",
            visionText: "Short OCR",
            threshold: 1.5
        )
        XCTAssertEqual(source, .pdfKit)
        XCTAssertEqual(text, "This is a long PDF text with many words and content.")
    }

    func testSelectBestTextVisionPreferred() {
        // Vision text is significantly longer (>50% more), should prefer Vision
        let (text, source) = AITextProcessor.selectBestText(
            pdfText: "Short",
            visionText: "This is a much longer OCR text with many more words and detailed content.",
            threshold: 1.5
        )
        XCTAssertEqual(source, .vision)
        XCTAssertEqual(text, "This is a much longer OCR text with many more words and detailed content.")
    }

    func testSelectBestTextNoVision() {
        // No Vision text available, should use PDF
        let (text, source) = AITextProcessor.selectBestText(
            pdfText: "PDF text only",
            visionText: nil,
            threshold: 1.5
        )
        XCTAssertEqual(source, .pdfKit)
        XCTAssertEqual(text, "PDF text only")
    }

    func testSelectBestTextEmptyVision() {
        // Empty Vision text, should use PDF
        let (text, source) = AITextProcessor.selectBestText(
            pdfText: "PDF text",
            visionText: "",
            threshold: 1.5
        )
        XCTAssertEqual(source, .pdfKit)
        XCTAssertEqual(text, "PDF text")
    }

    func testSelectBestTextVeryShortPDF() {
        // PDF is very short, Vision has reasonable content
        let (text, source) = AITextProcessor.selectBestText(
            pdfText: "Hi",
            visionText: "This page contains significant text content that was extracted via OCR.",
            threshold: 1.5
        )
        XCTAssertEqual(source, .vision)
        XCTAssertEqual(text, "This page contains significant text content that was extracted via OCR.")
    }

    // MARK: - Processing Options Tests

    func testProcessingOptionsDefault() {
        let options = ProcessingOptions.default
        XCTAssertFalse(options.fastMode)
        XCTAssertFalse(options.enableAI)
        XCTAssertEqual(options.dpi, 144.0)
        XCTAssertEqual(options.languages, ["en"])
        XCTAssertFalse(options.useFastRecognition)
        XCTAssertEqual(options.visionPreferenceThreshold, 1.5)
        XCTAssertNil(options.apiConfig)
    }

    func testProcessingOptionsFast() {
        let options = ProcessingOptions.fast
        XCTAssertTrue(options.fastMode)
    }

    func testProcessingOptionsCustom() {
        let options = ProcessingOptions(
            fastMode: true,
            enableAI: true,
            dpi: 300.0,
            languages: ["en", "fr", "de"],
            useFastRecognition: true,
            visionPreferenceThreshold: 2.0,
            apiConfig: nil
        )
        XCTAssertTrue(options.fastMode)
        XCTAssertTrue(options.enableAI)
        XCTAssertEqual(options.dpi, 300.0)
        XCTAssertEqual(options.languages, ["en", "fr", "de"])
        XCTAssertTrue(options.useFastRecognition)
        XCTAssertEqual(options.visionPreferenceThreshold, 2.0)
    }

    func testProcessingOptionsVerbose() {
        let options = ProcessingOptions(verbose: true)
        XCTAssertTrue(options.verbose)

        let defaultOptions = ProcessingOptions.default
        XCTAssertFalse(defaultOptions.verbose)
    }

    func testProcessingOptionsMaxPages() {
        let options = ProcessingOptions(maxPages: 5)
        XCTAssertEqual(options.maxPages, 5)

        let defaultOptions = ProcessingOptions.default
        XCTAssertNil(defaultOptions.maxPages)
    }

    func testProcessingOptionsThreshold() {
        let options = ProcessingOptions(visionPreferenceThreshold: 2.5)
        XCTAssertEqual(options.visionPreferenceThreshold, 2.5)

        let defaultOptions = ProcessingOptions.default
        XCTAssertEqual(defaultOptions.visionPreferenceThreshold, 1.5)
    }

    // MARK: - ChatMessage Tests

    func testChatMessageSystem() {
        let message = ChatMessage.system("You are helpful.")
        XCTAssertEqual(message.role, "system")
        XCTAssertEqual(message.content, "You are helpful.")
    }

    func testChatMessageUser() {
        let message = ChatMessage.user("Hello!")
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello!")
    }

    func testChatMessageAssistant() {
        let message = ChatMessage.assistant("Hi there!")
        XCTAssertEqual(message.role, "assistant")
        XCTAssertEqual(message.content, "Hi there!")
    }

    // MARK: - ChatCompletionRequest Tests

    func testChatCompletionRequestEncoding() throws {
        let messages = [
            ChatMessage.system("You are helpful."),
            ChatMessage.user("Hello!")
        ]
        let request = ChatCompletionRequest(
            model: "gpt-4o",
            messages: messages,
            temperature: 0.7,
            maxTokens: 100
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["model"] as? String, "gpt-4o")
        XCTAssertEqual(json?["temperature"] as? Double, 0.7)
        XCTAssertEqual(json?["max_tokens"] as? Int, 100)

        let encodedMessages = json?["messages"] as? [[String: String]]
        XCTAssertEqual(encodedMessages?.count, 2)
        XCTAssertEqual(encodedMessages?[0]["role"], "system")
        XCTAssertEqual(encodedMessages?[1]["role"], "user")
    }

    // MARK: - ChatCompletionResponse Tests

    func testChatCompletionResponseDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4o",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello! How can I help?"
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 9,
                "completion_tokens": 12,
                "total_tokens": 21
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)

        XCTAssertEqual(response.id, "chatcmpl-123")
        XCTAssertEqual(response.model, "gpt-4o")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "Hello! How can I help?")
        XCTAssertEqual(response.choices[0].finish_reason, "stop")
        XCTAssertEqual(response.usage?.total_tokens, 21)
    }

    func testChatCompletionResponseMinimal() throws {
        // Minimal response (some APIs return fewer fields)
        let json = """
        {
            "choices": [{
                "index": 0,
                "message": {
                    "content": "Response text"
                }
            }]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)

        XCTAssertNil(response.id)
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "Response text")
    }

    // MARK: - OpenAIClient Initialization Tests

    func testOpenAIClientInit() {
        let client = OpenAIClient(
            baseURL: URL(string: "https://api.openai.com/v1")!,
            apiKey: "sk-test",
            model: "gpt-4o"
        )

        XCTAssertEqual(client.baseURL.absoluteString, "https://api.openai.com/v1")
        XCTAssertEqual(client.apiKey, "sk-test")
        XCTAssertEqual(client.model, "gpt-4o")
        XCTAssertEqual(client.timeout, 60.0)
        XCTAssertEqual(client.temperature, 0.3)
        XCTAssertEqual(client.maxRetries, 2)
    }

    func testOpenAIClientFromConfig() throws {
        let config = try APIConfiguration.parse("gpt-4o:sk-xxx@https://api.openai.com/v1")
        let client = OpenAIClient(config: config)

        XCTAssertEqual(client.model, "gpt-4o")
        XCTAssertEqual(client.apiKey, "sk-xxx")
        XCTAssertEqual(client.baseURL.absoluteString, "https://api.openai.com/v1")
    }

    func testOpenAIClientConvenienceOpenAI() {
        let client = OpenAIClient.openAI(apiKey: "sk-test", model: "gpt-4o-mini")

        XCTAssertEqual(client.baseURL.absoluteString, "https://api.openai.com/v1")
        XCTAssertEqual(client.apiKey, "sk-test")
        XCTAssertEqual(client.model, "gpt-4o-mini")
    }

    func testOpenAIClientConvenienceOllama() {
        let client = OpenAIClient.ollama(model: "llama3")

        XCTAssertEqual(client.baseURL.absoluteString, "http://localhost:11434/v1")
        XCTAssertEqual(client.apiKey, "")
        XCTAssertEqual(client.model, "llama3")
    }

    // MARK: - OpenAIClientError Tests

    func testOpenAIClientErrorDescriptions() {
        XCTAssertEqual(
            OpenAIClientError.invalidURL.errorDescription,
            "Invalid API URL"
        )
        XCTAssertEqual(
            OpenAIClientError.timeout.errorDescription,
            "Request timed out"
        )
        XCTAssertEqual(
            OpenAIClientError.emptyContent.errorDescription,
            "Empty content in response"
        )
        XCTAssertEqual(
            OpenAIClientError.noResponse.errorDescription,
            "No response from API"
        )
        XCTAssertEqual(
            OpenAIClientError.httpError(statusCode: 404, message: "Not found").errorDescription,
            "HTTP 404: Not found"
        )
        XCTAssertEqual(
            OpenAIClientError.httpError(statusCode: 500, message: nil).errorDescription,
            "HTTP error: 500"
        )
        XCTAssertEqual(
            OpenAIClientError.rateLimited(retryAfter: 30).errorDescription,
            "Rate limited. Retry after 30 seconds"
        )
        XCTAssertEqual(
            OpenAIClientError.rateLimited(retryAfter: nil).errorDescription,
            "Rate limited"
        )
    }

    // MARK: - PageTextContent Tests

    func testPageTextContentBestTextPDFKit() {
        let content = PageTextContent(
            pageIndex: 0,
            pdfText: "PDF text",
            visionText: "Vision text",
            correctedText: nil,
            selectedSource: .pdfKit
        )
        XCTAssertEqual(content.bestText, "PDF text")
    }

    func testPageTextContentBestTextVision() {
        let content = PageTextContent(
            pageIndex: 0,
            pdfText: "PDF text",
            visionText: "Vision text",
            correctedText: nil,
            selectedSource: .vision
        )
        XCTAssertEqual(content.bestText, "Vision text")
    }

    func testPageTextContentBestTextAICorrected() {
        let content = PageTextContent(
            pageIndex: 0,
            pdfText: "PDF text",
            visionText: "Vision text",
            correctedText: "Corrected text",
            selectedSource: .aiCorrected
        )
        XCTAssertEqual(content.bestText, "Corrected text")
    }

    func testPageTextContentBestTextAIFallback() {
        // AI selected but no corrected text, should fall back to vision then pdf
        let content = PageTextContent(
            pageIndex: 0,
            pdfText: "PDF text",
            visionText: "Vision text",
            correctedText: nil,
            selectedSource: .aiCorrected
        )
        XCTAssertEqual(content.bestText, "Vision text")

        let content2 = PageTextContent(
            pageIndex: 0,
            pdfText: "PDF text",
            visionText: nil,
            correctedText: nil,
            selectedSource: .aiCorrected
        )
        XCTAssertEqual(content2.bestText, "PDF text")
    }

    // MARK: - AppleIntelligenceProcessor Tests

    func testAppleIntelligenceProcessorNotAvailable() {
        // Apple Intelligence is not available until macOS 26
        XCTAssertFalse(AppleIntelligenceProcessor.isAvailable)
    }

    func testAppleIntelligenceProcessorInit() {
        // Should be able to create instance even when unavailable
        let processor = AppleIntelligenceProcessor()
        XCTAssertNotNil(processor)
    }
}