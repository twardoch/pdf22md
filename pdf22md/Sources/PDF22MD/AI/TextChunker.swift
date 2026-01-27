import Foundation

public struct TextChunk {
    public let text: String
    public let chunkIndex: Int
    public let totalChunks: Int
    public let overlapStart: Int?
    public let overlapEnd: Int?
    
    public init(text: String, chunkIndex: Int, totalChunks: Int, overlapStart: Int? = nil, overlapEnd: Int? = nil) {
        self.text = text
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks
        self.overlapStart = overlapStart
        self.overlapEnd = overlapEnd
    }
}

public struct TextChunker {
    private let overlapPercentage: Double
    
    public init(overlapPercentage: Double = 0.15) {
        self.overlapPercentage = min(max(overlapPercentage, 0.0), 0.5)
    }
    
    public func chunk(_ text: String, into numChunks: Int) -> [TextChunk] {
        guard numChunks > 1 else {
            return [TextChunk(text: text, chunkIndex: 0, totalChunks: 1)]
        }
        
        let sentences = splitIntoSentences(text)
        guard !sentences.isEmpty else {
            return [TextChunk(text: text, chunkIndex: 0, totalChunks: 1)]
        }
        
        let sentencesPerChunk = max(1, sentences.count / numChunks)
        let overlapSentences = max(1, Int(Double(sentencesPerChunk) * overlapPercentage))
        
        var chunks: [TextChunk] = []
        var currentIndex = 0
        var chunkIndex = 0
        
        while currentIndex < sentences.count {
            let endIndex = min(currentIndex + sentencesPerChunk, sentences.count)
            let chunkSentences = Array(sentences[currentIndex..<endIndex])
            let chunkText = chunkSentences.joined(separator: " ")
            
            let overlapStart = chunkIndex > 0 ? overlapSentences : nil
            let overlapEnd = endIndex < sentences.count ? overlapSentences : nil
            
            chunks.append(TextChunk(
                text: chunkText,
                chunkIndex: chunkIndex,
                totalChunks: numChunks,
                overlapStart: overlapStart,
                overlapEnd: overlapEnd
            ))
            
            currentIndex = endIndex - (endIndex < sentences.count ? overlapSentences : 0)
            chunkIndex += 1
            
            if endIndex >= sentences.count {
                break
            }
        }
        
        return chunks
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            
            if sentenceEnders.contains(char.unicodeScalars.first!) {
                if let next = text[text.index(after: text.firstIndex(of: char)!)...].first,
                   next.isWhitespace || next.isNewline {
                    sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentSentence = ""
                }
            }
        }
        
        if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return sentences.filter { !$0.isEmpty }
    }
    
    public static func reassemble(_ chunks: [(chunk: TextChunk, response: String)]) -> String {
        guard !chunks.isEmpty else { return "" }
        
        if chunks.count == 1 {
            return chunks[0].response
        }
        
        var result = ""
        for (index, item) in chunks.enumerated() {
            let response = item.response
            
            if index == 0 {
                result = response
            } else {
                if let overlap = item.chunk.overlapStart {
                    let words = response.split(separator: " ")
                    let skipWords = min(overlap * 3, words.count / 4)
                    let deduplicated = words.dropFirst(skipWords).joined(separator: " ")
                    result += "\n\n" + deduplicated
                } else {
                    result += "\n\n" + response
                }
            }
        }
        
        return result
    }
}
