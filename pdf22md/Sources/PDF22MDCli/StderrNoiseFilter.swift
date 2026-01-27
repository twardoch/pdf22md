import Foundation
import Darwin

struct StderrNoiseFilter {
    static let defaultPatterns = [
        "attributedStringScaled",
        "CoreText note",
        "CoreGraphics PDF"
    ]
}

struct StderrLineBuffer {
    private var buffer = Data()
    private let patterns: [String]
    private let newline = Data([0x0A])

    init(patterns: [String]) {
        self.patterns = patterns
    }

    mutating func consume(_ data: Data) -> [Data] {
        buffer.append(data)
        return drainLines()
    }

    mutating func flush() -> [Data] {
        guard !buffer.isEmpty else { return [] }
        let remaining = buffer
        buffer = Data()
        return shouldSuppress(data: remaining) ? [] : [remaining]
    }

    func shouldSuppress(_ line: String) -> Bool {
        patterns.contains { line.contains($0) }
    }

    private mutating func drainLines() -> [Data] {
        var kept: [Data] = []
        while let range = buffer.range(of: newline) {
            let lineData = buffer.subdata(in: 0..<range.upperBound)
            buffer.removeSubrange(0..<range.upperBound)
            if !shouldSuppress(data: lineData) {
                kept.append(lineData)
            }
        }
        return kept
    }

    private func shouldSuppress(data: Data) -> Bool {
        guard let line = String(data: data, encoding: .utf8) else {
            return false
        }
        return shouldSuppress(line)
    }
}

final class StderrFilter {
    private let originalHandle: FileHandle
    private let pipe: Pipe
    private var lineBuffer: StderrLineBuffer

    init?(patterns: [String]) {
        let originalFD = dup(STDERR_FILENO)
        guard originalFD >= 0 else { return nil }
        originalHandle = FileHandle(fileDescriptor: originalFD, closeOnDealloc: false)
        pipe = Pipe()
        lineBuffer = StderrLineBuffer(patterns: patterns)

        guard dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO) >= 0 else {
            return nil
        }
        pipe.fileHandleForWriting.closeFile()

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            let lines = self.lineBuffer.consume(data)
            for line in lines {
                self.originalHandle.write(line)
            }
        }
    }

    deinit {
        let remaining = lineBuffer.flush()
        for line in remaining {
            originalHandle.write(line)
        }
    }
}
