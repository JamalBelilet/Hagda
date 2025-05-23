import Testing
@testable import Hagda
import Foundation

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    
    @Test("Network errors have appropriate user messages")
    func testNetworkErrorMessages() {
        let errors: [(NetworkError, String)] = [
            (.noConnection, "No internet connection"),
            (.timeout, "The request took too long"),
            (.serverError(statusCode: 500), "The service is temporarily unavailable"),
            (.serverError(statusCode: 400), "There was a problem with the request"),
            (.rateLimited, "Too many requests. Please wait a moment."),
            (.unauthorized, "Authentication required"),
            (.notFound, "Content not found")
        ]
        
        for (error, expectedMessage) in errors {
            #expect(error.userFriendlyMessage == expectedMessage)
        }
    }
    
    @Test("Network errors have retry capability")
    func testNetworkErrorRetryability() {
        #expect(NetworkError.noConnection.isRetryable == true)
        #expect(NetworkError.timeout.isRetryable == true)
        #expect(NetworkError.serverError(statusCode: 500).isRetryable == true)
        #expect(NetworkError.rateLimited.isRetryable == true)
        #expect(NetworkError.unauthorized.isRetryable == false)
        #expect(NetworkError.notFound.isRetryable == false)
    }
    
    @Test("App errors wrap network errors correctly")
    func testAppErrorWrapping() {
        let networkError = NetworkError.noConnection
        let appError = AppError.network(networkError)
        
        #expect(appError.errorDescription == "No internet connection")
        #expect(appError.recoverySuggestion == "Check your internet connection and try again.")
        #expect(appError.isRetryable == true)
    }
    
    @Test("URL errors convert to app errors")
    func testURLErrorConversion() {
        let urlError = URLError(.notConnectedToInternet)
        let appError = urlError.asAppError
        
        if case .network(.noConnection) = appError {
            #expect(true)
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test("HTTP response validates status codes")
    func testHTTPResponseValidation() {
        let url = URL(string: "https://test.com")!
        
        // Test successful response
        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        #expect(response200.asNetworkError == nil)
        
        // Test error responses
        let response401 = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
        #expect(response401.asNetworkError == .unauthorized)
        
        let response404 = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        #expect(response404.asNetworkError == .notFound)
        
        let response429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil)!
        #expect(response429.asNetworkError == .rateLimited)
        
        let response500 = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        if case .serverError(let code) = response500.asNetworkError {
            #expect(code == 500)
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test("Error recovery suggests appropriate actions")
    func testErrorRecoveryActions() {
        let noConnectionError = AppError.network(.noConnection)
        let recoveryAction = ErrorRecovery.recoveryAction(for: noConnectionError)
        #expect(recoveryAction == .checkConnection)
        #expect(recoveryAction.buttonTitle == "Check Settings")
        #expect(recoveryAction.systemImage == "wifi.exclamationmark")
        
        let timeoutError = AppError.network(.timeout)
        let timeoutAction = ErrorRecovery.recoveryAction(for: timeoutError)
        #expect(timeoutAction == .retry)
        #expect(timeoutAction.buttonTitle == "Try Again")
    }
    
    @Test("Loading state transitions work correctly")
    func testLoadingStateTransitions() {
        var state = LoadingState<String>.idle
        
        #expect(state.isLoading == false)
        #expect(state.isError == false)
        #expect(state.value == nil)
        
        state = .loading
        #expect(state.isLoading == true)
        #expect(state.value == nil)
        
        state = .loaded("Success")
        #expect(state.isLoading == false)
        #expect(state.value == "Success")
        
        state = .error(.network(.timeout))
        #expect(state.isError == true)
        #expect(state.error != nil)
    }
    
    @Test("Retry configuration uses exponential backoff")
    func testRetryConfiguration() {
        let config = RetryConfiguration.default
        
        #expect(config.maxAttempts == 3)
        #expect(config.initialDelay == 1.0)
        #expect(config.maxDelay == 30.0)
        #expect(config.multiplier == 2.0)
        
        // Test delay calculation
        var delay = config.initialDelay
        delay = delay * config.multiplier // 2.0
        #expect(delay == 2.0)
        
        delay = delay * config.multiplier // 4.0
        #expect(delay == 4.0)
    }
}

// Test view model conformance
class MockLoadingViewModel: LoadingStateViewModel {
    typealias DataType = [String]
    
    @Published var loadingState: LoadingState<[String]> = .idle
    var loadCalled = false
    var retryCalled = false
    
    func load() async {
        loadCalled = true
        await setLoading()
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await setLoaded(["Item 1", "Item 2"])
    }
    
    func retry() async {
        retryCalled = true
        await load()
    }
}

@Suite("Loading State ViewModel Tests")
struct LoadingStateViewModelTests {
    
    @Test("View model handles loading lifecycle")
    func testViewModelLoadingLifecycle() async {
        let viewModel = MockLoadingViewModel()
        
        #expect(viewModel.loadingState.value == nil)
        
        await viewModel.load()
        
        #expect(viewModel.loadCalled == true)
        #expect(viewModel.loadingState.value?.count == 2)
        #expect(viewModel.loadingState.value?.first == "Item 1")
    }
    
    @Test("View model retry calls load")
    func testViewModelRetry() async {
        let viewModel = MockLoadingViewModel()
        
        await viewModel.retry()
        
        #expect(viewModel.retryCalled == true)
        #expect(viewModel.loadCalled == true)
    }
}