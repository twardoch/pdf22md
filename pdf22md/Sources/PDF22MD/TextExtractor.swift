// this_file: pdf22md/Sources/PDF22MD/TextExtractor.swift
import Foundation
import PDFKit
import AppKit

/// Extracts text elements from PDF pages using PDFKit
struct TextExtractor {
    private let pdfPage: PDFPage
    private let pageIndex: Int

    init(page: PDFPage, pageIndex: Int) {
        self.pdfPage = page
        self.pageIndex = pageIndex
    }

    /// Extract text elements with font and style information
    func extractElements() -> [TextElement] {
        var textElements: [TextElement] = []
        guard let pageContent = pdfPage.attributedString else { return textElements }

        let fullRange = NSRange(location: 0, length: pageContent.length)
        var currentPosition = 0

        while currentPosition < pageContent.length {
            var effectiveRange = NSRange()
            let attributes = pageContent.attributes(
                at: currentPosition,
                longestEffectiveRange: &effectiveRange,
                in: fullRange
            )

            let text = (pageContent.string as NSString).substring(with: effectiveRange)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if !trimmed.isEmpty {
                let font = attributes[.font] as? NSFont
                let fontSize = font?.pointSize ?? 12.0
                let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
                let isItalic = font?.fontDescriptor.symbolicTraits.contains(.italic) ?? false
                let bounds = getBounds(for: effectiveRange)

                let element = TextElement(
                    text: trimmed,
                    bounds: bounds,
                    pageIndex: pageIndex,
                    fontSize: fontSize,
                    isBold: isBold,
                    isItalic: isItalic
                )
                textElements.append(element)
            }

            let nextPosition = NSMaxRange(effectiveRange)
            currentPosition = nextPosition > currentPosition ? nextPosition : currentPosition + 1
        }

        return textElements
    }

    private func getBounds(for range: NSRange) -> CGRect {
        guard range.location != NSNotFound, range.length > 0 else { return .zero }
        let startBounds = pdfPage.characterBounds(at: range.location)
        let endBounds = pdfPage.characterBounds(at: NSMaxRange(range) - 1)
        return startBounds.union(endBounds)
    }
}
