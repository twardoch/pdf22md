// this_file: pdf22md/Sources/PDF22MD/Version.swift

import Foundation

/// Version information for PDF22MD
public struct Version {
    /// The current version string, set at build time
    public static let current: String = {
        #if SWIFT_PACKAGE
        // When building with Swift Package Manager, use build-time version
        return "v1.5.3-56-g188a29e-dirty"
        #else
        // Fallback for other build systems
        return "dev"
        #endif
    }()
    
    /// Git commit hash, set at build time
    public static let commit: String = {
        #if SWIFT_PACKAGE
        return "188a29e3de8d545fe22cc2ee2a9755950182a952"
        #else
        return "unknown"
        #endif
    }()
    
    /// Build timestamp
    public static let buildDate: String = {
        #if SWIFT_PACKAGE
        return "2026-01-27T13:36:16Z"
        #else
        return "unknown"
        #endif
    }()
    
    /// Full version string with build info
    public static let fullVersion: String = {
        var version = current
        if commit != "unknown" {
            let shortCommit = String(commit.prefix(7))
            version += " (\(shortCommit))"
        }
        return version
    }()
}