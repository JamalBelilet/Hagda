import XCTest
@testable import Hagda

/// A shared mock implementation of URLSessionProtocol for testing
class SharedMockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let mockDataTask = SharedMockURLSessionDataTask()
        mockDataTask.completionHandler = {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
        return mockDataTask
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let mockDataTask = SharedMockURLSessionDataTask()
        mockDataTask.completionHandler = {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
        return mockDataTask
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.unknown)
        }
        
        return (data, response)
    }
    
    func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.unknown)
        }
        
        return (data, response)
    }
}

/// A shared mock URLSessionDataTask for testing
class SharedMockURLSessionDataTask: URLSessionDataTask {
    var completionHandler: (() -> Void)?
    
    override func resume() {
        completionHandler?()
    }
}

/// A shared mock URLSession that handles sequential requests with different responses
class SharedSequentialMockURLSession: URLSessionProtocol {
    var mockResponses: [(Data, URLResponse, Error?)] = []
    private var currentIndex = 0
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let mockDataTask = SharedMockURLSessionDataTask()
        
        guard currentIndex < mockResponses.count else {
            completionHandler(nil, nil, URLError(.unknown))
            return mockDataTask
        }
        
        let (data, response, error) = mockResponses[currentIndex]
        currentIndex += 1
        
        mockDataTask.completionHandler = {
            completionHandler(data, response, error)
        }
        
        return mockDataTask
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let mockDataTask = SharedMockURLSessionDataTask()
        
        guard currentIndex < mockResponses.count else {
            completionHandler(nil, nil, URLError(.unknown))
            return mockDataTask
        }
        
        let (data, response, error) = mockResponses[currentIndex]
        currentIndex += 1
        
        mockDataTask.completionHandler = {
            completionHandler(data, response, error)
        }
        
        return mockDataTask
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard currentIndex < mockResponses.count else {
            throw URLError(.unknown)
        }
        
        let (data, response, error) = mockResponses[currentIndex]
        currentIndex += 1
        
        if let error = error {
            throw error
        }
        
        return (data, response)
    }
    
    func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        guard currentIndex < mockResponses.count else {
            throw URLError(.unknown)
        }
        
        let (data, response, error) = mockResponses[currentIndex]
        currentIndex += 1
        
        if let error = error {
            throw error
        }
        
        return (data, response)
    }
}