import Foundation

public struct AILogger {
    
    public static func truncate(_ string: String, maxLength: Int = 600) -> String {
        guard string.count > maxLength else { return string }
        let halfLength = maxLength / 2
        let startIndex = string.index(string.startIndex, offsetBy: halfLength)
        let endIndex = string.index(string.endIndex, offsetBy: -halfLength)
        let start = String(string[..<startIndex])
        let end = String(string[endIndex...])
        return "\(start)...\(end)"
    }
    
    public static func formatAIInput(
        _ content: String,
        systemPrompt: String? = nil,
        chunkInfo: String? = nil
    ) -> String {
        var result = ""
        
        if let system = systemPrompt, !system.isEmpty {
            let truncatedSystem = truncate(system)
            result += "[System] \(truncatedSystem) (\(system.count))\n"
        }
        
        let truncatedContent = truncate(content)
        if let chunk = chunkInfo {
            result += "[\(chunk)] [AI→] \(truncatedContent) (\(content.count))"
        } else {
            result += "[AI→] \(truncatedContent) (\(content.count))"
        }
        
        return result
    }
    
    public static func formatAIOutput(_ content: String) -> String {
        let truncated = truncate(content)
        return "[←AI] \(truncated) (\(content.count))"
    }
    
    public static func log(_ message: String, verbose: Bool) {
        guard verbose else { return }
        FileHandle.standardError.write(Data("[pdf22md] \(message)\n".utf8))
    }
}
