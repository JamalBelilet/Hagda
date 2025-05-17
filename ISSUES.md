# GitHub Issues for Improving Hagda Tests

## Issue 1: Fix UI Tests with Robust Accessibility Identifiers

**Title:** Fix UI Tests with Robust Accessibility Identifiers

**Description:**
The current UI tests are failing due to inconsistent accessibility identifiers and navigation references. These tests need to be updated to work reliably across different platforms.

**Steps to reproduce:**
1. Run `xcodebuild -project Hagda.xcodeproj -scheme Hagda -configuration Debug test -only-testing:HagdaUITests/MinimalNavigationTest`
2. Observe test failures when trying to locate UI elements

**Current issues:**
- Tests are using different approaches to find elements: some use navigation bar titles, others use button indices
- Element lookup fails because accessibility identifiers are not consistently applied
- Platform-specific UI elements are not properly handled (iOS vs macOS)

**Tasks:**
- [ ] Update all UI tests to use consistent accessibility identifiers
- [ ] Add `.accessibilityIdentifier()` to all key UI elements in views
- [ ] Create a helper struct for centralized management of accessibility identifiers
- [ ] Consider using XCUIApplication snapshot to debug element hierarchy during test failures
- [ ] Update UI tests to run reliably on both macOS and iOS platforms

**Technical details:**
In `MinimalNavigationTest.swift` and other UI test files, tests are failing when trying to find buttons and navigation elements using identifiers or indices. We need a more systematic approach to accessibility in the app.

**Priority:** Medium

## Issue 2: Improve Network Testing Architecture

**Title:** Improve Network Testing Architecture with Protocol-Based Mocking

**Description:**
While we've implemented a shared mocking system for network tests, there's room for improvement in the overall testing architecture. The current implementation has some inconsistencies and could benefit from refinements.

**Current state:**
- We've created a `URLSessionProtocol` and shared mock implementations
- API service classes now use this protocol instead of concrete URLSession
- Test classes import the shared mocks correctly

**Improvement tasks:**
- [ ] Enhance `SharedMocks.swift` with additional helper methods for common test scenarios
- [ ] Add support for testing multiple sequential network requests
- [ ] Create a dedicated NetworkingTests suite to test the protocol implementation directly
- [ ] Document the networking test architecture in a README or wiki
- [ ] Consider implementing a more sophisticated request recording/replaying system for complex tests

**Technical details:**
The shared mocking system works, but could be enhanced with features like:
- Response queuing for sequential requests
- Request validation to ensure proper URLs and headers
- Simulated network conditions (delays, throttling)
- Better error simulation and handling

**Priority:** Low

## Issue 3: Add Integration Tests for NewsAPI RSS Functionality

**Title:** Add Integration Tests for NewsAPI RSS Functionality

**Description:**
While we have unit tests for the NewsAPI functionality, we should add integration tests to verify the entire RSS feed discovery and article fetching workflow functions correctly from end to end.

**Tasks:**
- [ ] Create integration tests that verify RSS discovery from website URLs
- [ ] Add tests for converting RSS feed items to ContentItem objects
- [ ] Test error handling and fallback mechanisms for malformed XML
- [ ] Create tests for the keyword search functionality
- [ ] Test feed parsing with real-world RSS examples from major publications

**Technical approach:**
1. Create a new test file `NewsAPIIntegrationTests.swift`
2. Use mock responses simulating complete discovery → feed → article workflow
3. Test both synchronous and asynchronous API variants
4. Verify proper error handling and debug fallbacks

**Priority:** Medium

## Issue 4: Unify Cross-Platform UI Testing Strategy

**Title:** Unify Cross-Platform UI Testing Strategy

**Description:**
The app needs to run on both macOS and iOS/iPadOS, but our UI tests are not well-designed for cross-platform testing. We need a consistent approach that works across all platforms.

**Tasks:**
- [ ] Create a platform abstraction layer for UI tests
- [ ] Use conditional compilation for platform-specific test code
- [ ] Implement a unified accessibility identifier system
- [ ] Verify all UI tests pass on both macOS and iOS simulators
- [ ] Add documentation for maintaining cross-platform tests

**Implementation details:**
```swift
// Example of platform abstraction for tests
#if os(iOS) || os(visionOS)
    let navBarIdentifier = "iOSNavigationBar"
#else
    let navBarIdentifier = "macOSNavigationBar"
#endif

// Test with platform independence
XCTAssertTrue(app.navigationBars[navBarIdentifier].exists)
```

**Priority:** High

## Issue 5: Implement User Onboarding Flow

**Title:** Implement Minimalistic User Onboarding Experience

**Description:**
Currently, new users are dropped directly into the app without guidance, potentially seeing empty states and having no clear direction on how to start using Hagda effectively. We need a streamlined onboarding experience that helps users set up their content sources and customize their experience while maintaining the app's minimalist design approach.

**Current state:**
- No onboarding flow exists
- New users may see empty states if they don't immediately discover how to add sources
- Users may not discover the daily brief customization options
- App relies on mocked data for initial user experience

**Tasks:**
- [ ] Create a multi-step onboarding flow using SwiftUI's latest navigation capabilities
- [ ] Design source selection UI that presents popular/recommended sources for quick selection
- [ ] Integrate daily brief customization into the onboarding flow
- [ ] Implement search functionality for finding specific sources during onboarding
- [ ] Add persistence layer to save onboarding completion status
- [ ] Create smooth transition from onboarding to main app experience
- [ ] Remove mocked data once user has completed onboarding

**Technical approach:**
1. Create an `OnboardingCoordinator` class to manage the flow state
2. Use `TabView` with `.tabViewStyle(.page)` for step navigation
3. Implement `@Observable` state management for the onboarding process
4. Add `isOnboardingComplete` flag to `AppModel`
5. Use `AppStorage` for persisting onboarding completion status
6. Create specialized versions of existing views for the onboarding context:
   - `OnboardingSourceSelectionView` based on `CombinedLibraryView`
   - `OnboardingDailySummarySetupView` based on `DailySummarySettingsView`
7. Add welcome and completion screens to bookend the experience

**UI/UX considerations:**
- Keep the flow to 3-4 screens maximum (Welcome, Source Selection, Daily Brief Setup, Completion)
- Use progressive disclosure to avoid overwhelming new users
- Include skip options while ensuring users have minimum viable content
- Use animations and transitions that match the app's design language
- Ensure cross-platform compatibility (iOS and macOS)

**Accessibility:**
- All onboarding screens must maintain proper accessibility support
- Add appropriate accessibility identifiers to support automated testing
- Ensure keyboard navigation works for macOS users

**Priority:** High