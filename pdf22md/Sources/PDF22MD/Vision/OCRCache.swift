// this_file: pdf22md/Sources/PDF22MD/Vision/OCRCache.swift

import Foundation
import CommonCrypto

/// Cache for OCR results to avoid re-processing unchanged PDFs
final class OCRCache {
    
    /// Cache entry metadata
    struct CacheMetadata: Codable {
        let pdfHash: String
        let pageIndex: Int
        let created: Date
        let dpi: Double
        let languages: [String]
    }
    
    /// Cached OCR result
    struct CachedResult: Codable {
        let metadata: CacheMetadata
        let text: String
        let resultCount: Int
    }
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    /// Initialize cache with default or custom directory
    /// - Parameter cacheDirectory: Custom cache directory (default: ~/.cache/pdf22md/ocr)
    init(cacheDirectory: URL? = nil) {
        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            let home = fileManager.homeDirectoryForCurrentUser
            self.cacheDirectory = home
                .appendingPathComponent(".cache")
                .appendingPathComponent("pdf22md")
                .appendingPathComponent("ocr")
        }
    }
    
    /// Get cached OCR text for a page if available
    /// - Parameters:
    ///   - pdfData: Raw PDF file data for hashing
    ///   - pageIndex: Page index (0-based)
    ///   - dpi: DPI used for OCR (must match)
    ///   - languages: Languages used for OCR (must match)
    /// - Returns: Cached text or nil if not cached
    func getCachedText(
        pdfData: Data,
        pageIndex: Int,
        dpi: Double,
        languages: [String]
    ) -> String? {
        let hash = sha256Hash(data: pdfData)
        let cacheFile = cacheFilePath(hash: hash, pageIndex: pageIndex)
        
        guard fileManager.fileExists(atPath: cacheFile.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheFile)
            let result = try JSONDecoder().decode(CachedResult.self, from: data)
            
            // Verify parameters match
            guard result.metadata.dpi == dpi,
                  result.metadata.languages == languages else {
                return nil
            }
            
            return result.text
        } catch {
            // Cache corrupted, return nil
            return nil
        }
    }
    
    /// Cache OCR text for a page
    /// - Parameters:
    ///   - text: OCR extracted text
    ///   - resultCount: Number of text results
    ///   - pdfData: Raw PDF file data for hashing
    ///   - pageIndex: Page index (0-based)
    ///   - dpi: DPI used for OCR
    ///   - languages: Languages used for OCR
    func cacheText(
        _ text: String,
        resultCount: Int,
        pdfData: Data,
        pageIndex: Int,
        dpi: Double,
        languages: [String]
    ) {
        let hash = sha256Hash(data: pdfData)
        let cacheFile = cacheFilePath(hash: hash, pageIndex: pageIndex)
        
        let metadata = CacheMetadata(
            pdfHash: hash,
            pageIndex: pageIndex,
            created: Date(),
            dpi: dpi,
            languages: languages
        )
        
        let result = CachedResult(
            metadata: metadata,
            text: text,
            resultCount: resultCount
        )
        
        do {
            // Create directory if needed
            let directory = cacheFile.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            
            // Write cache file
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(result)
            try data.write(to: cacheFile)
        } catch {
            // Silently fail - caching is optional optimization
        }
    }
    
    /// Clear all cached OCR results
    func clearCache() throws {
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
        }
    }
    
    /// Clear cached results for a specific PDF
    /// - Parameter pdfData: PDF data to identify cache entries
    func clearCache(for pdfData: Data) throws {
        let hash = sha256Hash(data: pdfData)
        let hashDirectory = cacheDirectory.appendingPathComponent(hash)
        
        if fileManager.fileExists(atPath: hashDirectory.path) {
            try fileManager.removeItem(at: hashDirectory)
        }
    }
    
    /// Get cache size in bytes
    var cacheSize: Int64 {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return 0
        }
        
        var size: Int64 = 0
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
    
    // MARK: - Private
    
    /// Build the on-disk cache path for one OCR'd page.
    ///
    /// Layout: `<cacheDir>/<sha256(pdfData)>/page_NNNN.json`. The cache key is the
    /// SHA-256 of the *entire* PDF file, so cache invalidation is content-addressed:
    /// editing the PDF by even one byte yields a different hash and therefore a fresh
    /// cache namespace — stale entries are never served, only orphaned (clear them
    /// with `clearCache()`). Note the DPI and OCR languages are recorded in each
    /// entry's metadata but are *not* part of the key, so re-OCRing the same PDF at a
    /// different DPI reuses the existing per-page files rather than regenerating them.
    private func cacheFilePath(hash: String, pageIndex: Int) -> URL {
        cacheDirectory
            .appendingPathComponent(hash)
            .appendingPathComponent("page_\(String(format: "%04d", pageIndex)).json")
    }
    
    private func sha256Hash(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
