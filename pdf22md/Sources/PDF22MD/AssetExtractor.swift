import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Handles extraction and saving of image assets from PDFs
final class AssetExtractor {
    private let assetsPath: String?
    private let pdfBasename: String
    private var pageImageCounts: [Int: Int] = [:]
    private let fileManager = FileManager.default
    
    init(assetsPath: String?, pdfBasename: String) {
        self.assetsPath = assetsPath
        self.pdfBasename = pdfBasename
        
        // Create assets directory if specified and valid
        if let path = assetsPath, !path.isEmpty {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }
    
    /// Save an image asset and return the relative path for markdown reference
    func saveImage(_ image: CGImage, pageIndex: Int, isVector: Bool) -> String? {
        guard let assetsPath = assetsPath else { return nil }
        
        // Get or initialize count for this page
        let assetNumber = (pageImageCounts[pageIndex] ?? 0) + 1
        pageImageCounts[pageIndex] = assetNumber
        
        // Determine format based on image characteristics
        let format = shouldUsePNG(for: image) ? "png" : "jpg"
        
        // Create filename: basename-pagenumber-assetnumber.ext
        let fileName = String(format: "%@-%03d-%02d.%@", 
                            pdfBasename, 
                            pageIndex + 1,  // Convert to 1-based page numbering
                            assetNumber, 
                            format)
        let filePath = (assetsPath as NSString).appendingPathComponent(fileName)
        
        // Save the image
        let saved = format == "png" 
            ? savePNG(image, to: filePath)
            : saveJPEG(image, to: filePath)
        
        return saved ? fileName : nil
    }
    
    private func shouldUsePNG(for image: CGImage) -> Bool {
        // Use PNG if image has alpha channel
        if let alphaInfo = CGImageAlphaInfo(rawValue: image.alphaInfo.rawValue),
           alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast {
            return true
        }
        
        // Use PNG for small images (likely icons/graphics)
        if image.width < 300 || image.height < 300 {
            return true
        }
        
        // Use PNG for images with few colors (likely graphics)
        // This is a simplified heuristic
        if image.bitsPerPixel <= 8 {
            return true
        }
        
        return false
    }
    
    private func savePNG(_ image: CGImage, to path: String) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            URL(fileURLWithPath: path) as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return false }
        
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }
    
    private func saveJPEG(_ image: CGImage, to path: String) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            URL(fileURLWithPath: path) as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return false }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.85
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
}