import Foundation
import CryptoKit

/// Handles network security configurations including certificate pinning
final class NetworkSecurity {
    static let shared = NetworkSecurity()
    
    private init() {}
    
    // MARK: - SSL Pinning
    
    /// Public key hashes for certificate pinning (base64 encoded SHA256)
    private let pinnedHosts: [String: Set<String>] = [
        "reddit.com": [
            // Reddit's public key hashes - these would be actual values in production
            // Example: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        ],
        "bsky.app": [
            // Bluesky's public key hashes
        ],
        "mastodon.social": [
            // Mastodon's public key hashes
        ]
    ]
    
    /// Validates server trust for certificate pinning
    func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        // In production, this would implement actual certificate pinning
        // For now, we'll use default system validation
        
        // Check if host requires pinning
        guard let pinnedKeys = pinnedHosts[host], !pinnedKeys.isEmpty else {
            // No pinning required, use default validation
            return evaluateServerTrust(serverTrust)
        }
        
        // In production, implement certificate pinning here
        // This would extract the public key from the certificate chain
        // and compare against our pinned keys
        
        return evaluateServerTrust(serverTrust)
    }
    
    private func evaluateServerTrust(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        return isValid
    }
    
    // MARK: - Network Configuration
    
    /// Creates a secure URLSession configuration
    func createSecureSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        
        // Security settings
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024, // 10 MB
            diskCapacity: 50 * 1024 * 1024,    // 50 MB
            diskPath: "com.hagda.urlcache"
        )
        
        // Timeout settings
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // Privacy settings
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.discretionary = false
        
        return configuration
    }
    
    /// Creates a secure URL request with proper headers
    func createSecureRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add security headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        // Apply default headers from API configuration
        let defaultHeaders = APIConfiguration.shared.defaultHeaders
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}