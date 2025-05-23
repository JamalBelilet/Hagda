# Info.plist Requirements for App Store Submission

The following keys and values need to be added to the Info.plist file through Xcode's project settings:

## Privacy Permissions

### NSAppTransportSecurity
Configure App Transport Security to ensure secure connections:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### Network Usage Description
```xml
<key>NSNetworkUsageDescription</key>
<string>Hagda needs network access to fetch content from your selected sources including Reddit, Bluesky, Mastodon, news feeds, and podcasts.</string>
```

## Security Settings

### File Sharing (Disabled)
```xml
<key>UIFileSharingEnabled</key>
<false/>

<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

### Encryption Declaration
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

## Deep Linking
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>hagda</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.hagda</string>
    </dict>
</array>
```

## How to Add These Settings

1. Open Hagda.xcodeproj in Xcode
2. Select the Hagda target
3. Go to the Info tab
4. Add the required keys and values
5. For App Transport Security, use the "App Transport Security Settings" section
6. For URL Types, use the "URL Types" section

## Additional Requirements

- Privacy Policy URL: Required in App Store Connect
- Terms of Service URL: Required if app has user accounts or subscriptions
- App uses background modes: Only add if implementing background functionality