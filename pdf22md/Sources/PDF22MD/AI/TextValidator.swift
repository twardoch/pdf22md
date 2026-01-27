import Foundation

public struct TextValidator {
    
    public let similarityThreshold: Double
    public let maxContentLoss: Double
    public let lengthRatioRange: ClosedRange<Double>
    
    public init(
        similarityThreshold: Double = 0.85,
        maxContentLoss: Double = 0.15,
        lengthRatioRange: ClosedRange<Double> = 0.7...1.3
    ) {
        self.similarityThreshold = similarityThreshold
        self.maxContentLoss = maxContentLoss
        self.lengthRatioRange = lengthRatioRange
    }
    
    public struct ValidationResult {
        public let isValid: Bool
        public let similarity: Double
        public let lengthRatio: Double
        public let reason: String?
        
        public static func valid(similarity: Double, lengthRatio: Double) -> ValidationResult {
            ValidationResult(isValid: true, similarity: similarity, lengthRatio: lengthRatio, reason: nil)
        }
        
        public static func invalid(similarity: Double, lengthRatio: Double, reason: String) -> ValidationResult {
            ValidationResult(isValid: false, similarity: similarity, lengthRatio: lengthRatio, reason: reason)
        }
    }
    
    public func validate(input: String, output: String) -> ValidationResult {
        if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .valid(similarity: 1.0, lengthRatio: 1.0)
            }
            return .invalid(similarity: 0.0, lengthRatio: 0.0, reason: "Empty output")
        }
        
        let lengthRatio = Double(output.count) / Double(max(input.count, 1))
        if !lengthRatioRange.contains(lengthRatio) {
            return .invalid(
                similarity: 0.0,
                lengthRatio: lengthRatio,
                reason: "Length ratio \(String(format: "%.2f", lengthRatio)) outside allowed range"
            )
        }
        
        let inputFreq = wordFrequencies(input)
        let outputFreq = wordFrequencies(output)
        let similarity = cosineSimilarity(inputFreq, outputFreq)
        
        if similarity < similarityThreshold {
            return .invalid(
                similarity: similarity,
                lengthRatio: lengthRatio,
                reason: "Similarity \(String(format: "%.2f", similarity)) below threshold \(similarityThreshold)"
            )
        }
        
        let inputTop = topWords(inputFreq, count: 5)
        let outputTop = topWords(outputFreq, count: 5)
        let topOverlap = Set(inputTop).intersection(Set(outputTop)).count
        
        if topOverlap < 2 && inputTop.count >= 3 {
            return .invalid(
                similarity: similarity,
                lengthRatio: lengthRatio,
                reason: "Top words mismatch"
            )
        }
        
        return .valid(similarity: similarity, lengthRatio: lengthRatio)
    }
    
    public func wordFrequencies(_ text: String) -> [String: Int] {
        var frequencies: [String: Int] = [:]
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
        
        for word in words {
            frequencies[word, default: 0] += 1
        }
        return frequencies
    }
    
    public func topWords(_ frequencies: [String: Int], count: Int) -> [String] {
        frequencies.sorted { $0.value > $1.value }
            .prefix(count)
            .map { $0.key }
    }
    
    public func cosineSimilarity(_ a: [String: Int], _ b: [String: Int]) -> Double {
        let allKeys = Set(a.keys).union(Set(b.keys))
        guard !allKeys.isEmpty else { return 1.0 }
        
        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        for key in allKeys {
            let aVal = Double(a[key] ?? 0)
            let bVal = Double(b[key] ?? 0)
            dotProduct += aVal * bVal
            normA += aVal * aVal
            normB += bVal * bVal
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0.0 }
        
        return dotProduct / denominator
    }
}
