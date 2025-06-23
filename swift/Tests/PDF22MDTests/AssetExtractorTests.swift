import XCTest
import CoreGraphics
@testable import PDF22MD

final class AssetExtractorTests: XCTestCase {
    
    var tempDirectory: String!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path
        try? FileManager.default.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempDirectory)
        super.tearDown()
    }
    
    func testAssetExtractorCreatesDirectory() {
        let assetsPath = (tempDirectory as NSString).appendingPathComponent("assets")
        _ = AssetExtractor(assetsPath: assetsPath)
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: assetsPath, isDirectory: &isDirectory)
        
        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
    }
    
    func testSaveImageAsPNG() {
        let assetsPath = tempDirectory
        let extractor = AssetExtractor(assetsPath: assetsPath)
        
        // Create a small test image (should be saved as PNG)
        guard let image = createTestImage(width: 100, height: 100, hasAlpha: true) else {
            XCTFail("Failed to create test image")
            return
        }
        
        let filename = extractor.saveImage(image, isVector: false)
        XCTAssertNotNil(filename)
        XCTAssertTrue(filename!.hasSuffix(".png"))
        
        // Verify file exists
        let filePath = (assetsPath as NSString).appendingPathComponent(filename!)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath))
    }
    
    func testSaveImageAsJPEG() {
        let assetsPath = tempDirectory
        let extractor = AssetExtractor(assetsPath: assetsPath)
        
        // Create a large test image without alpha (should be saved as JPEG)
        guard let image = createTestImage(width: 500, height: 500, hasAlpha: false) else {
            XCTFail("Failed to create test image")
            return
        }
        
        let filename = extractor.saveImage(image, isVector: false)
        XCTAssertNotNil(filename)
        XCTAssertTrue(filename!.hasSuffix(".jpg"))
    }
    
    func testImageCounter() {
        let assetsPath = tempDirectory
        let extractor = AssetExtractor(assetsPath: assetsPath)
        
        guard let image = createTestImage(width: 100, height: 100) else {
            XCTFail("Failed to create test image")
            return
        }
        
        let filename1 = extractor.saveImage(image, isVector: false)
        let filename2 = extractor.saveImage(image, isVector: false)
        
        XCTAssertEqual(filename1, "image_001.png")
        XCTAssertEqual(filename2, "image_002.png")
    }
    
    private func createTestImage(width: Int, height: Int, hasAlpha: Bool = false) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let alphaInfo: CGImageAlphaInfo = hasAlpha ? .premultipliedLast : .noneSkipLast
        let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        // Fill with a color
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
}