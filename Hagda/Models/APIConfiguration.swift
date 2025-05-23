import Foundation
import Security

/// Manages API configuration and secure credential storage
final class APIConfiguration {
    static let shared = APIConfiguration()
    
    private let keychainService = "com.hagda.api"
    private let userAgentHeader = "Hagda/1.0"
    
    private init() {}
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        static let reddit = "https://www.reddit.com"
        static let bluesky = "https://public.api.bsky.app/xrpc"
        static let mastodon = "https://mastodon.social/api/v1"
        static let feedlySearch = "https://cloud.feedly.com/v3/search/feeds"
    }
    
    // MARK: - Headers
    
    var defaultHeaders: [String: String] {
        return [
            "User-Agent": userAgentHeader,
            "Accept": "application/json"
        ]
    }
    
    // MARK: - Keychain Storage
    
    /// Stores a credential securely in the keychain
    func storeCredential(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw APIConfigurationError.keychainError(status: status)
        }
    }
    
    /// Retrieves a credential from the keychain
    func retrieveCredential(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw APIConfigurationError.keychainError(status: status)
        }
        
        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw APIConfigurationError.invalidData
        }
        
        return value
    }
    
    /// Deletes a credential from the keychain
    func deleteCredential(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIConfigurationError.keychainError(status: status)
        }
    }
    
    // MARK: - Environment Configuration
    
    var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    /// Returns the appropriate API endpoint based on environment
    func endpoint(for service: APIService) -> String {
        switch service {
        case .reddit:
            return Endpoints.reddit
        case .bluesky:
            return Endpoints.bluesky
        case .mastodon:
            return Endpoints.mastodon
        case .feedly:
            return Endpoints.feedlySearch
        }
    }
}

// MARK: - Supporting Types

enum APIService {
    case reddit
    case bluesky
    case mastodon
    case feedly
}

enum APIConfigurationError: LocalizedError {
    case keychainError(status: OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidData:
            return "Invalid data format"
        }
    }
}