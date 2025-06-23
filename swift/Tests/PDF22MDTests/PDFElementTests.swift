import XCTest
import CoreGraphics
@testable import PDF22MD

final class PDFElementTests: XCTestCase {
    
    func testTextElementCreation() {
        let text = "Hello, World!"
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 20)
        let element = TextElement(
            text: text,
            bounds: bounds,
            pageIndex: 0,
            fontSize: 12.0,
            isBold: true,
            isItalic: false
        )
        
        XCTAssertEqual(element.text, text)
        XCTAssertEqual(element.bounds, bounds)
        XCTAssertEqual(element.pageIndex, 0)
        XCTAssertEqual(element.fontSize, 12.0)
        XCTAssertTrue(element.isBold)
        XCTAssertFalse(element.isItalic)
    }
    
    func testImageElementCreation() {
        // Create a simple test image
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ), let image = context.makeImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let element = ImageElement(
            image: image,
            bounds: bounds,
            pageIndex: 1,
            isVectorSource: true
        )
        
        XCTAssertEqual(element.bounds, bounds)
        XCTAssertEqual(element.pageIndex, 1)
        XCTAssertTrue(element.isVectorSource)
        XCTAssertEqual(element.image.width, width)
        XCTAssertEqual(element.image.height, height)
    }
}