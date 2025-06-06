import Foundation

/// Model for the Reddit API search response
struct RedditSearchResponse: Codable {
    let kind: String
    let data: RedditSearchData
    
    struct RedditSearchData: Codable {
        let after: String?
        let dist: Int
        let children: [RedditChild]
        let before: String?
    }
}

/// Model for a Reddit child object in the API response
struct RedditChild: Codable {
    let kind: String
    let data: RedditSubredditData
}

/// Model for a subreddit data returned from the Reddit API
struct RedditSubredditData: Codable {
    let id: String
    let display_name: String
    let title: String?
    let display_name_prefixed: String
    let url: String
    let description: String?
    let public_description: String
    let subscribers: Int?
    let created_utc: Double
    let icon_img: String?
    let community_icon: String?
    let banner_img: String?
    
    // For post content
    let selftext: String?
    let author: String?
    let num_comments: Int?
    
    /// A brief description that includes subscriber count if available
    var formattedDescription: String {
        var result = public_description.isEmpty ? (description ?? "A Reddit community") : public_description
        
        if let subscribers = subscribers, subscribers > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if let formatted = formatter.string(from: NSNumber(value: subscribers)) {
                result += " • \(formatted) subscribers"
            }
        }
        
        return result
    }
    
    /// Convert to app Source model
    func toSource() -> Source {
        return Source(
            name: display_name,
            type: .reddit,
            description: formattedDescription,
            handle: display_name_prefixed,
            artworkUrl: icon_img ?? community_icon ?? banner_img,
            feedUrl: "https://www.reddit.com\(url)"
        )
    }
}

