import Foundation

/// Model for the iTunes Search API response
struct ITunesSearchResponse: Codable {
    let resultCount: Int
    let results: [ITunesPodcast]
}

/// Model for a podcast returned from the iTunes Search API
struct ITunesPodcast: Codable, Identifiable {
    let wrapperType: String
    let kind: String?
    let collectionId: Int
    let trackId: Int?
    let artistName: String
    let collectionName: String
    let trackName: String?
    let collectionCensoredName: String?
    let trackCensoredName: String?
    let collectionViewUrl: String?
    let feedUrl: String?
    let trackViewUrl: String?
    let artworkUrl30: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl600: String?
    let collectionPrice: Double?
    let trackPrice: Double?
    let trackRentalPrice: Double?
    let collectionHdPrice: Double?
    let trackHdPrice: Double?
    let trackHdRentalPrice: Double?
    let releaseDate: String?
    let collectionExplicitness: String?
    let trackExplicitness: String?
    let trackCount: Int?
    let country: String?
    let currency: String?
    let primaryGenreName: String?
    let contentAdvisoryRating: String?
    let genreIds: [String]?
    let genres: [String]?
    
    /// Computed property for ID to conform to Identifiable
    var id: Int { collectionId }
    
    /// A brief description for the podcast, combining relevant info
    var description: String {
        var descriptionParts: [String] = []
        
        if let primaryGenreName = primaryGenreName, !primaryGenreName.isEmpty {
            descriptionParts.append(primaryGenreName)
        }
        
        if let trackCount = trackCount {
            descriptionParts.append("\(trackCount) episodes")
        }
        
        if let country = country, !country.isEmpty {
            descriptionParts.append("from \(country)")
        }
        
        return descriptionParts.isEmpty ? "Podcast by \(artistName)" : descriptionParts.joined(separator: " • ")
    }
    
    /// Factory method to convert iTunes podcast to app Source
    func toSource() -> Source {
        return Source(
            name: collectionName,
            type: .podcast,
            description: description,
            handle: "by \(artistName)",
            artworkUrl: artworkUrl600 ?? artworkUrl100 ?? artworkUrl60 ?? artworkUrl30,
            feedUrl: feedUrl
        )
    }
}

/// Model for a podcast episode
struct PodcastEpisode: Codable, Identifiable {
    let guid: String
    let title: String
    let description: String
    let pubDate: String
    let enclosure: Enclosure?
    let duration: String?
    let link: String?
    let author: String?
    let summary: String?
    let image: String?
    
    /// Unique identifier for conforming to Identifiable
    var id: String { guid }
    
    /// Episode URL from enclosure
    var audioUrl: String? { enclosure?.url }
    
    /// Duration in user-friendly format
    var formattedDuration: String {
        guard let durationStr = duration else { return "Unknown length" }
        
        // If it's just seconds as a string (e.g., "3600")
        if let seconds = Int(durationStr) {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            // let remainingSeconds = seconds % 60  // Unused for now
            
            if hours > 0 {
                return "\(hours) hr \(minutes) min"
            } else if minutes > 0 {
                return "\(minutes) min"
            } else {
                return "\(seconds) sec"
            }
        }
        
        // If it's in format HH:MM:SS
        let components = durationStr.split(separator: ":").map { String($0) }
        if components.count == 3 {
            let hours = Int(components[0]) ?? 0
            let minutes = Int(components[1]) ?? 0
            
            if hours > 0 {
                return "\(hours) hr \(minutes) min"
            } else {
                return "\(minutes) min"
            }
        } else if components.count == 2 {
            let minutes = Int(components[0]) ?? 0
            return "\(minutes) min"
        }
        
        return durationStr
    }
    
    /// Publication date as a Date object
    var publicationDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = formatter.date(from: pubDate) {
            return date
        }
        
        // Try alternative format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: pubDate)
    }
    
    /// Enclosure for audio files
    struct Enclosure: Codable {
        let url: String
        let type: String?
        let length: String?
    }
    
    /// Factory method to convert to ContentItem
    func toContentItem(podcastSource: Source) -> ContentItem {
        return ContentItem(
            title: title,
            subtitle: formattedDuration,
            date: publicationDate ?? Date(),
            type: .podcast,
            contentPreview: description.isEmpty ? summary ?? "" : description,
            progressPercentage: 0.0,
            metadata: [
                "episodeGuid": guid,
                "episodeTitle": title,
                "episodeDescription": description,
                "episodeSummary": summary ?? "",
                "episodeDuration": duration ?? "",
                "episodeFormattedDuration": formattedDuration,
                "episodePubDate": pubDate,
                "episodeLink": link ?? "",
                "episodeAuthor": author ?? "",
                "episodeImageUrl": image ?? "",
                "audioUrl": audioUrl ?? "",
                "audioType": enclosure?.type ?? "audio/mpeg",
                "audioLength": enclosure?.length ?? "",
                "podcastName": podcastSource.name,
                "podcastArtworkUrl": podcastSource.artworkUrl ?? "",
                "podcastFeedUrl": podcastSource.feedUrl ?? ""
            ]
        )
    }
}

