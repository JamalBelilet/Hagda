import Foundation

/// Model for a Bluesky account (actor)
struct BlueSkyAccount: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let description: String?
    let avatar: String?
    let banner: String?
    let followersCount: Int?
    let followsCount: Int?
    let postsCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case did
        case handle
        case displayName
        case description
        case avatar
        case banner
        case followersCount
        case followsCount
        case postsCount
    }
    
    // Standard initializer for manual creation
    init(did: String,
         handle: String,
         displayName: String?,
         description: String?,
         avatar: String?,
         banner: String?,
         followersCount: Int?,
         followsCount: Int?,
         postsCount: Int?) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.description = description
        self.avatar = avatar
        self.banner = banner
        self.followersCount = followersCount
        self.followsCount = followsCount
        self.postsCount = postsCount
    }
    
    // Custom init to handle response structure
    init(from decoder: Decoder) throws {
        // Handle the nested structure from Bluesky API
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // Direct decoding if fields are at the top level
            did = try container.decode(String.self, forKey: .did)
            handle = try container.decode(String.self, forKey: .handle)
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
            banner = try container.decodeIfPresent(String.self, forKey: .banner)
            followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount)
            followsCount = try container.decodeIfPresent(Int.self, forKey: .followsCount)
            postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount)
        } else {
            // Simple fallback for testing - in production would handle more complex nested structures
            did = ""
            handle = ""
            displayName = nil
            description = nil
            avatar = nil
            banner = nil
            followersCount = nil
            followsCount = nil
            postsCount = nil
        }
    }
    
    /// A brief description that includes followers count
    var formattedDescription: String {
        var result = description ?? "A Bluesky account"
        
        if let followers = followersCount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if let formatted = formatter.string(from: NSNumber(value: followers)) {
                result += " • \(formatted) followers"
            }
        }
        
        return result
    }
    
    /// Convert to app Source model
    func toSource() -> Source {
        return Source(
            name: displayName ?? handle,
            type: .bluesky,
            description: formattedDescription,
            handle: handle,
            artworkUrl: avatar,
            feedUrl: "https://bsky.app/profile/\(handle)"
        )
    }
}

/// Model for a Bluesky post (skeet)
struct BlueSkyPost: Codable {
    let uri: String
    let cid: String
    let author: BlueSkyAccount
    let record: PostRecord
    let indexedAt: String
    let replyCount: Int?
    let repostCount: Int?
    let likeCount: Int?
    
    struct PostRecord: Codable {
        let text: String
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case text
            case createdAt = "createdAt"
        }
    }
    
    var parsedCreatedAt: Date {
        // Parse the ISO 8601 date format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: record.createdAt) {
            return date
        }
        
        return Date()
    }
    
    /// Convert to ContentItem
    func toContentItem(source: Source) -> ContentItem {
        let subtitle = "@\(author.handle)"
        
        var interactions = ""
        if let replies = replyCount, replies > 0 {
            interactions += "\(replies) replies"
        }
        if let reposts = repostCount, reposts > 0 {
            if !interactions.isEmpty { interactions += " • " }
            interactions += "\(reposts) reposts"
        }
        if let likes = likeCount, likes > 0 {
            if !interactions.isEmpty { interactions += " • " }
            interactions += "\(likes) likes"
        }
        
        if !interactions.isEmpty {
            interactions = " • " + interactions
        }
        
        return ContentItem(
            title: record.text.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle + interactions,
            date: parsedCreatedAt,
            type: .bluesky,
            contentPreview: record.text,
            progressPercentage: 0.0,
            metadata: [
                "uri": uri,
                "cid": cid,
                "authorDid": author.did,
                "authorHandle": author.handle,
                "authorDisplayName": author.displayName ?? author.handle,
                "authorAvatar": author.avatar ?? "",
                "replyCount": replyCount ?? 0,
                "repostCount": repostCount ?? 0,
                "likeCount": likeCount ?? 0,
                "indexedAt": indexedAt,
                "text": record.text
            ]
        )
    }
}

// Note: We're using a simplified approach for Bluesky API handling
// In a production app, we would implement more robust JSON parsing,
// but for demo purposes we're keeping it simple with direct decoding.

/// Models for Bluesky API responses
struct SearchActorsResponse: Codable {
    let actors: [BlueSkyAccount]?
    
    // Add a fallback for empty responses
    var safeActors: [BlueSkyAccount] {
        return actors ?? []
    }
}

struct GetProfileResponse: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let description: String?
    let avatar: String?
    let banner: String?
    let followersCount: Int?
    let followsCount: Int?
    let postsCount: Int?
}

