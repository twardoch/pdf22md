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
    
    /// Save an image asset and return the (relative) path to be used in Markdown.
    ///
    /// The returned string now always contains the **assets directory prefix** so that
    /// generated Markdown references point to the actual file location, e.g.
    /// `assets/report-001-01.png`.
    /// - Note: If the provided `assetsPath` is absolute, the absolute path is returned.
    ///         If it is relative (e.g. `./assets` or `assets`), the same relative prefix
    ///         will be included in the returned value.
    func saveImage(_ image: CGImage, pageIndex: Int, isVector: Bool) -> String? {
        guard let assetsPath = assetsPath else { return nil }
        
        // Increment asset counter for the current page
        let assetNumber = (pageImageCounts[pageIndex] ?? 0) + 1
        pageImageCounts[pageIndex] = assetNumber
        
        // Decide on output format
        let format = shouldUsePNG(for: image) ? "png" : "jpg"
        
        // Construct file name: <basename>-<page>-<asset>.<ext>
        let fileName = String(
            format: "%@-%03d-%02d.%@",
            pdfBasename,
            pageIndex + 1,
            assetNumber,
            format
        )
        
        // Full filesystem path where the image will be saved
        let filePath = (assetsPath as NSString).appendingPathComponent(fileName)
        
        // Persist the image to disk
        let saved: Bool = format == "png" ? savePNG(image, to: filePath) : saveJPEG(image, to: filePath)
        
        guard saved else { return nil }
        
        // Return the path that should be placed in Markdown. Prefer a *relative* path
        // when the assets directory itself is relative; otherwise fall back to absolute.
        if (assetsPath as NSString).isAbsolutePath {
            return filePath
        } else {
            // Remove leading "./" if present for cleaner Markdown
            let cleanedAssetsPath = assetsPath.hasPrefix("./") ? String(assetsPath.dropFirst(2)) : assetsPath
            return (cleanedAssetsPath as NSString).appendingPathComponent(fileName)
        }
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