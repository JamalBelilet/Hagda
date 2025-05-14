# Hagda

A minimalist news aggregator app that organizes content from various sources.

## Features

- Clean, minimalist design focused on content
- Navigation between Feed and Library views
- Support for multiple source types:
  - Articles
  - Reddit
  - Bluesky
  - Mastodon
  - Podcasts
- Source selection from Library for customizable Feed
- Visual indicators for selected sources

## Architecture

- Modern SwiftUI app using the latest Swift features
- Uses the new Navigation API
- Implements the Observable macro for state management
- Reactive design using SwiftUI's declarative paradigm
- Follows a clean separation of concerns:
  - Models: Data structures and business logic
  - Views: UI components and screens
- Stateful selection mechanism for customizing feed content
  
## Testing

- Unit tests for model components
  - Source model validation tests
  - Source type validation tests
  - Category organization tests
- UI tests for full app functionality
  - Navigation tests
  - Library content verification
  - Source display verification

## Getting Started

1. Open the project in Xcode
2. Build and run on a simulator or device
3. Explore the Feed and Library views