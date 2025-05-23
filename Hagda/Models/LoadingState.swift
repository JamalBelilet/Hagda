import Foundation
import SwiftUI

/// Represents the loading state of an async operation
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(AppError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: AppError? {
        if case .error(let error) = self { return error }
        return nil
    }
}

/// A view that displays content based on loading state
struct LoadingStateView<T, Content: View, LoadingContent: View, ErrorContent: View>: View {
    let state: LoadingState<T>
    let content: (T) -> Content
    let loadingContent: () -> LoadingContent
    let errorContent: (AppError) -> ErrorContent
    
    init(
        state: LoadingState<T>,
        @ViewBuilder content: @escaping (T) -> Content,
        @ViewBuilder loadingContent: @escaping () -> LoadingContent = { LoadingView() },
        @ViewBuilder errorContent: @escaping (AppError) -> ErrorContent
    ) {
        self.state = state
        self.content = content
        self.loadingContent = loadingContent
        self.errorContent = errorContent
    }
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            loadingContent()
        case .loaded(let value):
            content(value)
        case .error(let error):
            errorContent(error)
        }
    }
}

/// Protocol for view models with loading states
protocol LoadingStateViewModel: AnyObject {
    associatedtype DataType
    var loadingState: LoadingState<DataType> { get set }
    func load() async
    func retry() async
}

/// Extension to handle common loading patterns
extension LoadingStateViewModel {
    func retry() async {
        await load()
    }
    
    @MainActor
    func setLoading() {
        loadingState = .loading
    }
    
    @MainActor
    func setLoaded(_ data: DataType) {
        loadingState = .loaded(data)
    }
    
    @MainActor
    func setError(_ error: AppError) {
        loadingState = .error(error)
    }
    
    @MainActor
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            setError(appError)
        } else if let urlError = error as? URLError {
            setError(urlError.asAppError)
        } else {
            setError(.unknown(error))
        }
    }
}

/// Async operation wrapper with timeout
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AppError.network(.timeout)
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

/// Retry logic with exponential backoff
struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0
    )
}

/// Retry an async operation with exponential backoff
func retry<T>(
    config: RetryConfiguration = .default,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    var delay = config.initialDelay
    
    for attempt in 1...config.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            // Check if error is retryable
            if let appError = error as? AppError, !appError.isRetryable {
                throw error
            }
            
            // Don't delay after the last attempt
            if attempt < config.maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay = min(delay * config.multiplier, config.maxDelay)
            }
        }
    }
    
    throw lastError ?? AppError.unknown(NSError(domain: "RetryError", code: 0))
}