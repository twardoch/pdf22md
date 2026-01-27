// this_file: pdf22md/Sources/PDF22MD/ProgressTracker.swift
import Foundation

public final class ProgressTracker: @unchecked Sendable {
    public enum Phase: String, Sendable {
        case extraction = "Extracting"
        case aiProcessing = "AI processing"
        case generation = "Generating"
    }
    
    private let total: Int
    private var completed: Int = 0
    private var startTime: Date = Date()
    private var phaseStartTime: Date = Date()
    private var currentPhase: Phase = .extraction
    private let lock = NSLock()
    
    public var isEnabled: Bool = true
    public var barWidth: Int = 30
    
    public init(total: Int) {
        self.total = max(1, total)
    }
    
    public func start(phase: Phase) {
        lock.lock()
        defer { lock.unlock() }
        currentPhase = phase
        phaseStartTime = Date()
        completed = 0
        if phase == .extraction {
            startTime = Date()
        }
    }
    
    public func increment() {
        lock.lock()
        defer { lock.unlock() }
        completed = min(completed + 1, total)
    }
    
    public func update(completed: Int) {
        lock.lock()
        defer { lock.unlock() }
        self.completed = min(completed, total)
    }
    
    public func render() -> String {
        lock.lock()
        let snapshot = (completed: completed, phase: currentPhase, phaseStart: phaseStartTime)
        lock.unlock()
        
        let progress = Double(snapshot.completed) / Double(total)
        let filledWidth = Int(progress * Double(barWidth))
        let emptyWidth = barWidth - filledWidth
        
        let bar = String(repeating: "█", count: filledWidth) + String(repeating: "░", count: emptyWidth)
        let percentage = Int(progress * 100)
        
        let eta = formatETA(completed: snapshot.completed, since: snapshot.phaseStart)
        
        return "\r[pdf22md] \(snapshot.phase.rawValue): [\(bar)] \(percentage)% (\(snapshot.completed)/\(total)) \(eta)"
    }
    
    public func renderLine() -> String {
        lock.lock()
        let snapshot = (completed: completed, phase: currentPhase, phaseStart: phaseStartTime)
        lock.unlock()
        
        let eta = formatETA(completed: snapshot.completed, since: snapshot.phaseStart)
        return "[pdf22md] \(snapshot.phase.rawValue) page \(snapshot.completed)/\(total) \(eta)"
    }
    
    private func formatETA(completed: Int, since startTime: Date) -> String {
        guard completed > 0 else { return "" }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let avgTime = elapsed / Double(completed)
        let remaining = Double(total - completed) * avgTime
        
        if remaining < 1 { return "" }
        if remaining < 60 { return "ETA: \(Int(remaining))s" }
        if remaining < 3600 { return "ETA: \(Int(remaining / 60))m \(Int(remaining.truncatingRemainder(dividingBy: 60)))s" }
        return "ETA: \(Int(remaining / 3600))h \(Int((remaining / 60).truncatingRemainder(dividingBy: 60)))m"
    }
    
    public func clear() {
        guard isEnabled else { return }
        FileHandle.standardError.write(Data("\r\u{1B}[K".utf8))
    }
    
    public func display() {
        guard isEnabled else { return }
        FileHandle.standardError.write(Data(render().utf8))
    }
    
    public func displayLine() {
        guard isEnabled else { return }
        FileHandle.standardError.write(Data((renderLine() + "\n").utf8))
    }
    
    public func finish() {
        guard isEnabled else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let formatted = elapsed < 60 ? String(format: "%.1fs", elapsed) : "\(Int(elapsed / 60))m \(Int(elapsed.truncatingRemainder(dividingBy: 60)))s"
        FileHandle.standardError.write(Data("\r\u{1B}[K[pdf22md] Complete (\(total) pages in \(formatted))\n".utf8))
    }
}
