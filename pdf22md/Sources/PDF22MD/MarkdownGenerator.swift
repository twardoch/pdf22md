// this_file: pdf22md/Sources/PDF22MD/MarkdownGenerator.swift
import Foundation
import CoreGraphics

/// Generates Markdown output from extracted PDF elements
struct MarkdownGenerator {
    private let assetsPath: String?
    private let pdfBasename: String

    init(pdfURL: URL, assetsPath: String?) {
        self.pdfBasename = pdfURL.deletingPathExtension().lastPathComponent
        self.assetsPath = assetsPath
    }

    /// Generate markdown from PDF elements with font-based heading detection
    func generate(from elements: [PDFElement], fontStats: FontStatistics) -> String {
        var markdown = ""
        let assetExtractor = AssetExtractor(assetsPath: assetsPath, pdfBasename: pdfBasename)

        // Sort elements by page and vertical position
        let sortedElements = elements.sorted { lhs, rhs in
            if lhs.pageIndex != rhs.pageIndex {
                return lhs.pageIndex < rhs.pageIndex
            }
            // Sort top to bottom (flip Y coordinate)
            return lhs.bounds.origin.y > rhs.bounds.origin.y
        }

        var previousElement: PDFElement?

        for element in sortedElements {
            // Add page breaks
            if let prev = previousElement, prev.pageIndex != element.pageIndex {
                markdown += "\n---\n\n"
            }

            switch element {
            case let textElement as TextElement:
                let headingLevel = fontStats.headingLevel(for: textElement.fontSize)

                if headingLevel > 0 {
                    markdown += String(repeating: "#", count: headingLevel) + " "
                }

                var text = textElement.text

                // Apply formatting
                if textElement.isBold && textElement.isItalic {
                    text = "***\(text)***"
                } else if textElement.isBold {
                    text = "**\(text)**"
                } else if textElement.isItalic {
                    text = "*\(text)*"
                }

                markdown += text

                // Add appropriate spacing
                if headingLevel > 0 {
                    markdown += "\n\n"
                } else {
                    // Check if next element is on a new line
                    if let prev = previousElement as? TextElement,
                       abs(prev.bounds.origin.y - textElement.bounds.origin.y) > 5 {
                        markdown += "\n\n"
                    } else {
                        markdown += " "
                    }
                }

            case let imageElement as ImageElement:
                if let image = imageElement.image,
                   let imagePath = assetExtractor.saveImage(
                       image,
                       pageIndex: imageElement.pageIndex,
                       isVector: imageElement.isVectorSource
                   ) {
                    let altText = imageElement.isVectorSource ? "Vector graphic" : "Image"
                    markdown += "![\(altText)](\(imagePath))\n\n"
                }

            default:
                break
            }

            previousElement = element
        }

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generate markdown from enhanced extraction results (text strings + images)
    func generateEnhanced(
        texts: [String],
        imageElements: [ImageElement]
    ) -> String {
        var markdown = ""
        let assetExtractor = AssetExtractor(assetsPath: assetsPath, pdfBasename: pdfBasename)

        // Group images by page
        var imagesByPage: [Int: [ImageElement]] = [:]
        for image in imageElements {
            imagesByPage[image.pageIndex, default: []].append(image)
        }

        // Generate markdown for each page
        for (index, text) in texts.enumerated() {
            if index > 0 {
                markdown += "\n\n---\n\n"
            }

            // Add text content
            markdown += text

            // Add images for this page
            if let pageImages = imagesByPage[index] {
                for imageElement in pageImages {
                    if let image = imageElement.image,
                       let imagePath = assetExtractor.saveImage(
                           image,
                           pageIndex: imageElement.pageIndex,
                           isVector: imageElement.isVectorSource
                       ) {
                        let altText = imageElement.isVectorSource ? "Vector graphic" : "Image"
                        markdown += "\n\n![\(altText)](\(imagePath))"
                    }
                }
            }
        }

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
