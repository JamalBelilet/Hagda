# Testing Podcast Episodes Feature

This document outlines the steps to test the podcast episodes feature on an iPhone 16 simulator.

## Test Plan

1. **Launch the app on iPhone 16 simulator**
   - Open the project in Xcode
   - Select iPhone 16 as the target device
   - Build and run the app (⌘+R)

2. **Test Podcast Listing**
   - Navigate to the "Discover Sources" tab
   - Select "Podcast" in the type selector
   - Verify that podcast sources are displayed correctly

3. **Test Podcast Search**
   - Search for a podcast (e.g., "tech", "news", "development")
   - Verify search results are displayed correctly
   - Add one or more podcasts to your feed

4. **Test Podcast Episodes Display**
   - Navigate to a podcast source from your feed
   - Verify that the list of episodes is displayed
   - Confirm that each episode shows:
     - Episode title
     - Duration
     - Publication date
     - Progress bar (for partially played episodes)
   
5. **Test Episode Details**
   - Tap on an episode to view its details
   - Verify that the episode details are displayed correctly
   - Confirm that navigation works properly

## Expected Results

- The app should display podcast episodes with proper formatting
- The episode list should load asynchronously with a loading indicator
- Each episode should display with the podcast-specific row format
- Episodes should be sorted by publication date (newest first)
- Progress indicators should show correctly for partially played episodes

## Notes

- Since we're using mock data for the podcast episodes (instead of actual RSS parsing), the episodes will be generated with sample data
- In a production app, you would implement full XML parsing for RSS feeds
- The async loading system ensures that the UI remains responsive during data fetching

## Issue Reporting

If any issues are found during testing, please report them with:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots if applicable