import Foundation

public struct ParagraphChunker {
    
    public let maxChunkSize: Int
    public let minChunkSize: Int
    
    public init(maxChunkSize: Int = 3500, minChunkSize: Int = 200) {
        self.maxChunkSize = maxChunkSize
        self.minChunkSize = minChunkSize
    }
    
    public struct Chunk {
        public let text: String
        public let index: Int
        public let isLast: Bool
        
        public init(text: String, index: Int, isLast: Bool) {
            self.text = text
            self.index = index
            self.isLast = isLast
        }
    }
    
    public func chunk(_ text: String) -> [Chunk] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        if trimmed.count <= maxChunkSize {
            return [Chunk(text: trimmed, index: 0, isLast: true)]
        }
        
        let paragraphs = trimmed.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var chunks: [Chunk] = []
        var currentChunk = ""
        var chunkIndex = 0
        
        for paragraph in paragraphs {
            if currentChunk.count + paragraph.count + 2 > maxChunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(Chunk(text: currentChunk, index: chunkIndex, isLast: false))
                    chunkIndex += 1
                    currentChunk = ""
                }
                
                if paragraph.count > maxChunkSize {
                    let subChunks = splitLargeParagraph(paragraph)
                    for (i, subChunk) in subChunks.enumerated() {
                        if i == subChunks.count - 1 {
                            currentChunk = subChunk
                        } else {
                            chunks.append(Chunk(text: subChunk, index: chunkIndex, isLast: false))
                            chunkIndex += 1
                        }
                    }
                } else {
                    currentChunk = paragraph
                }
            } else {
                if currentChunk.isEmpty {
                    currentChunk = paragraph
                } else {
                    currentChunk += "\n\n" + paragraph
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(Chunk(text: currentChunk, index: chunkIndex, isLast: true))
        }
        
        if var last = chunks.popLast() {
            last = Chunk(text: last.text, index: last.index, isLast: true)
            chunks.append(last)
        }
        
        return chunks
    }
    
    private func splitLargeParagraph(_ paragraph: String) -> [String] {
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        var current = ""
        
        for char in paragraph {
            current.append(char)
            if let scalar = char.unicodeScalars.first, sentenceEnders.contains(scalar) {
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        if !current.isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespaces))
        }
        
        var chunks: [String] = []
        var currentChunk = ""
        
        for sentence in sentences {
            if currentChunk.count + sentence.count + 1 > maxChunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    currentChunk = ""
                }
                
                if sentence.count > maxChunkSize {
                    let wordChunks = splitByWords(sentence)
                    chunks.append(contentsOf: wordChunks.dropLast())
                    currentChunk = wordChunks.last ?? ""
                } else {
                    currentChunk = sentence
                }
            } else {
                if currentChunk.isEmpty {
                    currentChunk = sentence
                } else {
                    currentChunk += " " + sentence
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    private func splitByWords(_ text: String) -> [String] {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var chunks: [String] = []
        var currentChunk = ""
        
        for word in words {
            if currentChunk.count + word.count + 1 > maxChunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = word
            } else {
                if currentChunk.isEmpty {
                    currentChunk = word
                } else {
                    currentChunk += " " + word
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    public func reassemble(_ chunks: [Chunk]) -> String {
        chunks.sorted { $0.index < $1.index }
            .map { $0.text }
            .joined(separator: "\n\n")
    }
}
