// this_file: pdf22md/Sources/PDF22MD/VectorGraphicsExtractor.swift
import Foundation
import PDFKit
import CoreGraphics

struct VectorGraphicsExtractor {
    private let pdfPage: PDFPage
    private let pageIndex: Int
    private let dpi: CGFloat

    init(page: PDFPage, pageIndex: Int, dpi: CGFloat = 144.0) {
        self.pdfPage = page
        self.pageIndex = pageIndex
        self.dpi = dpi
    }

    func extractElements() -> [ImageElement] {
        var elements: [ImageElement] = []
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let sectionSize: CGFloat = 200.0
        
        let textBounds = extractTextBounds()

        let gridX = Int(ceil(pageRect.size.width / sectionSize))
        let gridY = Int(ceil(pageRect.size.height / sectionSize))

        for x in 0..<gridX {
            for y in 0..<gridY {
                var sectionRect = CGRect(
                    x: CGFloat(x) * sectionSize,
                    y: CGFloat(y) * sectionSize,
                    width: sectionSize,
                    height: sectionSize
                )

                sectionRect = sectionRect.intersection(pageRect)
                if sectionRect.isEmpty || sectionRect.size.width < 40 || sectionRect.size.height < 40 {
                    continue
                }
                
                if overlapsTextRegion(sectionRect, textBounds: textBounds) {
                    continue
                }

                if sectionContainsNonTextContent(sectionRect) {
                    if let sectionImage = renderSection(sectionRect) {
                        elements.append(ImageElement(
                            image: sectionImage,
                            bounds: sectionRect,
                            pageIndex: pageIndex,
                            isVectorSource: true
                        ))
                    }
                }
            }
        }

        return elements
    }
    
    private func extractTextBounds() -> [CGRect] {
        var bounds: [CGRect] = []
        
        for pageNum in 0..<pdfPage.numberOfCharacters {
            let charBounds = pdfPage.characterBounds(at: pageNum)
            if !charBounds.isEmpty {
                bounds.append(charBounds)
            }
        }
        
        return mergeOverlappingRects(bounds)
    }
    
    private func mergeOverlappingRects(_ rects: [CGRect], threshold: CGFloat = 10.0) -> [CGRect] {
        guard !rects.isEmpty else { return [] }
        
        var merged: [CGRect] = []
        var current = rects[0]
        
        for rect in rects.dropFirst() {
            if current.insetBy(dx: -threshold, dy: -threshold).intersects(rect) {
                current = current.union(rect)
            } else {
                merged.append(current)
                current = rect
            }
        }
        merged.append(current)
        
        return merged
    }
    
    private func overlapsTextRegion(_ rect: CGRect, textBounds: [CGRect]) -> Bool {
        for textRect in textBounds {
            if rect.intersects(textRect.insetBy(dx: -20, dy: -20)) {
                return true
            }
        }
        return false
    }

    private func sectionContainsNonTextContent(_ rect: CGRect) -> Bool {
        guard let selection = pdfPage.selection(for: rect) else { return true }
        let text = selection.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.count < 20
    }

    private func renderSection(_ rect: CGRect) -> CGImage? {
        let scale = dpi / 72.0
        let scaledSize = CGSize(width: rect.size.width * scale, height: rect.size.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: scaledSize))
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -rect.origin.x, y: -rect.origin.y)
        pdfPage.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }
}
