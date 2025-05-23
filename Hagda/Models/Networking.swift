import Foundation

/// Protocol defining the URLSession interface that we use in our services
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol { }

// Extension for commonly used URLSessionProtocol convenience methods
extension URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return try await data(from: url, delegate: nil)
    }
}