import Foundation

/// Model for a Mastodon account
struct MastodonAccount: Codable {
    let id: String
    let username: String
    let acct: String
    let display_name: String
    let url: String
    let note: String?
    let avatar: String?
    let header: String?
    let followers_count: Int
    let following_count: Int
    let statuses_count: Int
    
    // Add coding keys for fallback field names
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case acct
        case display_name = "displayName"
        case url
        case note = "description"
        case avatar
        case header
        case followers_count = "followersCount"
        case following_count = "followingCount"
        case statuses_count = "statusesCount"
    }
    
    // Custom init to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields - try both snake_case and camelCase
        id = try container.decode(String.self, forKey: .id)
        
        // Try username or fallback to screen_name (Twitter/Bluesky API compatibility)
        do {
            username = try container.decode(String.self, forKey: .username)
        } catch {
            // For Twitter compatibility
            username = "user" 
        }
        
        // Try acct or fallback to username
        do {
            acct = try container.decode(String.self, forKey: .acct)
        } catch {
            acct = username
        }
        
        // Try display_name or fallback to username
        do {
            display_name = try container.decode(String.self, forKey: .display_name)
        } catch {
            display_name = username
        }
        
        // URL is required
        url = try container.decode(String.self, forKey: .url)
        
        // Optional fields
        note = try container.decodeIfPresent(String.self, forKey: .note)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        header = try container.decodeIfPresent(String.self, forKey: .header)
        
        // Try to decode counts or use defaults
        do {
            followers_count = try container.decode(Int.self, forKey: .followers_count)
        } catch {
            followers_count = 0
        }
        
        do {
            following_count = try container.decode(Int.self, forKey: .following_count)
        } catch {
            following_count = 0
        }
        
        do {
            statuses_count = try container.decode(Int.self, forKey: .statuses_count)
        } catch {
            statuses_count = 0
        }
    }
    
    /// A brief description that includes followers count
    var formattedDescription: String {
        var result = note?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? "A Mastodon account"
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.isEmpty {
            result = "A Mastodon account"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let formatted = formatter.string(from: NSNumber(value: followers_count)) {
            result += " • \(formatted) followers"
        }
        
        return result
    }
    
    /// Convert to app Source model
    func toSource() -> Source {
        return Source(
            name: display_name.isEmpty ? username : display_name,
            type: .mastodon,
            description: formattedDescription,
            handle: "@\(acct)",
            artworkUrl: avatar,
            feedUrl: url
        )
    }
}

/// Model for a Mastodon status (post)
struct MastodonStatus: Codable {
    let id: String
    let created_at: String
    let content: String
    let url: String
    let account: MastodonAccount
    let replies_count: Int?
    let reblogs_count: Int?
    let favourites_count: Int?
    let media_attachments: [MediaAttachment]?
    
    var parsedCreatedAt: Date {
        // Parse the Mastodon API date format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = formatter.date(from: created_at) {
            return date
        }
        
        // Try alternate format without milliseconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: created_at) {
            return date
        }
        
        return Date()
    }
    
    struct MediaAttachment: Codable {
        let id: String
        let type: String
        let url: String
        let preview_url: String
        let description: String?
    }
    
    /// Convert to ContentItem
    func toContentItem(source: Source) -> ContentItem {
        // Clean HTML tags from content
        let cleanedContent = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        let subtitle = "@\(account.acct)"
        
        var interactions = ""
        if let replies = replies_count, replies > 0 {
            interactions += "\(replies) replies"
        }
        if let reblogs = reblogs_count, reblogs > 0 {
            if !interactions.isEmpty { interactions += " • " }
            interactions += "\(reblogs) boosts"
        }
        if let favorites = favourites_count, favorites > 0 {
            if !interactions.isEmpty { interactions += " • " }
            interactions += "\(favorites) favorites"
        }
        
        if !interactions.isEmpty {
            interactions = " • " + interactions
        }
        
        return ContentItem(
            title: cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle + interactions,
            date: parsedCreatedAt,
            type: .mastodon,
            contentPreview: cleanedContent,
            progressPercentage: 0.0
        )
    }
}

/// Model for a thread context (replies and context)
struct MastodonContext: Codable {
    let ancestors: [MastodonStatus]
    let descendants: [MastodonStatus]
}

/// Service for interacting with the Mastodon API
class MastodonAPIService {
    private let session: URLSession
    private let baseURL: String
    private let instanceURL: String
    