/// Service for interacting with the Reddit API
class RedditAPIService {
    private let session: URLSessionProtocol
    private let baseURL = "https://www.reddit.com"
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    /// Search for subreddits with the given query
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    ///   - completion: Callback with results or error
    func searchSubreddits(query: String, limit: Int = 20, completion: @escaping (Result<[Source], Error>) -> Void) {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/subreddits/search.json")
        components?.queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "raw_json", value: "1") // Get unescaped HTML in responses
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Create and execute the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent") // Reddit API requires a user agent
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RedditSearchResponse.self, from: data)
                let sources = response.data.children.map { $0.data.toSource() }
                completion(.success(sources))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Search for subreddits with async/await support
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of Source objects representing subreddits
    func searchSubreddits(query: String, limit: Int = 20) async throws -> [Source] {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/subreddits/search.json")
        components?.queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "raw_json", value: "1") // Get unescaped HTML in responses
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent") // Reddit API requires a user agent
        
        // Execute the request with async/await
        let (data, _) = try await session.data(for: request)
        
        // Parse the response
        let response = try JSONDecoder().decode(RedditSearchResponse.self, from: data)
        return response.data.children.map { $0.data.toSource() }
    }
    
    /// Response model specifically for subreddit content/posts
    struct RedditPostResponse: Codable {
        let kind: String
        let data: RedditPostData
        
        struct RedditPostData: Codable {
            let after: String?
            let dist: Int?
            let children: [RedditPostChild]
            let before: String?
        }
    }
    
    /// Child model for posts
    struct RedditPostChild: Codable {
        let kind: String
        let data: RedditPostChildData
    }
    
    /// Data model for post content
    struct RedditPostChildData: Codable {
        let id: String
        let title: String
        let author: String?
        let selftext: String?
        let created_utc: Double
        let num_comments: Int
        let subreddit: String
        let subreddit_name_prefixed: String
        let ups: Int?
        let downs: Int?
        let url: String?
        let permalink: String?
        
        // Allow for missing fields
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            author = try container.decodeIfPresent(String.self, forKey: .author)
            selftext = try container.decodeIfPresent(String.self, forKey: .selftext)
            created_utc = try container.decode(Double.self, forKey: .created_utc)
            num_comments = try container.decodeIfPresent(Int.self, forKey: .num_comments) ?? 0
            subreddit = try container.decode(String.self, forKey: .subreddit)
            subreddit_name_prefixed = try container.decode(String.self, forKey: .subreddit_name_prefixed)
            ups = try container.decodeIfPresent(Int.self, forKey: .ups)
            downs = try container.decodeIfPresent(Int.self, forKey: .downs)
            url = try container.decodeIfPresent(String.self, forKey: .url)
            permalink = try container.decodeIfPresent(String.self, forKey: .permalink)
        }
    }
    
    /// Reddit comment data model
    struct RedditComment {
        let id: String
        let author: String?
        let body: String?
        let created_utc: Double
        let ups: Int
        let depth: Int
        let replies: [RedditComment]
    }
    
    /// Fetch comments for a Reddit post
    /// - Parameters:
    ///   - subreddit: The subreddit name
    ///   - postId: The post ID (without t3_ prefix)
    ///   - limit: Maximum number of top-level comments
    /// - Returns: Array of comment data with nested replies
    func fetchPostComments(subreddit: String, postId: String, limit: Int = 100) async throws -> [RedditComment] {
        // Clean subreddit name
        let cleanSubreddit = subreddit.starts(with: "r/") ? String(subreddit.dropFirst(2)) : subreddit
        
        // Construct URL
        let url = URL(string: "\(baseURL)/r/\(cleanSubreddit)/comments/\(postId).json?limit=\(limit)&raw_json=1")!
        
        // Create request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute request
        let (data, _) = try await session.data(for: request)
        
        // Parse JSON as generic structure first
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              json.count > 1,
              let commentsListing = json[1] as? [String: Any],
              let commentsData = commentsListing["data"] as? [String: Any],
              let children = commentsData["children"] as? [[String: Any]] else {
            return []
        }
        
        // Parse comments recursively
        return parseComments(from: children, depth: 0)
    }
    
    /// Recursively parse Reddit comments from JSON
    private func parseComments(from children: [[String: Any]], depth: Int) -> [RedditComment] {
        return children.compactMap { child in
            guard let kind = child["kind"] as? String,
                  kind == "t1",
                  let data = child["data"] as? [String: Any] else {
                return nil
            }
            
            let id = data["id"] as? String ?? ""
            let author = data["author"] as? String
            let body = data["body"] as? String
            let created_utc = data["created_utc"] as? Double ?? 0
            let ups = data["ups"] as? Int ?? 0
            
            // Parse nested replies
            var nestedReplies: [RedditComment] = []
            if let replies = data["replies"] as? [String: Any],
               let repliesData = replies["data"] as? [String: Any],
               let repliesChildren = repliesData["children"] as? [[String: Any]] {
                nestedReplies = parseComments(from: repliesChildren, depth: depth + 1)
            }
            
            return RedditComment(
                id: id,
                author: author,
                body: body,
                created_utc: created_utc,
                ups: ups,
                depth: depth,
                replies: nestedReplies
            )
        }
    }
    
    /// Fetch hot posts from a subreddit (for trending content)
    /// - Parameters:
    ///   - subreddit: The name of the subreddit (without "r/")
    ///   - limit: Maximum number of results (default: 10)
    /// - Returns: Array of ContentItem objects representing hot posts
    func fetchHotPosts(subreddit: String, limit: Int = 10) async throws -> [ContentItem] {
        // Use the existing fetchSubredditContent method which already fetches hot posts
        return try await fetchSubredditContent(subredditName: subreddit, limit: limit)
    }
    
    /// Fetch posts from a subreddit
    /// - Parameters:
    ///   - subredditName: The name of the subreddit (without "r/")
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of ContentItem objects representing posts
    func fetchSubredditContent(subredditName: String, limit: Int = 20) async throws -> [ContentItem] {
        // Ensure we handle the subreddit name correctly
        let cleanName = subredditName.starts(with: "r/") ? String(subredditName.dropFirst(2)) : subredditName
        
        // Construct the URL with parameters
        var components = URLComponents(string: "\(baseURL)/r/\(cleanName)/hot.json")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "raw_json", value: "1") // Get unescaped HTML in responses
        ]
        
        guard let url = components?.url else {
            throw AppError.network(.notFound)
        }
        
        // Create the request with timeout
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent") // Reddit API requires a user agent
        request.timeoutInterval = 30.0 // 30 second timeout
        
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
            // Print the JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Reddit API response: \(jsonString.prefix(200))...")
            }
            #endif
            
            // Parse the response using the posts-specific model
            let redditResponse = try JSONDecoder().decode(RedditPostResponse.self, from: data)
            
            // Check for empty results
            if redditResponse.data.children.isEmpty {
                throw AppError.parsing(.emptyResponse)
            }
            
            // Convert to ContentItem objects
            let items = redditResponse.data.children.compactMap { child -> ContentItem? in
                let post = child.data
                
                // Create a date from the UTC timestamp
                let date = Date(timeIntervalSince1970: post.created_utc)
                
                // Generate a content preview from the post selftext if available
                let contentPreview = post.selftext ?? "No content available for this post."
                
                return ContentItem(
                    title: post.title,
                    subtitle: "Posted by u/\(post.author ?? "unknown") • \(post.num_comments) comments",
                    date: date,
                    type: .reddit,
                    contentPreview: contentPreview,
                    progressPercentage: 0.0, // New posts start with 0 progress
                    metadata: [
                        "postId": post.id,
                        "author": post.author ?? "unknown",
                        "subreddit": post.subreddit,
                        "subredditPrefixed": post.subreddit_name_prefixed,
                        "ups": post.ups ?? 0,
                        "downs": post.downs ?? 0,
                        "numComments": post.num_comments,
                        "url": post.url ?? "",
                        "permalink": post.permalink ?? "",
                        "selftext": post.selftext ?? ""
                    ]
                )
            }
            
            // Ensure we have at least some items
            guard !items.isEmpty else {
                throw AppError.parsing(.emptyResponse)
            }
            
            return items
            
        } catch let error as URLError {
            throw error.asAppError
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.parsing(.invalidJSON)
        }
    }
}