/// RSS feed response for podcast episodes
struct PodcastFeed: Codable {
    let channel: Channel
    
    struct Channel: Codable {
        let title: String
        let description: String
        let link: String
        let image: Image?
        let item: [PodcastEpisode]
    }
    
    struct Image: Codable {
        let url: String
        let title: String?
        let link: String?
    }
}

/// Service for interacting with the iTunes Search API
class ITunesSearchService {
    private let session: URLSessionProtocol
    private let baseURL = "https://itunes.apple.com/search"
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    /// Search for podcasts with the given query
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    ///   - completion: Callback with results or error
    func searchPodcasts(query: String, limit: Int = 20, completion: @escaping (Result<[Source], Error>) -> Void) {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Construct the URL with parameters
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "term", value: encodedQuery),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Create and execute the request
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
                let sources = response.results.map { $0.toSource() }
                completion(.success(sources))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Search for podcasts with async/await support
    /// - Parameters:
    ///   - query: The search term
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Array of Source objects representing podcasts
    func searchPodcasts(query: String, limit: Int = 20) async throws -> [Source] {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        // Construct the URL with parameters
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "term", value: encodedQuery),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        // Execute the request with async/await
        let (data, _) = try await session.data(from: url)
        
        // Parse the response
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        return response.results.map { $0.toSource() }
    }
    
    /// Fetch top podcasts from iTunes charts
    /// - Parameters:
    ///   - limit: Maximum number of podcasts to fetch
    /// - Returns: Array of ContentItem objects representing top podcasts
    func fetchTopPodcasts(limit: Int = 10) async throws -> [ContentItem] {
        // Use iTunes RSS feed for top podcasts
        let topPodcastsURL = "https://itunes.apple.com/us/rss/toppodcasts/limit=\(limit)/json"
        
        guard let url = URL(string: topPodcastsURL) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await session.data(from: url)
        
        // Parse the iTunes RSS feed JSON format
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let feed = json["feed"] as? [String: Any],
           let entries = feed["entry"] as? [[String: Any]] {
            
            return entries.compactMap { entry in
                guard let title = (entry["im:name"] as? [String: Any])?["label"] as? String,
                      let artist = (entry["im:artist"] as? [String: Any])?["label"] as? String,
                      let summary = (entry["summary"] as? [String: Any])?["label"] as? String,
                      let images = entry["im:image"] as? [[String: Any]],
                      let largestImage = images.last,
                      let imageUrl = largestImage["label"] as? String else {
                    return nil
                }
                
                // Create a pseudo-source for the podcast
                let source = Source(
                    name: title,
                    type: .podcast,
                    description: summary,
                    handle: "by \(artist)",
                    artworkUrl: imageUrl
                )
                
                return ContentItem(
                    title: title,
                    subtitle: artist,
                    description: summary,
                    date: Date(), // Top charts are current
                    type: .podcast,
                    contentPreview: summary,
                    progressPercentage: 0.0,
                    metadata: [
                        "artist": artist,
                        "imageUrl": imageUrl
                    ],
                    source: source
                )
            }
        }
        
        return []
    }
    
    /// Fetch podcast episodes from RSS feed
    /// - Parameter feedUrl: URL to the podcast's RSS feed
    /// - Returns: Array of ContentItem objects representing episodes
    func fetchPodcastEpisodes(from feedUrl: String, source: Source) async throws -> [ContentItem] {
        guard let url = URL(string: feedUrl) else {
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.setValue("Hagda/1.0", forHTTPHeaderField: "User-Agent")
        
        // Execute the request with async/await
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse, 
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the XML data into podcast episodes
        #if DEBUG
        print("Fetched \(data.count) bytes from podcast feed")
        #endif
        
        // Convert data to string for parsing
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        // Define regex patterns for extracting podcast episode information
        let itemPattern = "<item>[\\s\\S]*?<\\/item>"
        let titlePattern = "<title>(.*?)<\\/title>"
        let descPattern = "<description><!\\[CDATA\\[(.*?)\\]\\]><\\/description>|<description>(.*?)<\\/description>"
        let pubDatePattern = "<pubDate>(.*?)<\\/pubDate>"
        let guidPattern = "<guid[^>]*>(.*?)<\\/guid>"
        let durationPattern = "<itunes:duration>(.*?)<\\/itunes:duration>"
        let enclosurePattern = "<enclosure url=\"([^\"]*)\"[^>]*>"
        let summaryPattern = "<itunes:summary><!\\[CDATA\\[(.*?)\\]\\]><\\/itunes:summary>|<itunes:summary>(.*?)<\\/itunes:summary>"
        
        // Create regex objects
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern),
              let titleRegex = try? NSRegularExpression(pattern: titlePattern),
              let descRegex = try? NSRegularExpression(pattern: descPattern),
              let pubDateRegex = try? NSRegularExpression(pattern: pubDatePattern),
              let guidRegex = try? NSRegularExpression(pattern: guidPattern),
              let durationRegex = try? NSRegularExpression(pattern: durationPattern),
              let enclosureRegex = try? NSRegularExpression(pattern: enclosurePattern),
              let summaryRegex = try? NSRegularExpression(pattern: summaryPattern) else {
            throw URLError(.cannotParseResponse)
        }
        
        // Find all item tags in the XML
        let nsString = xmlString as NSString
        let itemMatches = itemRegex.matches(in: xmlString, range: NSRange(location: 0, length: nsString.length))
        
        #if DEBUG
        print("Found \(itemMatches.count) episodes in podcast feed")
        #endif
        
        // Stop here if no episodes were found
        if itemMatches.isEmpty {
            return []
        }
        
        // Parse each episode
        var episodes: [PodcastEpisode] = []
        
        for itemMatch in itemMatches {
            let itemXml = nsString.substring(with: itemMatch.range)
            let itemNSString = itemXml as NSString
            
            // Extract title
            var title = "Untitled Episode"
            if let titleMatch = titleRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                title = itemNSString.substring(with: titleMatch.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")
            }
            
            // Extract description (handles both CDATA and regular format)
            var description = ""
            if let descMatch = descRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                // Try CDATA version first (range 1)
                if descMatch.range(at: 1).location != NSNotFound {
                    description = itemNSString.substring(with: descMatch.range(at: 1))
                } 
                // Try regular version (range 2)
                else if descMatch.numberOfRanges > 2 && descMatch.range(at: 2).location != NSNotFound {
                    description = itemNSString.substring(with: descMatch.range(at: 2))
                }
                description = description.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract summary
            var summary = ""
            if let summaryMatch = summaryRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                // Try CDATA version first (range 1)
                if summaryMatch.range(at: 1).location != NSNotFound {
                    summary = itemNSString.substring(with: summaryMatch.range(at: 1))
                } 
                // Try regular version (range 2)
                else if summaryMatch.numberOfRanges > 2 && summaryMatch.range(at: 2).location != NSNotFound {
                    summary = itemNSString.substring(with: summaryMatch.range(at: 2))
                }
                summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract publication date
            var pubDate = "Thu, 01 Jan 1970 00:00:00 +0000"
            if let dateMatch = pubDateRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                pubDate = itemNSString.substring(with: dateMatch.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract GUID
            var guid = UUID().uuidString // Default to random UUID
            if let guidMatch = guidRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                guid = itemNSString.substring(with: guidMatch.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract duration
            var duration: String? = nil
            if let durationMatch = durationRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                duration = itemNSString.substring(with: durationMatch.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract enclosure URL
            var enclosure: PodcastEpisode.Enclosure? = nil
            if let enclosureMatch = enclosureRegex.firstMatch(in: itemXml, range: NSRange(location: 0, length: itemXml.count)) {
                let url = itemNSString.substring(with: enclosureMatch.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                enclosure = PodcastEpisode.Enclosure(url: url, type: "audio/mpeg", length: nil)
            }
            
            // Create episode object
            let episode = PodcastEpisode(
                guid: guid,
                title: title,
                description: description,
                pubDate: pubDate,
                enclosure: enclosure,
                duration: duration,
                link: nil,
                author: nil,
                summary: summary,
                image: nil
            )
            
            episodes.append(episode)
        }
        
        // If no episodes were successfully parsed, return empty array
        if episodes.isEmpty {
            #if DEBUG
            print("No episodes parsed successfully")
            #endif
            return []
        }
        
        // Convert PodcastEpisode objects to ContentItem objects
        #if DEBUG
        print("Successfully parsed \(episodes.count) podcast episodes")
        // Print first episode as sample
        if let first = episodes.first {
            print("First episode: \(first.title) - \(first.formattedDuration)")
        }
        #endif
        
        return episodes.map { $0.toContentItem(podcastSource: source) }
    }
    
}