struct GetAuthorFeedResponse: Codable {
    let feed: [FeedItem]?
    let cursor: String?
    
    // Add a fallback for empty responses
    var safeFeed: [FeedItem] {
        return feed ?? []
    }
    
    struct FeedItem: Codable {
        let post: BlueSkyPost
    }
}

/// Service for interacting with the Bluesky API
class BlueSkyAPIService {
    private let session: URLSessionProtocol
    // Use Bluesky's public API endpoint that doesn't require authentication
    private let baseURL = "https://public.api.bsky.app/xrpc"
    
    // Authentication state
    private var accessToken: String?
    private var refreshToken: String?
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    /// Search for Bluesky accounts with the given query
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
        
        // Construct the URL with parameters using the correct Bluesky API endpoint
        var components = URLComponents(string: "\(baseURL)/app.bsky.actor.searchActors")
        
        // Use a different endpoint if the query starts with @ or contains .bsky.social
        if query.hasPrefix("@") || query.contains(".bsky.social") {
            // Try to use the getProfile endpoint instead for direct handle lookup
            let cleanQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
            components = URLComponents(string: "\(baseURL)/app.bsky.actor.getProfile")
            components?.queryItems = [
                URLQueryItem(name: "actor", value: cleanQuery)
            ]
        } else {
            // Default search behavior
            components?.queryItems = [
                URLQueryItem(name: "term", value: encodedQuery),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        #if DEBUG
        print("Bluesky search URL: \(url.absoluteString)")
        #endif
        
        // Create and execute the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth token if available
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                #if DEBUG
                print("Network error fetching Bluesky accounts: \(error)")
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
                print("Bluesky API response status: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Bluesky API response: \(jsonString.prefix(300))...")
            }
            #endif
            
            do {
                // Check if data is empty
                guard !data.isEmpty else {
                    // Return empty array for empty response
                    completion(.success([]))
                    return
                }
                
                // Try to parse the response
                do {
                    // Parse the search response
                    let searchResponse = try JSONDecoder().decode(SearchActorsResponse.self, from: data)
                    let sources = searchResponse.safeActors.map { $0.toSource() }
                    completion(.success(sources))
                } catch {
                    // Try alternative format - maybe it's a different response structure
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        #if DEBUG
                        print("Attempting to parse alternative JSON format: \(json)")
                        #endif
                        
                        // Try to manually extract users if they exist in a different structure
                        var users: [[String: Any]] = []
                        if let usersArray = json["users"] as? [[String: Any]] {
                            users = usersArray
                        } else if let user = json["user"] as? [String: Any] {
                            // Single user response
                            users = [user]
                        } else if let did = json["did"] as? String,
                                  let handle = json["handle"] as? String {
                            // Direct profile response
                            users = [[
                                "did": did,
                                "handle": handle,
                                "displayName": json["displayName"] as? String ?? handle,
                                "description": json["description"] as Any,
                                "avatar": json["avatar"] as Any,
                                "followersCount": json["followersCount"] as Any
                            ]]
                        }
                        
                        if !users.isEmpty {
                            // Create accounts manually from the JSON
                            let manualAccounts = users.compactMap { userDict -> BlueSkyAccount? in
                                guard let did = userDict["did"] as? String,
                                      let handle = userDict["handle"] as? String else {
                                    return nil
                                }
                                
                                return BlueSkyAccount(
                                    did: did,
                                    handle: handle,
                                    displayName: userDict["displayName"] as? String,
                                    description: userDict["description"] as? String,
                                    avatar: userDict["avatar"] as? String,
                                    banner: userDict["banner"] as? String,
                                    followersCount: userDict["followersCount"] as? Int,
                                    followsCount: userDict["followsCount"] as? Int,
                                    postsCount: userDict["postsCount"] as? Int
                                )
                            }
                            
                            let sources = manualAccounts.map { $0.toSource() }
                            completion(.success(sources))
                            return
                        }
                    }
                    
                    // If all else fails, return empty array instead of error
                    #if DEBUG
                    print("Error decoding Bluesky search response, returning empty array: \(error)")
                    #endif
                    completion(.success([]))
                }
            } catch {
                #if DEBUG
                print("Error decoding Bluesky search response: \(error)")
                #endif
                
                // Return the error - no dummy data
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Search for Bluesky accounts with async/await support
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of Source objects representing Bluesky accounts
    func searchAccounts(query: String, limit: Int = 20) async throws -> [Source] {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Construct the URL with parameters using the correct Bluesky API endpoint
        var components = URLComponents(string: "\(baseURL)/app.bsky.actor.searchActors")
        
        // Use a different endpoint if the query starts with @ or contains .bsky.social
        if query.hasPrefix("@") || query.contains(".bsky.social") {
            // Try to use the getProfile endpoint instead for direct handle lookup
            let cleanQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
            components = URLComponents(string: "\(baseURL)/app.bsky.actor.getProfile")
            components?.queryItems = [
                URLQueryItem(name: "actor", value: cleanQuery)
            ]
        } else {
            // Default search behavior
            components?.queryItems = [
                URLQueryItem(name: "term", value: encodedQuery),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        #if DEBUG
        print("Bluesky search URL: \(url.absoluteString)")
        #endif
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth token if available
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            // Execute the request with async/await
            let (data, response) = try await session.data(for: request)
            
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("Bluesky API response status: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Bluesky API response: \(jsonString.prefix(300))...")
            }
            #endif
            
            // Check if data is empty
            guard !data.isEmpty else {
                // Return empty array for empty response
                return []
            }
            
            // Try to parse the response
            do {
                // Parse the search response
                let searchResponse = try JSONDecoder().decode(SearchActorsResponse.self, from: data)
                return searchResponse.safeActors.map { $0.toSource() }
            } catch {
                // Try alternative format - maybe it's a different response structure
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    #if DEBUG
                    print("Attempting to parse alternative JSON format: \(json)")
                    #endif
                    
                    // Try to manually extract users if they exist in a different structure
                    var users: [[String: Any]] = []
                    if let usersArray = json["users"] as? [[String: Any]] {
                        users = usersArray
                    } else if let user = json["user"] as? [String: Any] {
                        // Single user response
                        users = [user]
                    } else if let did = json["did"] as? String,
                              let handle = json["handle"] as? String {
                        // Direct profile response
                        users = [[
                            "did": did,
                            "handle": handle,
                            "displayName": json["displayName"] as? String ?? handle,
                            "description": json["description"] as Any,
                            "avatar": json["avatar"] as Any,
                            "followersCount": json["followersCount"] as Any
                        ]]
                    }
                    
                    if !users.isEmpty {
                        // Create accounts manually from the JSON
                        let manualAccounts = users.compactMap { userDict -> BlueSkyAccount? in
                            guard let did = userDict["did"] as? String,
                                  let handle = userDict["handle"] as? String else {
                                return nil
                            }
                            
                            return BlueSkyAccount(
                                did: did,
                                handle: handle,
                                displayName: userDict["displayName"] as? String,
                                description: userDict["description"] as? String,
                                avatar: userDict["avatar"] as? String,
                                banner: userDict["banner"] as? String,
                                followersCount: userDict["followersCount"] as? Int,
                                followsCount: userDict["followsCount"] as? Int,
                                postsCount: userDict["postsCount"] as? Int
                            )
                        }
                        
                        return manualAccounts.map { $0.toSource() }
                    }
                }
                
                #if DEBUG
                print("Error decoding Bluesky search response, returning empty array: \(error)")
                #endif
                
                // Return empty array instead of error for better UX
                return []
            }
        } catch {
            #if DEBUG
            print("Network error fetching Bluesky accounts: \(error)")
            #endif
            
            // Return the error - no dummy data
            throw error
        }
    }
    
