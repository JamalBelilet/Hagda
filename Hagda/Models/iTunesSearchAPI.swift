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

/// Service for interacting with the iTunes Search API
class ITunesSearchService {
    private let session: URLSession
    private let baseURL = "https://itunes.apple.com/search"
    
    init(session: URLSession = .shared) {
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
}