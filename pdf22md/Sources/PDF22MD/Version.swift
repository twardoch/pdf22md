// this_file: pdf22md/Sources/PDF22MD/Version.swift

import Foundation

/// Version information for PDF22MD
public struct Version {
    /// The current version string, set at build time
    public static let current: String = {
        #if SWIFT_PACKAGE
        return "v1.7.0"
        #else
        // Fallback for other build systems
        return "dev"
        #endif
    }()
    
    /// Git commit hash, set at build time
    public static let commit: String = {
        #if SWIFT_PACKAGE
        return "4a81427c54edea92b713683fc38e6e93b0943b91"
        #else
        return "unknown"
        #endif
    }()
    
    /// Build timestamp
    public static let buildDate: String = {
        #if SWIFT_PACKAGE
        return "2026-01-27T17:48:30Z"
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