import Foundation
import PDFKit
import CoreGraphics

/// Utility responsible for extracting raster images from a PDF page using a best-effort heuristic.
///
/// Phase 1 implementation: look for image-like annotations (link, stamp, etc.) that have no text
/// and are reasonably big; render their bounds into a bitmap at the requested DPI.
/// This already captures embedded photos in most PDFs created by office software.
///
/// Later phases will add direct XObject scanning for perfect coverage.
struct CGPDFImageExtractor {
    /// Extract raster images from `page`.
    /// - Parameters:
    ///   - page: PDFKit page to analyse.
    ///   - pageIndex: Zero-based page index – passed into resulting `ImageElement`s.
    ///   - dpi: Desired rasterisation DPI (defaults to 144 the same as vector capture).
    /// - Returns: Array of `ImageElement`s ready for markdown generator.
    static func extractImages(from page: PDFPage,
                              pageIndex: Int,
                              dpi: CGFloat = 144.0) -> [ImageElement] {
        var elements: [ImageElement] = []

        // 1. Scan annotations for potential images.
        for annotation in page.annotations {
            guard annotationMayContainImage(annotation) else { continue }
            if let img = render(annotation: annotation, on: page, dpi: dpi) {
                let element = ImageElement(image: img,
                                           bounds: annotation.bounds,
                                           pageIndex: pageIndex,
                                           isVectorSource: false)
                elements.append(element)
            }
        }

        // 2. (Future) Scan XObject dictionary here.

        return elements
    }

    // MARK: - Private helpers

    private static func annotationMayContainImage(_ annotation: PDFAnnotation) -> Bool {
        let bounds = annotation.bounds
        // Ignore tiny icons/logo-like annotations.
        // Require both dimensions ≥ 50 pt **and** area ≥ 5 000 pt² to treat as a photo.
        guard bounds.width >= 50, bounds.height >= 50, (bounds.width * bounds.height) >= 5000 else {
            return false
        }

        // If the annotation carries any textual contents we treat it as non-image.
        if let contents = annotation.contents, !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }

    private static func render(annotation: PDFAnnotation,
                               on page: PDFPage,
                               dpi: CGFloat) -> CGImage? {
        let bounds = annotation.bounds
        let scale = dpi / 72.0
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        guard width > 0, height > 0, width <= 4096, height <= 4096 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: 0,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }

        // White background so transparent images look OK.
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        page.draw(with: .mediaBox, to: ctx)

        guard let cgImage = ctx.makeImage() else { return nil }
        // Filter out blank/white images (e.g. empty pages or whitespace boxes)
        if isMostlyWhite(cgImage) {
            return nil
        }
        return cgImage
    }

    /// Quick heuristic: returns true when >99% pixels have brightness > 0.97 (near white).
    private static func isMostlyWhite(_ image: CGImage) -> Bool {
        guard let dataProvider = image.dataProvider,
              let cfData = dataProvider.data,
              let ptr = CFDataGetBytePtr(cfData) else { return false }

        let bytesPerPixel = image.bitsPerPixel / 8
        guard bytesPerPixel >= 3 else { return false }

        let width = image.width
        let height = image.height
        let totalPixels = width * height
        var whiteCount = 0
        let step = max(1, totalPixels / 10000) // sample at most 10k pixels

        for i in stride(from: 0, to: totalPixels, by: step) {
            let offset = i * bytesPerPixel
            let r = ptr[offset]
            let g = ptr[offset + 1]
            let b = ptr[offset + 2]
            // consider pixel white if all channels > 245 (out of 255)
            if r > 245 && g > 245 && b > 245 {
                whiteCount += 1
            }
        }

        let samplePixels = totalPixels / step
        return Double(whiteCount) / Double(samplePixels) > 0.99
    }
} 