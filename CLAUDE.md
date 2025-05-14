# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hagda is a SwiftUI application for macOS/iOS. The project is set up with a standard Apple Xcode project structure and uses SwiftUI for its UI components.

## Build and Run

To build and run the application:

```bash
# Open the project in Xcode
open Hagda.xcodeproj

# Alternatively, build from command line
xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug build

# Run the application (requires specifying a destination)
xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug run -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Testing

The project has both unit tests and UI tests set up:

```bash
# Run all tests
xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug test

# Run specific test class
xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug test -only-testing:HagdaTests/HagdaTests

# Run UI tests
xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug test -only-testing:HagdaUITests/HagdaUITests
```

## Architecture

The application follows a standard SwiftUI architecture:

- `HagdaApp.swift`: Entry point for the application that sets up the main window and scene
- `ContentView.swift`: Main view of the application

The project is in its initial state with minimal implementation.

## SwiftUI Development Tips

When working with SwiftUI in this project:

- Use SwiftUI previews for rapid UI development
- The project uses the SwiftUI app lifecycle (no AppDelegate)
- For unit tests, the project uses the new Swift Testing framework
- For UI tests, the project uses XCTest with XCUIApplication