#!/usr/bin/env swift

import Foundation
import PDFKit
import CoreGraphics
import CoreText

// Create a test PDF with proper content rendering
func createTestPDF(pages: Int, filename: String, includeImages: Bool = false) {
    let pdfDoc = PDFDocument()
    
    for pageNum in 0..<pages {
        // Create page with US Letter dimensions
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        // Create PDF context for the page
        let pdfData = NSMutableData()
        var mutableBounds = pageBounds
        guard let dataConsumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: dataConsumer, mediaBox: &mutableBounds, nil) else {
            continue
        }
        
        // Begin PDF page
        let pageDict: [String: Any] = [:]
        pdfContext.beginPDFPage(pageDict as CFDictionary?)
        
        // Save the graphics state
        pdfContext.saveGState()
        
        // Flip coordinate system
        pdfContext.translateBy(x: 0, y: pageBounds.height)
        pdfContext.scaleBy(x: 1.0, y: -1.0)
        
        var yPosition: CGFloat = 50
        
        // Draw title
        drawText(context: pdfContext, text: "Page \(pageNum + 1) - Document Title", 
                x: 50, y: yPosition, fontSize: 24, bold: true)
        yPosition += 40
        
        // Draw main heading
        drawText(context: pdfContext, text: "Chapter \(pageNum % 5 + 1): Section Heading", 
                x: 50, y: yPosition, fontSize: 18, bold: true)
        yPosition += 30
        
        // Draw subheading
        drawText(context: pdfContext, text: "Subsection \(pageNum % 3 + 1).1: Details", 
                x: 50, y: yPosition, fontSize: 14, bold: true)
        yPosition += 25
        
        // Draw body paragraphs with different styles
        let paragraphs = [
            "This is regular body text. Lorem ipsum dolor sit amet, consectetur adipiscing elit. " +
            "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            
            "This paragraph contains bold text that should be detected. " +
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
            
            "This paragraph uses italic styling for emphasis. " +
            "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.",
            
            "Mixed formatting: Regular text with bold sections and italic portions. " +
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia."
        ]
        
        for (index, paragraph) in paragraphs.enumerated() {
            let isBold = index == 1
            let isItalic = index == 2
            drawText(context: pdfContext, text: paragraph, x: 50, y: yPosition, 
                    fontSize: 12, bold: isBold, italic: isItalic, width: 512)
            yPosition += 60
        }
        
        // Add images if requested
        if includeImages && pageNum % 3 == 0 {
            // Draw a simple shape as an image
            drawShape(context: pdfContext, x: 50, y: yPosition, width: 200, height: 150)
            yPosition += 170
            
            // Draw another shape
            drawShape(context: pdfContext, x: 300, y: yPosition - 170, width: 150, height: 150, 
                     isCircle: true)
        }
        
        // Add some vector graphics (charts/diagrams)
        if pageNum % 4 == 0 {
            drawChart(context: pdfContext, x: 50, y: yPosition, width: 400, height: 200)
            yPosition += 220
        }
        
        // Restore graphics state
        pdfContext.restoreGState()
        
        // End PDF page
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        // Create PDFPage from data
        if let provider = CGDataProvider(data: pdfData),
           let pdfFromData = CGPDFDocument(provider),
           let cgPage = pdfFromData.page(at: 1) {
            let page = PDFPage()
            // PDFPage doesn't have an init with CGPDFPage in Swift, so we'll use the data
            if let pdfDocFromData = PDFDocument(data: pdfData as Data),
               let pageFromDoc = pdfDocFromData.page(at: 0) {
                pdfDoc.insert(pageFromDoc, at: pageNum)
            }
        }
    }
    
    // Write PDF to file
    let url = URL(fileURLWithPath: filename)
    pdfDoc.write(to: url)
    print("Created \(filename) with \(pages) pages")
}

// Helper function to draw text
func drawText(context: CGContext, text: String, x: CGFloat, y: CGFloat, 
              fontSize: CGFloat, bold: Bool = false, italic: Bool = false, width: CGFloat = 512) {
    let font: CTFont
    if bold && italic {
        font = CTFontCreateWithName("Helvetica-BoldOblique" as CFString, fontSize, nil)
    } else if bold {
        font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    } else if italic {
        font = CTFontCreateWithName("Helvetica-Oblique" as CFString, fontSize, nil)
    } else {
        font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
    }
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.black
    ]
    
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    
    let textPath = CGPath(rect: CGRect(x: x, y: y, width: width, height: 1000), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), textPath, nil)
    
    CTFrameDraw(frame, context)
}

// Helper function to draw shapes
func drawShape(context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, 
               isCircle: Bool = false) {
    context.saveGState()
    
    // Set fill color
    context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.7)
    context.setStrokeColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1.0)
    context.setLineWidth(2.0)
    
    if isCircle {
        context.addEllipse(in: CGRect(x: x, y: y, width: width, height: height))
    } else {
        context.addRect(CGRect(x: x, y: y, width: width, height: height))
    }
    
    context.drawPath(using: .fillStroke)
    context.restoreGState()
}

// Helper function to draw a simple chart
func drawChart(context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
    context.saveGState()
    
    // Draw axes
    context.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    context.setLineWidth(2.0)
    context.move(to: CGPoint(x: x, y: y + height))
    context.addLine(to: CGPoint(x: x, y: y))
    context.addLine(to: CGPoint(x: x + width, y: y))
    context.strokePath()
    
    // Draw bars
    let barWidth = width / 6
    let barSpacing = barWidth / 4
    let colors: [(CGFloat, CGFloat, CGFloat)] = [
        (0.8, 0.2, 0.2), (0.2, 0.8, 0.2), (0.2, 0.2, 0.8),
        (0.8, 0.8, 0.2), (0.8, 0.2, 0.8)
    ]
    
    for i in 0..<5 {
        let barHeight = CGFloat.random(in: 0.3...0.9) * height
        let barX = x + CGFloat(i) * (barWidth + barSpacing) + barSpacing
        
        context.setFillColor(red: colors[i].0, green: colors[i].1, blue: colors[i].2, alpha: 0.8)
        context.fill(CGRect(x: barX, y: y, width: barWidth, height: barHeight))
    }
    
    context.restoreGState()
}


// Create test directory
try? FileManager.default.createDirectory(atPath: "test", withIntermediateDirectories: true)

// Create test PDFs
createTestPDF(pages: 5, filename: "test/small.pdf")
createTestPDF(pages: 50, filename: "test/medium.pdf")
createTestPDF(pages: 200, filename: "test/large.pdf")
createTestPDF(pages: 20, filename: "test/images.pdf", includeImages: true)

print("Test PDFs created successfully!")