# Onboarding Source Selection Fix

## Issue
Sources selected during onboarding were not appearing in the feed after onboarding completion. 

## Root Cause
The core issue was UUID regeneration. When the same source was created twice (once during onboarding and once in the app model), they received different random UUIDs. This meant that while sources were being "selected" during onboarding, the IDs saved to `appModel.selectedSources` didn't match any source IDs in the main app catalog.

## Solution Implemented

1. **Deterministic IDs**: Modified `Source` struct initialization to generate consistent UUIDs based on source properties:
   ```swift
   // Generate a deterministic ID based on name and type
   var hasher = Hasher()
   hasher.combine(name)
   hasher.combine(type.rawValue)
   if let handle = handle {
       hasher.combine(handle)
   }
   let hashValue = hasher.finalize()
   self.id = UUID(uuid: (/* hash bits... */))
   ```

2. **Improved Source Matching**: Added `findSource` method to locate existing sources by name and type:
   ```swift
   func findSource(name: String, type: SourceType) -> Source? {
       return sources.first { $0.name == name && $0.type == type }
   }
   ```

3. **Smarter Source Selection in Onboarding**: Updated `completeOnboarding()` to properly match sources:
   ```swift
   for selectedSource in selectedSources {
       if let existingSource = appModel.findSource(name: selectedSource.name, type: selectedSource.type) {
           appModel.selectedSources.insert(existingSource.id)
       } else {
           appModel.sources.append(selectedSource)
           appModel.selectedSources.insert(selectedSource.id)
       }
   }
   ```

4. **Better Debugging**: Added debug logging statements to trace source selection:
   ```swift
   print("DEBUG: Selected sources count: \(appModel.selectedSources.count)")
   print("DEBUG: Feed sources count: \(appModel.feedSources.count)")
   for source in appModel.sources {
       if appModel.selectedSources.contains(source.id) {
           print("DEBUG: Selected source: \(source.name) (ID: \(source.id))")
       }
   }
   ```

## Benefits
- Sources now maintain consistent IDs throughout the app, solving the onboarding selection issue
- Improved source matching eliminates duplicate entries when the same source is selected multiple times
- Better handling of dynamically-discovered sources from search results
- Enhanced debugging capabilities make it easier to trace selection state issues