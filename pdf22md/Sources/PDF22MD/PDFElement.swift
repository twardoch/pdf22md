import Foundation
import CoreGraphics

/// Protocol defining common properties for PDF content elements
protocol PDFElement {
    var bounds: CGRect { get }
    var pageIndex: Int { get }
}

/// Errors that can occur during PDF conversion
enum PDFConversionError: Error {
    case invalidPDF
    case fileNotFound
    case conversionFailed(String)
}

/// Represents a text element extracted from a PDF
struct TextElement: PDFElement {
    let text: String
    let bounds: CGRect
    let pageIndex: Int
    let fontSize: CGFloat
    let isBold: Bool
    let isItalic: Bool
    
    init(text: String, bounds: CGRect, pageIndex: Int, fontSize: CGFloat, isBold: Bool = false, isItalic: Bool = false) {
        self.text = text
        self.bounds = bounds
        self.pageIndex = pageIndex
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
    }
}

/// Represents an image element extracted from a PDF
struct ImageElement: PDFElement {
    let image: CGImage?
    let bounds: CGRect
    let pageIndex: Int
    let isVectorSource: Bool
    let path: String
    
    init(image: CGImage? = nil, bounds: CGRect, pageIndex: Int, isVectorSource: Bool = false, path: String = "") {
        self.image = image
        self.bounds = bounds
        self.pageIndex = pageIndex
        self.isVectorSource = isVectorSource
        self.path = path
    }
}