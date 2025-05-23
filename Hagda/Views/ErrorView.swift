import SwiftUI

/// A reusable error view with retry capability
struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    
    @State private var showDetails = false
    
    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundStyle(iconColor)
                .padding(.bottom, 10)
            
            // Error message
            VStack(spacing: 8) {
                Text(error.errorDescription ?? "Something went wrong")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                if error.isRetryable, let retryAction = retryAction {
                    Button(action: {
                        hapticFeedback()
                        retryAction()
                    }) {
                        Label(recoveryAction.buttonTitle, systemImage: recoveryAction.systemImage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Additional actions based on error type
                if case .network(.noConnection) = error {
                    Button {
                        openSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                            .font(.subheadline)
                    }
                }
                
                // Show details toggle
                Button {
                    showDetails.toggle()
                } label: {
                    Label(showDetails ? "Hide Details" : "Show Details", 
                          systemImage: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Error details
            if showDetails {
                GroupBox {
                    Text(technicalDetails)
                        .font(.caption)
                        .monospaced()
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorIcon: String {
        switch error {
        case .network(.noConnection):
            return "wifi.slash"
        case .network(.serverError):
            return "exclamationmark.icloud"
        case .network(.timeout):
            return "clock.badge.exclamationmark"
        case .network(.rateLimited):
            return "hourglass"
        case .parsing:
            return "doc.badge.ellipsis"
        case .storage:
            return "externaldrive.badge.exclamationmark"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch error {
        case .network(.noConnection):
            return .orange
        case .network(.serverError), .network(.notFound):
            return .red
        case .network(.rateLimited):
            return .yellow
        default:
            return .red
        }
    }
    
    private var recoveryAction: ErrorRecovery.RecoveryAction {
        ErrorRecovery.recoveryAction(for: error)
    }
    
    private var technicalDetails: String {
        var details = "Error Type: \(String(describing: type(of: error)))\n"
        
        switch error {
        case .network(let netError):
            details += "Network Error: \(netError)\n"
        case .parsing(let parseError):
            details += "Parsing Error: \(parseError)\n"
        case .storage(let storageError):
            details += "Storage Error: \(storageError)\n"
        case .unknown(let unknownError):
            details += "Unknown Error: \(unknownError.localizedDescription)\n"
        }
        
        details += "Time: \(Date().formatted())"
        return details
    }
    
    private func hapticFeedback() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

/// A compact inline error view for smaller spaces
struct InlineErrorView: View {
    let message: String
    let systemImage: String
    let retryAction: (() -> Void)?
    
    init(message: String, systemImage: String = "exclamationmark.circle", retryAction: (() -> Void)? = nil) {
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Full Error View") {
    ErrorView(
        error: .network(.noConnection),
        retryAction: { print("Retry tapped") }
    )
}

#Preview("Server Error") {
    ErrorView(
        error: .network(.serverError(statusCode: 500)),
        retryAction: { print("Retry tapped") }
    )
}

#Preview("Inline Error") {
    InlineErrorView(
        message: "Failed to load content",
        retryAction: { print("Retry tapped") }
    )
    .padding()
}