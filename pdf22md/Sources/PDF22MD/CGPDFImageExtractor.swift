import Foundation
import PDFKit
import CoreGraphics

/// Utility responsible for extracting raster images from a PDF page.
/// Extracts actual embedded images from PDF XObject streams.
struct CGPDFImageExtractor {
    /// Extract raster images from `page`.
    /// - Parameters:
    ///   - page: PDFKit page to analyse.
    ///   - pageIndex: Zero-based page index – passed into resulting `ImageElement`s.
    ///   - dpi: Desired rasterisation DPI (not used for embedded images, kept for API compatibility).
    /// - Returns: Array of `ImageElement`s ready for markdown generator.
    static func extractImages(from page: PDFPage,
                              pageIndex: Int,
                              dpi: CGFloat = 144.0) -> [ImageElement] {
        var elements: [ImageElement] = []
        
        // Get the underlying CGPDFPage
        guard let cgPage = page.pageRef else { return elements }
        
        // Extract images from XObject dictionary
        elements.append(contentsOf: extractXObjectImages(from: cgPage, pageIndex: pageIndex))
        
        return elements
    }

    // MARK: - XObject Image Extraction
    
    private static func extractXObjectImages(from cgPage: CGPDFPage, pageIndex: Int) -> [ImageElement] {
        var elements: [ImageElement] = []
        
        // Get page dictionary
        guard let pageDict = cgPage.dictionary else { return elements }
        
        // Get Resources dictionary
        var resDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resDict),
              let resources = resDict else { return elements }
        
        // Get XObject dictionary
        var xObjDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjDict),
              let xObject = xObjDict else { return elements }
        
        // Iterate through XObject entries
        CGPDFDictionaryApplyBlock(xObject, { keyPtr, object, _ in
            // Object name is available if needed for debugging
            // let objectName = String(cString: keyPtr)
            
            // Check if it's a stream
            var streamRef: CGPDFStreamRef?
            guard CGPDFObjectGetValue(object, .stream, &streamRef),
                  let stream = streamRef,
                  let streamDict = CGPDFStreamGetDictionary(stream) else {
                return true // continue iteration
            }
            
            // Check if it's an Image subtype
            var subtypePtr: UnsafePointer<Int8>?
            CGPDFDictionaryGetName(streamDict, "Subtype", &subtypePtr)
            guard let subtype = subtypePtr,
                  String(cString: subtype) == "Image" else {
                return true // continue iteration
            }
            
            // Extract image data
            var format = CGPDFDataFormat.raw
            guard let cfData = CGPDFStreamCopyData(stream, &format) else {
                return true // continue iteration
            }
            
            let imageData = cfData as Data
            
            // Try to create CGImage based on format
            if let cgImage = createImage(from: imageData, format: format, streamDict: streamDict) {
                // Get image bounds (use width/height from stream dictionary)
                let bounds = getImageBounds(from: streamDict)
                
                let element = ImageElement(
                    image: cgImage,
                    bounds: bounds,
                    pageIndex: pageIndex,
                    isVectorSource: false
                )
                elements.append(element)
            }
            
            return true // continue iteration
        }, nil)
        
        return elements
    }
    
    private static func createImage(from data: Data, format: CGPDFDataFormat, streamDict: CGPDFDictionaryRef) -> CGImage? {
        switch format {
        case .jpegEncoded:
            // JPEG data can be used directly
            return CGImage(jpegDataProviderSource: CGDataProvider(data: data as CFData)!,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
            
        case .JPEG2000:
            // For JPEG2000, we can try to create an image from the data
            // Note: This might not work on all systems
            if let dataProvider = CGDataProvider(data: data as CFData),
               let source = CGImageSourceCreateWithDataProvider(dataProvider, nil),
               CGImageSourceGetCount(source) > 0 {
                return CGImageSourceCreateImageAtIndex(source, 0, nil)
            }
            return nil
            
        case .raw:
            // For raw data, we need to read image properties from the stream dictionary
            return createImageFromRawData(data, streamDict: streamDict)
            
        @unknown default:
            return nil
        }
    }
    
    private static func createImageFromRawData(_ data: Data, streamDict: CGPDFDictionaryRef) -> CGImage? {
        // Get image dimensions
        var width: CGPDFInteger = 0
        var height: CGPDFInteger = 0
        guard CGPDFDictionaryGetInteger(streamDict, "Width", &width),
              CGPDFDictionaryGetInteger(streamDict, "Height", &height),
              width > 0, height > 0 else { return nil }
        
        // Get bits per component
        var bitsPerComponent: CGPDFInteger = 8
        CGPDFDictionaryGetInteger(streamDict, "BitsPerComponent", &bitsPerComponent)
        
        // For now, we'll assume RGB color space for simplicity
        // A full implementation would need to parse the ColorSpace entry
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = Int(width) * 4 // Assuming RGBA
        
        guard let dataProvider = CGDataProvider(data: data as CFData) else { return nil }
        
        return CGImage(
            width: Int(width),
            height: Int(height),
            bitsPerComponent: Int(bitsPerComponent),
            bitsPerPixel: Int(bitsPerComponent) * 4,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
    
    private static func getImageBounds(from streamDict: CGPDFDictionaryRef) -> CGRect {
        var width: CGPDFInteger = 0
        var height: CGPDFInteger = 0
        
        CGPDFDictionaryGetInteger(streamDict, "Width", &width)
        CGPDFDictionaryGetInteger(streamDict, "Height", &height)
        
        // PDF images don't have an origin, so we use zero
        return CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
    }
} 