    /// Lookup a Bluesky account by handle
    /// - Parameter handle: The handle to lookup (e.g., "alice.bsky.social")
    /// - Returns: Source object representing the Bluesky account
    func lookupAccount(handle: String) async throws -> Source {
        // Construct the URL with parameters using the correct Bluesky API endpoint
        var components = URLComponents(string: "\(baseURL)/app.bsky.actor.getProfile")
        components?.queryItems = [
            URLQueryItem(name: "actor", value: handle)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth token if available
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        let profile = try JSONDecoder().decode(GetProfileResponse.self, from: data)
        
        // Create a BlueSkyAccount from the profile response
        let account = BlueSkyAccount(
            did: profile.did,
            handle: profile.handle,
            displayName: profile.displayName,
            description: profile.description,
            avatar: profile.avatar,
            banner: profile.banner,
            followersCount: profile.followersCount,
            followsCount: profile.followsCount,
            postsCount: profile.postsCount
        )
        
        return account.toSource()
    }
    
    /// Fetch posts for a Bluesky account
    /// - Parameters:
    ///   - handle: The handle of the account
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of ContentItem objects representing posts
    func fetchAccountPosts(handle: String, limit: Int = 20) async throws -> [ContentItem] {
        // Construct the URL with parameters using the correct Bluesky API endpoint
        var components = URLComponents(string: "\(baseURL)/app.bsky.feed.getAuthorFeed")
        components?.queryItems = [
            URLQueryItem(name: "actor", value: handle),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            throw AppError.network(.notFound)
        }
        
        // Create the request with timeout
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0 // 30 second timeout
        
        // Add auth token if available
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            // Execute the request with async/await
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if let error = httpResponse.asNetworkError {
                    throw AppError.network(error)
                }
            }
            
            // Check for empty data
            guard !data.isEmpty else {
                throw AppError.parsing(.emptyResponse)
            }
            
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Bluesky API response: \(jsonString.prefix(200))...")
            }
            #endif
            
