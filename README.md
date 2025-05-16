# Hagda

A minimalist news aggregator app that organizes content from various sources.

## Features

- Clean, minimalist design focused on content
- Navigation between Feed and Library views
- Support for multiple source types:
  - Articles
  - Reddit
  - Bluesky (using public Bluesky API)
  - Mastodon
  - Podcasts
- Source selection from Library for customizable Feed
- Visual indicators for selected sources
- API integrations with multiple content platforms:
  - iTunes Search API for podcasts
  - Reddit API for subreddits
  - Bluesky API for accounts and posts
  - Mastodon API for accounts and statuses

## Architecture

- Modern SwiftUI app using the latest Swift features
- Uses the new Navigation API
- Implements the Observable macro for state management
- Reactive design using SwiftUI's declarative paradigm
- Follows a clean separation of concerns:
  - Models: Data structures and business logic
  - Views: UI components and screens
- Stateful selection mechanism for customizing feed content
- Robust API service layers with async/await support
  
## Testing

- Unit tests for model components
  - Source model validation tests
  - Source type validation tests
  - Category organization tests
  - API integration tests
    - Bluesky API tests
    - Reddit API tests
- UI tests for full app functionality
  - Navigation tests
  - Library content verification
  - Source display verification

## API Integrations

### Bluesky API

The app integrates with Bluesky's public API endpoint `public.api.bsky.app/xrpc` to:
- Search for Bluesky accounts
- View account profiles
- Fetch posts from accounts
- Display posts in the feed

### Reddit API

The app integrates with Reddit's API to:
- Search for subreddits
- Fetch posts from subreddits
- Display posts in the feed

### iTunes Search API

The app integrates with iTunes Search API to:
- Search for podcasts
- Fetch podcast details and episodes
- Display episodes in the feed

### Mastodon API

The app integrates with Mastodon instances to:
- Search for Mastodon accounts
- Fetch statuses from accounts
- Display statuses in the feed

## Getting Started

1. Open the project in Xcode
2. Build and run on a simulator or device
3. Explore the Feed and Library views
4. Try searching for Bluesky accounts, subreddits, podcasts, and Mastodon accounts