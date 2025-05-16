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
            progressPercentage: 0.0
        )
    }
}

// Note: We're using a simplified approach for Bluesky API handling
// In a production app, we would implement more robust JSON parsing,
// but for demo purposes we're keeping it simple with direct decoding.

/// Models for Bluesky API responses
struct SearchActorsResponse: Codable {
    let actors: [BlueSkyAccount]
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
    let feed: [FeedItem]
    let cursor: String?
    
    struct FeedItem: Codable {
        let post: BlueSkyPost
    }
}

/// Service for interacting with the Bluesky API
class BlueSkyAPIService {
    private let session: URLSession
    private let baseURL = "https://bsky.social/xrpc"
    
    // Authentication state
    private var accessToken: String?
    private var refreshToken: String?
    
    init(session: URLSession = .shared) {
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
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/app.bsky.actor.searchActors")
        components?.queryItems = [
            URLQueryItem(name: "term", value: encodedQuery),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
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
                // Parse the search response
                let searchResponse = try JSONDecoder().decode(SearchActorsResponse.self, from: data)
                let sources = searchResponse.actors.map { $0.toSource() }
                completion(.success(sources))
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
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/app.bsky.actor.searchActors")
        components?.queryItems = [
            URLQueryItem(name: "term", value: encodedQuery),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
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
            
            // Try to parse the response
            do {
                // Parse the search response
                let searchResponse = try JSONDecoder().decode(SearchActorsResponse.self, from: data)
                return searchResponse.actors.map { $0.toSource() }
            } catch {
                #if DEBUG
                print("Error decoding Bluesky search response: \(error)")
                #endif
                
                // Return the error - no dummy data
                throw error
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
        // Construct the URL with parameters
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
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/app.bsky.feed.getAuthorFeed")
        components?.queryItems = [
            URLQueryItem(name: "actor", value: handle),
            URLQueryItem(name: "limit", value: "\(limit)")
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
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Bluesky API response: \(jsonString.prefix(200))...")
        }
        #endif
        
        // Parse the response
        let feedResponse = try JSONDecoder().decode(GetAuthorFeedResponse.self, from: data)
        
        // Get account info to create a source
        let source = try await lookupAccount(handle: handle)
        
        // Convert to ContentItem objects
        return feedResponse.feed.map { $0.post.toContentItem(source: source) }
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
}