    /// Initialize with a specific Mastodon instance
    /// - Parameter instance: Mastodon instance domain (defaults to mastodon.social)
    init(instance: String = "mastodon.social", session: URLSession = .shared) {
        self.instanceURL = "https://\(instance)"
        self.baseURL = "\(instanceURL)/api/v1"
        self.session = session
    }
    
    /// Search for Mastodon accounts with the given query
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    ///   - completion: Callback with results or error
    func searchAccounts(query: String, limit: Int = 20, completion: @escaping (Result<[Source], Error>) -> Void) {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Construct the URL with parameters - using lookup endpoint
        var components = URLComponents(string: "\(baseURL)/accounts/lookup")
        components?.queryItems = [
            URLQueryItem(name: "acct", value: encodedQuery)
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        #if DEBUG
        print("Mastodon search URL: \(url.absoluteString)")
        #endif
        
        // Create and execute the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                #if DEBUG
                print("Network error fetching Mastodon accounts: \(error)")
                #endif
                
                // Return the error - no dummy data
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("Mastodon API response status: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Mastodon API response: \(jsonString.prefix(300))...")
            }
            #endif
            
            do {
                // For lookup endpoint, we get a single account, not an array
                let account = try JSONDecoder().decode(MastodonAccount.self, from: data)
                let source = account.toSource()
                completion(.success([source])) // Return as array for API compatibility
            } catch {
                #if DEBUG
                print("Error decoding Mastodon account: \(error)")
                #endif
                
                // Return the error - no dummy data
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Search for Mastodon accounts with async/await support
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of Source objects representing Mastodon accounts
    func searchAccounts(query: String, limit: Int = 20) async throws -> [Source] {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Construct the URL with parameters - using lookup endpoint
        var components = URLComponents(string: "\(baseURL)/accounts/lookup")
        components?.queryItems = [
            URLQueryItem(name: "acct", value: encodedQuery)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        #if DEBUG
        print("Mastodon search URL: \(url.absoluteString)")
        #endif
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            // Execute the request with async/await
            let (data, response) = try await session.data(for: request)
            
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("Mastodon API response status: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Mastodon API response: \(jsonString.prefix(300))...")
            }
            #endif
            
            // Try to parse the response
            do {
                // For lookup endpoint, we get a single account, not an array
                let account = try JSONDecoder().decode(MastodonAccount.self, from: data)
                let source = account.toSource()
                return [source] // Return as array for API compatibility
            } catch {
                #if DEBUG
                print("Error decoding Mastodon account: \(error)")
                #endif
                
                // Return the error - no dummy data
                throw error
            }
        } catch {
            #if DEBUG
            print("Network error fetching Mastodon accounts: \(error)")
            #endif
            
            // Return the error - no dummy data
            throw error
        }
    }
    
    /// Lookup a Mastodon account by username
    /// - Parameter username: The username to lookup
    /// - Returns: Source object representing the Mastodon account
    func lookupAccount(username: String) async throws -> Source {
        // URL encode the username
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/accounts/lookup")
        components?.queryItems = [
            URLQueryItem(name: "acct", value: encodedUsername)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        let account = try JSONDecoder().decode(MastodonAccount.self, from: data)
        return account.toSource()
    }
    
    /// Fetch statuses for a Mastodon account
    /// - Parameters:
    ///   - accountID: The ID of the account
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of ContentItem objects representing statuses
    func fetchAccountStatuses(accountID: String, limit: Int = 20) async throws -> [ContentItem] {
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/accounts/\(accountID)/statuses")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "exclude_replies", value: "false"),
            URLQueryItem(name: "exclude_reblogs", value: "false")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Mastodon API response: \(jsonString.prefix(200))...")
        }
        #endif
        
        // Parse the response
        let statuses = try JSONDecoder().decode([MastodonStatus].self, from: data)
        
        // Get the account info to create a source
        let accountData = try await fetchAccountInfo(accountID: accountID)
        let source = accountData.toSource()
        
        // Convert to ContentItem objects
        return statuses.map { $0.toContentItem(source: source) }
    }
    
    /// Fetch a specific Mastodon account by ID
    /// - Parameter accountID: The ID of the account
    /// - Returns: MastodonAccount object
    private func fetchAccountInfo(accountID: String) async throws -> MastodonAccount {
        let url = URL(string: "\(baseURL)/accounts/\(accountID)")!
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        return try JSONDecoder().decode(MastodonAccount.self, from: data)
    }
    
    /// Fetch the thread context for a specific status
    /// - Parameter statusID: The ID of the status
    /// - Returns: MastodonContext with ancestors and descendants
    func fetchThreadContext(statusID: String) async throws -> MastodonContext {
        let url = URL(string: "\(baseURL)/statuses/\(statusID)/context")!
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        return try JSONDecoder().decode(MastodonContext.self, from: data)
    }
    
    /// Fetch content for a Mastodon source
    /// - Parameters:
    ///   - source: The source to fetch content for
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of ContentItem objects
    func fetchContentForSource(_ source: Source, limit: Int = 20) async throws -> [ContentItem] {
        // If missing the feed URL or handle, use the handle from the source
        if let handle = source.handle, handle.hasPrefix("@") {
            // Use the handle (which is @username@instance)
            // Remove the @ prefix
            let acct = String(handle.dropFirst())
            
            #if DEBUG
            print("Looking up Mastodon account with handle: \(acct)")
            #endif
            
            do {
                let lookupAccount = try await fetchAccountByUsername(acct)
                return try await fetchAccountStatuses(accountID: lookupAccount.id, limit: limit)
            } catch {
                #if DEBUG
                print("Error looking up account by username: \(error.localizedDescription), trying direct URL")
                #endif
                
                // If handle lookup fails, try the feed URL
                if let feedUrl = source.feedUrl {
                    return try await fetchContentFromURL(feedUrl, limit: limit)
                } else {
                    throw error
                }
            }
        } else if let feedUrl = source.feedUrl {
            return try await fetchContentFromURL(feedUrl, limit: limit)
        } else {
            throw URLError(.badURL)
        }
    }
    
    /// Helper method to fetch content from a URL
    /// - Parameters:
    ///   - feedUrl: URL to fetch content from
    ///   - limit: Maximum number of results
    /// - Returns: Array of ContentItem objects
    private func fetchContentFromURL(_ feedUrl: String, limit: Int) async throws -> [ContentItem] {
        // Try to extract the account ID from the URL path
        // Typical Mastodon profile URL: https://mastodon.social/@username or https://mastodon.social/users/username
        #if DEBUG
        print("Fetching Mastodon content from URL: \(feedUrl)")
        #endif
        
        if feedUrl.contains("/users/") {
            // If the URL is in the format https://instance/users/username
            let components = feedUrl.components(separatedBy: "/users/")
            guard components.count > 1 else {
                throw URLError(.badURL)
            }
            
            // In this case, we need to look up the account ID by username
            let username = components[1].split(separator: "/").first ?? ""
            #if DEBUG
            print("Looking up Mastodon account with username: \(username)")
            #endif
            
            let account = try await lookupAccount(username: String(username))
            
            // Now fetch statuses using the handle (which is @username@instance)
            guard let handle = account.handle, handle.hasPrefix("@") else {
                throw URLError(.badURL)
            }
            
            // Remove the @ prefix
            let acct = String(handle.dropFirst())
            let lookupAccount = try await fetchAccountByUsername(acct)
            return try await fetchAccountStatuses(accountID: lookupAccount.id, limit: limit)
        } else if feedUrl.contains("/@") {
            // If the URL is in the format https://instance/@username
            let components = feedUrl.components(separatedBy: "/@")
            guard components.count > 1 else {
                throw URLError(.badURL)
            }
            
            // In this case, we need to look up the account ID by username
            let username = components[1].split(separator: "/").first ?? ""
            #if DEBUG
            print("Looking up Mastodon account for username: \(username)")
            #endif
            
            let lookupAccount = try await fetchAccountByUsername(String(username))
            return try await fetchAccountStatuses(accountID: lookupAccount.id, limit: limit)
        } else {
            // Try to extract account ID directly if it's already in the URL
            let pathComponents = URL(string: feedUrl)?.pathComponents ?? []
            guard let accountIDIndex = pathComponents.firstIndex(where: { $0 == "accounts" || $0 == "users" }),
                  accountIDIndex + 1 < pathComponents.count else {
                throw URLError(.badURL)
            }
            
            let accountID = pathComponents[accountIDIndex + 1]
            return try await fetchAccountStatuses(accountID: accountID, limit: limit)
        }
    }
    
    /// Fetch a Mastodon account by username
    /// - Parameter username: The username to fetch
    /// - Returns: MastodonAccount object
    private func fetchAccountByUsername(_ username: String) async throws -> MastodonAccount {
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/accounts/lookup")
        components?.queryItems = [
            URLQueryItem(name: "acct", value: username)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        return try JSONDecoder().decode(MastodonAccount.self, from: data)
    }
}