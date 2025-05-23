import Foundation

/// Secure networking layer that wraps URLSession with security features
final class SecureNetworking {
    static let shared = SecureNetworking()
    
    private let session: URLSession
    private let networkSecurity = NetworkSecurity.shared
    
    private init() {
        let configuration = networkSecurity.createSecureSessionConfiguration()
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }
    
    /// Performs a secure data request
    func data(from url: URL) async throws -> (Data, URLResponse) {
        let request = networkSecurity.createSecureRequest(url: url)
        return try await session.data(for: request)
    }
    
    /// Performs a secure data request with custom URLRequest
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var secureRequest = request
        
        // Apply security headers if not already set
        if secureRequest.value(forHTTPHeaderField: "User-Agent") == nil {
            let headers = APIConfiguration.shared.defaultHeaders
            for (key, value) in headers {
                secureRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return try await session.data(for: secureRequest)
    }
    
    /// Creates a secure URL session for specific needs
    static func createSecureSession() -> URLSession {
        let configuration = NetworkSecurity.shared.createSecureSessionConfiguration()
        return URLSession(configuration: configuration)
    }
}

// MARK: - URLSessionProtocol Conformance

extension SecureNetworking: URLSessionProtocol {
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        return try await data(from: url)
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return session.dataTask(with: request, completionHandler: completionHandler)
    }
    
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let request = networkSecurity.createSecureRequest(url: url)
        return session.dataTask(with: request, completionHandler: completionHandler)
    }
}