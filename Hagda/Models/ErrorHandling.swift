import Foundation

/// Types of errors that can occur in the app
enum AppError: LocalizedError {
    case network(NetworkError)
    case parsing(ParsingError)
    case storage(StorageError)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.userFriendlyMessage
        case .parsing(let error):
            return error.userFriendlyMessage
        case .storage(let error):
            return error.userFriendlyMessage
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network(let error):
            return error.recoverySuggestion
        case .parsing:
            return "The content format may have changed. We're working on a fix."
        case .storage:
            return "Try freeing up some space on your device."
        case .unknown:
            return "If this persists, please contact support."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .parsing:
            return false
        case .storage:
            return false
        case .unknown:
            return true
        }
    }
}

/// Network-specific errors
enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case rateLimited
    case unauthorized
    case notFound
    
    var userFriendlyMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "The request took too long"
        case .serverError(let code):
            if code >= 500 {
                return "The service is temporarily unavailable"
            } else {
                return "There was a problem with the request"
            }
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Content not found"
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again."
        case .timeout:
            return "The server might be busy. Try again in a few moments."
        case .serverError:
            return "The service might be down. Try again later."
        case .rateLimited:
            return "You've made too many requests. Wait a bit before trying again."
        case .unauthorized:
            return "You may need to sign in or check your credentials."
        case .notFound:
            return "The content may have been moved or deleted."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .rateLimited:
            return true
        case .unauthorized, .notFound:
            return false
        }
    }
}

/// Parsing-specific errors
enum ParsingError: LocalizedError {
    case invalidJSON
    case missingField(String)
    case invalidFormat
    case emptyResponse
    
    var userFriendlyMessage: String {
        switch self {
        case .invalidJSON:
            return "Unable to read the content"
        case .missingField:
            return "Some information is missing"
        case .invalidFormat:
            return "The content format is unexpected"
        case .emptyResponse:
            return "No content available"
        }
    }
}

/// Storage-specific errors
enum StorageError: LocalizedError {
    case insufficientSpace
    case corruptedData
    case accessDenied
    
    var userFriendlyMessage: String {
        switch self {
        case .insufficientSpace:
            return "Not enough storage space"
        case .corruptedData:
            return "Saved data is corrupted"
        case .accessDenied:
            return "Cannot access storage"
        }
    }
}

/// Error recovery coordinator
struct ErrorRecovery {
    
    /// Suggests recovery action based on error type
    static func recoveryAction(for error: AppError) -> RecoveryAction {
        switch error {
        case .network(let networkError):
            switch networkError {
            case .noConnection:
                return .checkConnection
            case .timeout, .serverError, .rateLimited:
                return .retry
            case .unauthorized:
                return .authenticate
            case .notFound:
                return .goBack
            }
        case .parsing:
            return .contactSupport
        case .storage:
            return .clearCache
        case .unknown:
            return .retry
        }
    }
    
    enum RecoveryAction {
        case retry
        case checkConnection
        case authenticate
        case clearCache
        case contactSupport
        case goBack
        
        var buttonTitle: String {
            switch self {
            case .retry:
                return "Try Again"
            case .checkConnection:
                return "Check Settings"
            case .authenticate:
                return "Sign In"
            case .clearCache:
                return "Clear Cache"
            case .contactSupport:
                return "Get Help"
            case .goBack:
                return "Go Back"
            }
        }
        
        var systemImage: String {
            switch self {
            case .retry:
                return "arrow.clockwise"
            case .checkConnection:
                return "wifi.exclamationmark"
            case .authenticate:
                return "person.circle"
            case .clearCache:
                return "trash"
            case .contactSupport:
                return "questionmark.circle"
            case .goBack:
                return "arrow.left"
            }
        }
    }
}

/// Converts URLError to our AppError
extension URLError {
    var asAppError: AppError {
        switch self.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .network(.noConnection)
        case .timedOut:
            return .network(.timeout)
        case .cannotFindHost, .cannotConnectToHost:
            return .network(.serverError(statusCode: 0))
        default:
            return .unknown(self)
        }
    }
}

/// HTTP response validation
extension HTTPURLResponse {
    var asNetworkError: NetworkError? {
        switch statusCode {
        case 200..<300:
            return nil
        case 401:
            return .unauthorized
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        case 500..<600:
            return .serverError(statusCode: statusCode)
        default:
            return .serverError(statusCode: statusCode)
        }
    }
}