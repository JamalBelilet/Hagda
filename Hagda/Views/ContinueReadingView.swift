import SwiftUI

/// A view that displays all content items the user was previously engaging with
struct ContinueReadingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var continueItems: [ContentItem] = []
    @State private var isRefreshing = false
    @State private var selectedItem: ContentItem?
    @State private var showItemDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if continueItems.isEmpty {
                    emptyStateView
                } else {
                    ForEach(continueItems) { item in
                        VStack(spacing: 0) {
                            // Main row with content and progress
                            Button {
                                selectedItem = item
                                showItemDetail = true
                            } label: {
                                continueItemRow(for: item)
                                    .padding(.bottom, 12)
                            }
                            .buttonStyle(.plain)
                            
                            // Preview of remaining content - separate button with same action
                            Button {
                                selectedItem = item
                                showItemDetail = true
                            } label: {
                                RemainingContentPreview(item: item)
                            }
                            .buttonStyle(.plain)
                            
                            // Add spacing after the entire item
                            if item != continueItems.last {
                                Divider()
                                    .padding(.vertical, 10)
                            }
                            
                            // Add bottom padding for the entire section
                            Spacer()
                                .frame(height: 16)
                        }
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: $showItemDetail) {
                if let item = selectedItem {
                    ContentDetailView(item: item)
                }
            }
        }
        .navigationTitle("Continue Reading")
        .refreshable {
            await refreshContinueItems()
        }
        .onAppear {
            // Generate mocked continue items
            loadContent()
            
            // Set up notification observer for feed refreshes
            setupNotificationObserver()
        }
    }
    
    // Setup notification observer for feed refreshes
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .feedRefreshed,
            object: nil,
            queue: .main
        ) { _ in
            // When the feed is refreshed, update our content
            loadContent()
        }
    }
    
    // Load content items
    private func loadContent() {
        continueItems = generateMockContinueItems()
    }
    
    // Refresh continue items - simulates a network request with async
    private func refreshContinueItems() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate new items
        continueItems = generateMockContinueItems()
    }
    
    // Row for a continue item with progress indicator
    private func continueItemRow(for item: ContentItem) -> some View {
        HStack(spacing: 14) {
            // Type icon with progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: progressValue(for: item))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: item.typeIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(progressText(for: item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron indicator for item row
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
    
    // Empty state when no continue items exist
    private var emptyStateView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                
                Text("Continue Reading")
                    .font(.headline)
                
                Text("Content you've started reading or listening to will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
    
    // Generate mock continue items for demonstration - create more items for this view
    private func generateMockContinueItems() -> [ContentItem] {
        let calendar = Calendar.current
        let now = Date()
        
        // Generate multiple items for each content type for a fuller list
        var items: [ContentItem] = []
        
        // Article items
        items.append(ContentItem(
            title: "The Evolution of Sustainable Technology: Green Tech in 2024",
            subtitle: "From ZDNet • 8 min read",
            date: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
            type: .article,
            contentPreview: """
            The article continues with key sustainable technology trends of 2024:
            
            • How HPE's GreenLake platform is revolutionizing energy-efficient cloud services
            • The rise of carbon-aware computing and its impact on enterprise IT strategy
            • Renewable energy innovations powering next-gen data centers
            • Circular economy principles applied to hardware procurement and disposal
            """,
            progressPercentage: 0.35
        ))
        
        items.append(ContentItem(
            title: "Web Development Frameworks in 2024: What's Hot and What's Not",
            subtitle: "From DEV Community • 12 min read",
            date: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
            type: .article,
            contentPreview: """
            This in-depth analysis continues with framework benchmarks:
            
            • Performance comparison across major JavaScript frameworks
            • Developer experience metrics and community support trends
            • Enterprise adoption patterns and migration strategies
            • Emerging micro-frameworks and their specialized use cases
            """,
            progressPercentage: 0.22
        ))
        
        // Podcast items
        items.append(ContentItem(
            title: "The Vergecast: AI's Role in Reshaping Media Consumption",
            subtitle: "The Vergecast • 30 min remaining",
            date: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
            type: .podcast,
            contentPreview: """
            Coming up in this episode:
            
            • Analysis of how generative AI is changing content creation and consumption
            • Interview with leading AI researcher on multi-modal models and their capabilities
            • Discussion on context window size increases and what they mean for real-world applications
            • Debate on the ethical implications of AI-generated media and potential regulations
            """,
            progressPercentage: 0.65
        ))
        
        items.append(ContentItem(
            title: "This Week in Tech: Apple's New Developer Tools Explained",
            subtitle: "TWiT • 42 min remaining",
            date: calendar.date(byAdding: .hour, value: -12, to: now) ?? now,
            type: .podcast,
            contentPreview: """
            The episode continues with expert analysis on:
            
            • Detailed walkthrough of Apple's new development environment
            • Practical applications of the new machine learning frameworks
            • Cross-platform considerations and compatibility improvements
            • Future roadmap predictions and strategic implications
            """,
            progressPercentage: 0.28
        ))
        
        // Reddit items
        items.append(ContentItem(
            title: "The IT-Security Convergence: Why Your Organization Needs It",
            subtitle: "r/cybersecurity • 15 min read",
            date: calendar.date(byAdding: .hour, value: -6, to: now) ?? now,
            type: .reddit,
            contentPreview: """
            The discussion continues with practical insights:
            
            • Case studies of organizations that successfully merged IT and security teams
            • Key challenges in organizational structure and how to overcome them
            • Training programs to build cross-functional expertise in both domains
            • Metrics that show improved security posture after convergence
            """,
            progressPercentage: 0.42
        ))
        
        items.append(ContentItem(
            title: "I built a low-code tool that automates API testing - looking for feedback",
            subtitle: "r/programming • 8 min read",
            date: calendar.date(byAdding: .hour, value: -24, to: now) ?? now,
            type: .reddit,
            contentPreview: """
            The post continues with the implementation details:
            
            • Technical architecture using Node.js and WebSockets
            • Frontend implementation with React and state management
            • Automated test generation from OpenAPI specifications
            • Performance benchmarks and scalability considerations
            """,
            progressPercentage: 0.51
        ))
        
        // Randomize the order a bit for variety
        return items.shuffled()
    }
    
    // Generate progress value for visual indicator
    private func progressValue(for item: ContentItem) -> CGFloat {
        return CGFloat(item.progressPercentage)
    }
    
    // Generate progress text based on content type
    private func progressText(for item: ContentItem) -> String {
        switch item.type {
        case .article:
            return "\(Int(item.progressPercentage * 100))% completed"
        case .podcast:
            let totalSeconds = 45 * 60 // 45 minutes in seconds
            let remainingSeconds = Int(Double(totalSeconds) * (1 - item.progressPercentage))
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds)) remaining"
        default:
            return "\(Int(item.progressPercentage * 100))% completed"
        }
    }
}

#Preview {
    NavigationStack {
        ContinueReadingView()
            .environment(AppModel())
    }
}