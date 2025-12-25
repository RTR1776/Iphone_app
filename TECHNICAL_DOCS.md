# Pawn Shop Assistant - Technical Documentation

## Architecture Overview

The app follows the MVVM (Model-View-ViewModel) architecture pattern with a clean separation of concerns.

### Component Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│                     PawnShopAssistantApp                     │
│                      (Main Entry Point)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                        ContentView                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  • Display app title and icon                         │  │
│  │  • Show camera button                                 │  │
│  │  • Display captured image preview                     │  │
│  │  • "Analyze & Get Price" button                       │  │
│  │  • Show analysis results in scrollable view           │  │
│  │  • Error message display                              │  │
│  │  • "Start Over" reset button                          │  │
│  └───────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ ImagePicker  │  │ViewModel     │  │ Models       │
└──────────────┘  └──────────────┘  └──────────────┘
        │                │                │
        │                ▼                │
        │         ┌──────────────┐        │
        │         │ClaudeAPIService       │
        │         └──────────────┘        │
        │                │                │
        └────────────────┴────────────────┘
```

## File Structure

### Views Layer
- **ContentView.swift**: Main UI component
  - Displays the camera interface
  - Shows image preview
  - Renders analysis results
  - Manages user interactions

- **ImagePicker.swift**: Camera integration
  - Wraps UIImagePickerController for SwiftUI
  - Handles camera permissions
  - Returns captured UIImage

### ViewModels Layer
- **PawnShopViewModel.swift**: Business logic coordinator
  - Manages app state (@Published properties)
  - Coordinates between View and Service
  - Handles async operations with Claude API
  - Error handling and state management

### Services Layer
- **ClaudeAPIService.swift**: API integration
  - Converts images to base64
  - Constructs API requests
  - Handles HTTP communication
  - Parses API responses
  - Error handling

### Models Layer
- **ItemAnalysis.swift**: Data structures
  - ItemAnalysis: Structured analysis data
  - PriceRange: Price formatting and display

## Data Flow

### 1. Image Capture Flow
```
User Taps "Take Photo"
    ↓
ContentView shows ImagePicker
    ↓
User captures photo with camera
    ↓
ImagePicker returns UIImage
    ↓
ViewModel.selectedImage updated
    ↓
ContentView re-renders with image preview
```

### 2. Analysis Flow
```
User Taps "Analyze & Get Price"
    ↓
ViewModel.analyzeItem() called
    ↓
ViewModel sets isAnalyzing = true
    ↓
ClaudeAPIService.analyzeImage() called
    ↓
Image converted to base64 JPEG
    ↓
HTTP POST to Claude API with:
  - Model: claude-3-5-sonnet-20241022
  - Image data
  - Expert pawn shop prompt
    ↓
Claude API processes and responds
    ↓
Response parsed for text content
    ↓
ViewModel.analysisResult updated
    ↓
ViewModel sets isAnalyzing = false
    ↓
ContentView displays results
```

## API Integration Details

### Claude API Request Format
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "image/jpeg",
            "data": "<base64_encoded_image>"
          }
        },
        {
          "type": "text",
          "text": "Expert pawn shop analysis prompt..."
        }
      ]
    }
  ]
}
```

### Expert Prompt
The app sends a specialized prompt requesting:
1. Item identification and description
2. Condition assessment
3. Estimated market value range
4. Estimated pawn value (25-60% of market)
5. Key factors affecting price
6. Verification/authentication tips

### Response Handling
- Parses JSON response from Claude API
- Extracts text content from first message
- Displays as formatted text in UI
- Handles errors gracefully with user-friendly messages

## State Management

The ViewModel uses `@Published` properties for reactive UI updates:

```swift
@Published var selectedImage: UIImage?        // Current photo
@Published var analysisResult: String?        // AI analysis text
@Published var isAnalyzing: Bool = false      // Loading state
@Published var errorMessage: String?          // Error display
```

## Error Handling

### Custom Error Types
```swift
enum ClaudeAPIError: Error {
    case invalidURL
    case invalidResponse
    case apiKeyMissing
    case networkError(Error)
    case decodingError(Error)
}
```

### Error Display
- API errors shown in red text below results
- User-friendly error messages
- Non-blocking - user can retry or start over

## Security Considerations

1. **API Key Storage**
   - Stored in Config.xcconfig (gitignored)
   - Can be injected via Info.plist
   - Never hardcoded in source

2. **Camera Permissions**
   - NSCameraUsageDescription in Info.plist
   - User must grant permission before use

3. **Data Privacy**
   - Images processed in-memory only
   - No local storage of photos
   - API requests over HTTPS

## Testing Strategy

Since this is a "bones" implementation, testing focuses on:

1. **Manual Testing**
   - Camera capture works
   - Image displays correctly
   - API integration functional
   - Error states display properly
   - UI responsive and intuitive

2. **Simulator Testing**
   - Note: Camera requires physical device
   - Can test UI/UX in simulator
   - Use photo library as fallback

3. **API Testing**
   - Valid API key configuration
   - Network error handling
   - Response parsing
   - Timeout handling

## Future Enhancements

### Phase 2 Features
- [ ] Photo library support
- [ ] Save analysis history
- [ ] Export to PDF
- [ ] Multiple item comparison
- [ ] Price trend tracking

### Phase 3 Features
- [ ] User authentication
- [ ] Cloud sync
- [ ] Barcode scanning
- [ ] Offline mode
- [ ] Multi-language support

### Phase 4 Features
- [ ] Business analytics
- [ ] Inventory management
- [ ] Customer database
- [ ] Receipt generation
- [ ] Reporting dashboard

## Performance Considerations

1. **Image Compression**
   - JPEG compression at 0.8 quality
   - Balances file size vs. image quality
   - Reduces API transfer time

2. **Async Operations**
   - API calls use Swift Concurrency (async/await)
   - Non-blocking UI during analysis
   - Progress indicator for user feedback

3. **Memory Management**
   - Images released on reset
   - No persistent caching
   - Clean state management

## Dependencies

### System Frameworks
- SwiftUI: UI framework
- UIKit: Camera integration
- Foundation: Networking and data handling
- Combine: Reactive state management

### External Dependencies
- None! Pure iOS SDK implementation
- Only external dependency: Claude API (HTTP REST)

## Build Requirements

- Xcode 14.0+
- iOS 15.0+
- Swift 5.0+
- Active internet connection for API
- Physical device for camera (simulator optional)

## Deployment Notes

### Development
1. Configure API key
2. Select development team
3. Build and run on device

### TestFlight
1. Archive app
2. Upload to App Store Connect
3. Add testers
4. Distribute via TestFlight

### App Store
1. Add app screenshots
2. Complete App Store metadata
3. Submit for review
4. Publish upon approval

## Support and Maintenance

### Configuration
- API key rotation: Update Config.xcconfig
- Bundle ID: Update in project settings
- App name: Modify in Info.plist

### Troubleshooting
See README.md for common issues and solutions.
