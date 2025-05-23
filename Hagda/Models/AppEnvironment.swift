import Foundation

/// Manages environment-specific configuration
struct AppEnvironment {
    
    // MARK: - Environment Types
    
    enum EnvironmentType {
        case development
        case staging
        case production
        
        var name: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }
    
    // MARK: - Current Environment
    
    static var current: EnvironmentType {
        #if DEBUG
        return .development
        #else
        // Check if we're in TestFlight/App Store
        if isTestFlight {
            return .staging
        } else {
            return .production
        }
        #endif
    }
    
    // MARK: - Environment Detection
    
    private static var isTestFlight: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }
    
    static var isAppStore: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "receipt"
    }
    
    // MARK: - Configuration Values
    
    static var configuration: Configuration {
        switch current {
        case .development:
            return Configuration(
                apiLogLevel: .verbose,
                enableDebugMenu: true,
                crashReportingEnabled: false,
                analyticsEnabled: false,
                cacheExpirationHours: 1
            )
        case .staging:
            return Configuration(
                apiLogLevel: .warning,
                enableDebugMenu: true,
                crashReportingEnabled: true,
                analyticsEnabled: true,
                cacheExpirationHours: 6
            )
        case .production:
            return Configuration(
                apiLogLevel: .error,
                enableDebugMenu: false,
                crashReportingEnabled: true,
                analyticsEnabled: true,
                cacheExpirationHours: 24
            )
        }
    }
    
    // MARK: - Configuration Model
    
    struct Configuration {
        let apiLogLevel: LogLevel
        let enableDebugMenu: Bool
        let crashReportingEnabled: Bool
        let analyticsEnabled: Bool
        let cacheExpirationHours: Int
    }
    
    enum LogLevel {
        case verbose
        case debug
        case info
        case warning
        case error
        case none
    }
}

// MARK: - Info.plist Values

extension AppEnvironment {
    
    /// Reads a value from Info.plist
    static func infoPlistValue(for key: String) -> String? {
        return Bundle.main.infoDictionary?[key] as? String
    }
    
    /// App version string
    static var appVersion: String {
        return infoPlistValue(for: "CFBundleShortVersionString") ?? "Unknown"
    }
    
    /// Build number
    static var buildNumber: String {
        return infoPlistValue(for: "CFBundleVersion") ?? "Unknown"
    }
    
    /// Full version string (e.g., "1.0.0 (42)")
    static var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}