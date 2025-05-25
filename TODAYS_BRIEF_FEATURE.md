# Today's Brief Feature - Implementation Plan

## Overview
Today's Brief is a personalized daily summary that aggregates and curates content from all the user's selected sources, presenting the most important updates in a digestible format.

## Core Concept
- **Purpose**: Save users time by providing a curated summary of the day's most important content
- **Update Frequency**: Generated once daily (e.g., 6 AM local time)
- **Content**: Mix of top stories, trending discussions, and new podcast episodes

## Feature Components

### 1. Data Aggregation Engine
```swift
class DailyBriefGenerator {
    // Collects content from all sources
    // Applies ranking algorithms
    // Generates personalized brief
}
```

**Key Functions:**
- Fetch latest content from all selected sources (last 24 hours)
- Apply relevance scoring based on:
  - Source priority (user-defined)
  - Engagement metrics (comments, likes, etc.)
  - Recency
  - User's reading history
  - Content type diversity

### 2. Content Selection Algorithm
**Scoring Factors:**
- **Recency Score** (0-1): How recent is the content?
- **Engagement Score** (0-1): How much interaction does it have?
- **Source Trust Score** (0-1): User's interaction history with source
- **Diversity Score** (0-1): Ensures mix of content types
- **Relevance Score** (0-1): Based on user's reading patterns

**Brief Composition:**
- 3-5 top articles
- 2-3 trending Reddit threads
- 1-2 new podcast episodes
- 2-3 social media highlights
- Total: ~10-12 items maximum

### 3. UI/UX Design

#### Brief Summary Card (Collapsed)
```
┌─────────────────────────────────────┐
│ 📰 Today's Brief                    │
│                                     │
│ 12 stories • 5 min read            │
│                                     │
│ [Preview of top story...]           │
│                                     │
│ Tap to expand ▼                     │
└─────────────────────────────────────┘
```

#### Brief Detail View (Expanded)
```
┌─────────────────────────────────────┐
│ 📰 Today's Brief                    │
│ Monday, May 25, 2025                │
│                                     │
│ TOP STORIES                         │
│ ├─ Apple announces new AI...        │
│ ├─ Breaking: Major security...      │
│ └─ SwiftUI 6.0 released with...     │
│                                     │
│ TRENDING DISCUSSIONS                │
│ ├─ r/swift: "New concurrency..."    │
│ └─ r/apple: "WWDC 2025 wishlist"   │
│                                     │
│ FRESH PODCASTS                      │
│ ├─ Swift Talk: "Actor isolation"   │
│ └─ Accidental Tech: "M4 review"    │
│                                     │
│ SOCIAL HIGHLIGHTS                   │
│ ├─ @johnsundell: "Quick tip..."    │
│ └─ @twostraws: "SwiftUI trick..."  │
└─────────────────────────────────────┘
```

### 4. Smart Features

#### Personalization
- **Reading Time Awareness**: Brief adapts to user's typical reading time
- **Content Preferences**: Learns which types user engages with most
- **Time-of-Day Optimization**: Adjusts when brief is generated based on usage

#### Intelligence Features
- **Duplicate Detection**: Avoid showing same story from multiple sources
- **Thread Continuation**: If user was following a story, include updates
- **Weekend Mode**: Different algorithm for weekends (more long-reads, podcasts)

### 5. Technical Implementation

#### Data Model
```swift
struct DailyBrief: Identifiable {
    let id: UUID
    let date: Date
    let items: [BriefItem]
    let estimatedReadTime: TimeInterval
    let generatedAt: Date
}

struct BriefItem: Identifiable {
    let id: UUID
    let contentItem: ContentItem
    let reason: SelectionReason // Why this was included
    let priority: Int // Display order
    let summary: String? // AI-generated summary
}

enum SelectionReason {
    case topStory
    case trending
    case followUp(to: ContentItem)
    case fromTrustedSource
    case highEngagement
    case editorsPick
}
```

#### Storage Strategy
- Cache daily briefs for 7 days
- Background refresh when app launches
- Push notification option for brief availability

### 6. Advanced Features (Future)

#### AI-Powered Summaries
- Use on-device ML to generate concise summaries
- Highlight key points from long articles
- Extract main discussion points from threads

#### Cross-Content Connections
- Link related stories from different sources
- Show how a story evolved across platforms
- Connect podcast discussions to written articles

#### Customization Options
- Brief length (5 min, 10 min, 15 min)
- Content type preferences
- Delivery time
- Weekend vs. weekday preferences

### 7. Implementation Phases

**Phase 1: Basic Brief (MVP)**
- Simple aggregation of top content
- Basic scoring algorithm
- Static UI component

**Phase 2: Smart Selection**
- Improved scoring with user history
- Duplicate detection
- Better content diversity

**Phase 3: Personalization**
- ML-based recommendations
- Reading pattern analysis
- Time-based optimization

**Phase 4: Advanced Features**
- AI summaries
- Cross-content connections
- Rich notifications

## Success Metrics
- **Engagement Rate**: % of users who open daily brief
- **Completion Rate**: % who read/interact with most items
- **Return Rate**: Daily active users increase
- **Time Saved**: Measured through user feedback
- **Content Discovery**: New sources discovered through brief

## Potential Challenges
1. **Performance**: Generating brief shouldn't slow app launch
2. **Relevance**: Ensuring content is actually important to user
3. **Freshness**: Balancing new content with ongoing stories
4. **Diversity**: Not showing only one type of content
5. **Offline**: Handle cases where brief can't be generated

## User Settings
```swift
struct DailyBriefSettings {
    var isEnabled: Bool = true
    var generationTime: Date = "06:00"
    var maxItems: Int = 10
    var includeWeekends: Bool = true
    var contentTypes: Set<ContentType> = .all
    var estimatedReadTime: TimeInterval = 300 // 5 minutes
    var pushNotifications: Bool = false
}
```

## Future Monetization Options
- **Premium Brief**: AI-powered summaries, unlimited history
- **Brief Scheduling**: Multiple briefs per day
- **Team Briefs**: Shared briefs for organizations
- **Export Options**: Send brief to email, Notion, etc.