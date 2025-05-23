import Foundation
import SwiftUI

/// ViewModel for article detail views
@Observable
class ArticleDetailViewModel {
    // MARK: - Properties
    
    /// The content item to display
    let item: ContentItem
    
    /// Loading state
    var isLoading = false
    
    /// Error state
    var error: Error?
    
    /// Article information
    var title: String = ""
    var sourceName: String = ""
    var authorName: String = ""
    var summary: String = ""
    var fullContent: String = ""
    var formattedDate: String = ""
    
    /// Article progress
    var progressPercentage: Double = 0.0
    var estimatedReadingTime: Int = 0
    var remainingReadingTime: Int = 0
    
    /// Media content
    var hasImage: Bool = false
    var imageURL: URL?
    
    /// Original article link
    var articleURL: URL?
    
    // MARK: - Initialization
    
    init(item: ContentItem) {
        self.item = item
        
        // Set initial values from the content item
        self.title = item.title
        self.summary = item.contentPreview
        self.fullContent = item.contentPreview
        self.progressPercentage = item.progressPercentage
        
        // Extract author and source names from subtitle if available
        // Format: "By Author Name • Source Name"
        if item.subtitle.hasPrefix("By ") {
            let components = item.subtitle.dropFirst(3).components(separatedBy: " • ")
            if components.count > 0 {
                self.authorName = components[0]
            }
            if components.count > 1 {
                self.sourceName = components[1]
            }
        } else if item.subtitle.contains("From ") {
            // Format: "From Source Name"
            if let range = item.subtitle.range(of: "From ") {
                self.sourceName = String(item.subtitle[range.upperBound...])
            }
        } else {
            // Just use the subtitle as is
            self.sourceName = item.subtitle
        }
        
        // Format the date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: item.date, relativeTo: Date())
        
        // Calculate reading time based on word count
        // Average reading speed is about 200-250 words per minute
        let wordCount = summary.split(separator: " ").count
        self.estimatedReadingTime = max(1, wordCount / 200)
        self.remainingReadingTime = Int(ceil(Double(estimatedReadingTime) * (1 - progressPercentage)))
        
        // Load additional details
        loadArticleDetails()
    }
    
    // MARK: - Data Loading
    
    /// Load additional details for an article
    private func loadArticleDetails() {
        Task {
            do {
                self.isLoading = true
                
                // Check if we have metadata from the RSS feed
                let metadata = item.metadata
                
                await MainActor.run {
                    // Set article information from metadata
                    if let articleTitle = metadata["articleTitle"] as? String {
                        self.title = articleTitle
                    }
                    
                    if let sourceName = metadata["sourceName"] as? String {
                        self.sourceName = sourceName
                    }
                    
                    if let author = metadata["articleAuthor"] as? String, !author.isEmpty {
                        self.authorName = author
                    }
                    
                    // Get full content from metadata
                    if let fullContent = metadata["articleContent"] as? String, !fullContent.isEmpty {
                        self.fullContent = fullContent
                        self.summary = fullContent
                    } else if let description = metadata["articleDescription"] as? String, !description.isEmpty {
                        self.fullContent = description
                        self.summary = description
                    }
                    
                    // Set article URL
                    if let articleLink = metadata["articleLink"] as? String,
                       !articleLink.isEmpty {
                        self.articleURL = URL(string: articleLink)
                    }
                    
                    // Set image URL
                    if let imageUrlString = metadata["articleImageUrl"] as? String,
                       !imageUrlString.isEmpty {
                        self.imageURL = URL(string: imageUrlString)
                        self.hasImage = true
                    }
                    
                    // Recalculate reading time based on full content
                    let wordCount = fullContent.split(separator: " ").count
                    self.estimatedReadingTime = max(1, wordCount / 200)
                    self.remainingReadingTime = Int(ceil(Double(estimatedReadingTime) * (1 - progressPercentage)))
                }
                
                self.isLoading = false
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Update the UI with article data
    @MainActor
    private func updateUIWithArticle(_ article: ContentItem) {
        // Update article information
        self.title = article.title
        
        // Use the fuller content preview if available
        if !article.contentPreview.isEmpty && article.contentPreview.count > self.summary.count {
            self.summary = article.contentPreview
            self.fullContent = article.contentPreview
        }
        
        // Update progress if not already set
        if progressPercentage == 0.0 && article.progressPercentage > 0.0 {
            self.progressPercentage = article.progressPercentage
        }
        
        // Recalculate reading time based on word count
        let wordCount = summary.split(separator: " ").count
        self.estimatedReadingTime = max(1, wordCount / 200)
        self.remainingReadingTime = Int(ceil(Double(estimatedReadingTime) * (1 - progressPercentage)))
        
        // Update date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: article.date, relativeTo: Date())
        
        // For demo purposes, we'll pretend to have a link to the full article
        if let host = URL(string: "https://\(sourceName.lowercased().replacingOccurrences(of: " ", with: "")).com") {
            let path = "/\(title.lowercased().replacingOccurrences(of: " ", with: "-"))"
            self.articleURL = URL(string: path, relativeTo: host)
        }
    }
    
    /// Get a summary of the remaining content
    var remainingContentSummary: String {
        if summary.isEmpty {
            return "The article continues with a discussion of implementation details and best practices. Key points include scalability considerations, performance optimizations, and real-world case studies."
        }
        
        let words = summary.split(separator: " ")
        let startIndex = Int(Double(words.count) * progressPercentage)
        
        if startIndex >= words.count - 10 {
            return "The article concludes with final thoughts and recommendations."
        }
        
        let remainingWords = words[startIndex...]
        return remainingWords.joined(separator: " ")
    }
}