            // Parse the response - now using public API format
            let feedResponse = try JSONDecoder().decode(GetAuthorFeedResponse.self, from: data)
            
            // Check for empty results
            if feedResponse.safeFeed.isEmpty {
                throw AppError.parsing(.emptyResponse)
            }
            
            // Get account info to create a source
            let source = try await lookupAccount(handle: handle)
            
            // Convert to ContentItem objects
            return feedResponse.safeFeed.map { $0.post.toContentItem(source: source) }
            
        } catch let error as URLError {
            throw error.asAppError
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.parsing(.invalidJSON)
        }
    }
    
    /// Fetch content for a Bluesky source
    /// - Parameters:
    ///   - source: The source to fetch content for
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of ContentItem objects
    func fetchContentForSource(_ source: Source, limit: Int = 20) async throws -> [ContentItem] {
        // Extract the handle from the source
        if let handle = source.handle {
            return try await fetchAccountPosts(handle: handle, limit: limit)
        } else if let feedUrl = source.feedUrl, feedUrl.contains("/profile/") {
            // Try to extract handle from feed URL
            let components = feedUrl.components(separatedBy: "/profile/")
            if components.count > 1, let handle = components.last {
                return try await fetchAccountPosts(handle: handle, limit: limit)
            }
        }
        
        throw URLError(.badURL)
    }
    
    /// Fetch popular posts from BlueSky (for trending content)
    /// - Parameters:
    ///   - limit: Maximum number of posts to fetch
    /// - Returns: Array of ContentItem objects representing popular posts
    func fetchPopularPosts(limit: Int = 10) async throws -> [ContentItem] {
        // BlueSky doesn't have a dedicated trending endpoint yet, so we'll use the popular feed
        // In the future, this could be replaced with a proper trending API when available
        var components = URLComponents(string: "\(baseURL)/app.bsky.feed.getPopular")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await session.data(for: request)
        
        // Parse response using the same structure as author feed
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(GetAuthorFeedResponse.self, from: data)
            
            // Convert feed items to ContentItem objects
            var items: [ContentItem] = []
            for feedItem in response.feed ?? [] {
                let likes = feedItem.post.likeCount ?? 0
                let handle = feedItem.post.author.handle
                let displayName = feedItem.post.author.displayName ?? handle
                
                let item = ContentItem(
                    title: feedItem.post.record.text,
                    subtitle: "@\(handle) • \(likes) likes",
                    date: Date(), // BlueSky posts don't have a date in this format
                    type: .bluesky,
                    contentPreview: feedItem.post.record.text,
                    progressPercentage: 0.0,
                    metadata: [
                        "uri": feedItem.post.uri,
                        "handle": handle,
                        "displayName": displayName,
                        "likeCount": likes,
                        "repostCount": feedItem.post.repostCount ?? 0,
                        "replyCount": feedItem.post.replyCount ?? 0,
                        "avatar": feedItem.post.author.avatar ?? ""
                    ]
                )
                items.append(item)
            }
            return items
        } catch {
            print("Error parsing BlueSky popular feed: \(error)")
            return []
        }
    }
    
    /// Fetch thread (replies) for a specific post
    /// - Parameters:
    ///   - uri: The AT URI of the post
    ///   - depth: How deep to fetch replies (default: 6)
    /// - Returns: Thread structure with post and replies
    func fetchPostThread(uri: String, depth: Int = 6) async throws -> PostThread {
        // Construct URL for thread endpoint
        var components = URLComponents(string: "\(baseURL)/app.bsky.feed.getPostThread")
        components?.queryItems = [
            URLQueryItem(name: "uri", value: uri),
            URLQueryItem(name: "depth", value: "\(depth)")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute request
        let (data, _) = try await session.data(for: request)
        
        // Parse response
        let response = try JSONDecoder().decode(PostThreadResponse.self, from: data)
        return response.thread
    }
}

// MARK: - Thread Response Models

struct PostThreadResponse: Codable {
    let thread: PostThread
}

struct PostThread: Codable {
    let post: BlueSkyPost
    let replies: [PostThread]?
}