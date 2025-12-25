# Pawn Shop Assistant - iPhone App

An AI-powered iPhone application that helps pawn shop owners and customers evaluate items using the Claude API. Take a photo of any item and get instant expert analysis including identification, condition assessment, and pricing estimates.

## 🚀 Quick Links

- **[QUICKSTART.md](QUICKSTART.md)** - Get running in 5 minutes
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup instructions
- **[TECHNICAL_DOCS.md](TECHNICAL_DOCS.md)** - Architecture and implementation details
- **[UI_MOCKUP.md](UI_MOCKUP.md)** - Interface design and user flow
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - What was built

## Features

- 📸 **Camera Integration**: Take photos directly in the app
- 🤖 **AI-Powered Analysis**: Uses Claude API for expert item evaluation
- 💰 **Price Estimation**: Get market value and pawn value estimates
- ✅ **Condition Assessment**: Detailed condition evaluation
- 🔍 **Authentication Tips**: Guidance on verifying item authenticity
- 📊 **Key Factors**: Understanding what affects item value

## Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- Claude API key from [Anthropic](https://console.anthropic.com/)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/RTR1776/Iphone_app.git
cd Iphone_app
```

### 2. Configure API Key

The app requires a Claude API key to function. You have two options:

#### Option A: Using Config.xcconfig (Recommended)

1. Copy the example config file:
   ```bash
   cp Config.xcconfig.example Config.xcconfig
   ```

2. Edit `Config.xcconfig` and add your Claude API key:
   ```
   CLAUDE_API_KEY = sk-ant-api03-your-actual-key-here
   ```

3. In Xcode, add the config file to your project configuration:
   - Select your project in the Project Navigator
   - Select the PawnShopAssistant target
   - Go to "Info" tab
   - Add a new key: `CLAUDE_API_KEY` with value `$(CLAUDE_API_KEY)`

#### Option B: Direct in Info.plist (Not Recommended for Production)

Add your API key directly to `PawnShopAssistant/Info.plist`:
```xml
<key>CLAUDE_API_KEY</key>
<string>sk-ant-api03-your-actual-key-here</string>
```

**⚠️ Warning**: Never commit your actual API key to version control!

### 3. Open in Xcode

```bash
open PawnShopAssistant.xcodeproj
```

If the project file doesn't exist yet, you'll need to create it:

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Product Name: "PawnShopAssistant"
5. Interface: SwiftUI
6. Language: Swift
7. Save in the repository directory

Then add all the source files from the `PawnShopAssistant` folder to your project.

### 4. Build and Run

1. Select a simulator or connected iPhone device
2. Press Cmd + R or click the Run button
3. Grant camera permissions when prompted

## Project Structure

```
PawnShopAssistant/
├── PawnShopAssistantApp.swift    # Main app entry point
├── Views/
│   ├── ContentView.swift         # Main UI view
│   └── ImagePicker.swift         # Camera integration
├── ViewModels/
│   └── PawnShopViewModel.swift   # Business logic
├── Services/
│   └── ClaudeAPIService.swift    # Claude API integration
├── Models/
│   └── ItemAnalysis.swift        # Data models
├── Assets.xcassets/              # App icons and images
└── Info.plist                    # App configuration
```

## How to Use

1. **Launch the App**: Open the Pawn Shop Assistant on your iPhone
2. **Take a Photo**: Tap "Take Photo" and capture an image of the item
3. **Analyze**: Tap "Analyze & Get Price" to send the image to Claude API
4. **Review Results**: Read the detailed analysis including:
   - Item identification and description
   - Condition assessment
   - Market value range
   - Estimated pawn value
   - Key pricing factors
   - Authentication tips
5. **Start Over**: Tap "Start Over" to analyze another item

## Technology Stack

- **Language**: Swift 5
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **API**: Claude 3.5 Sonnet (Anthropic)
- **Minimum iOS**: 15.0

## API Usage

The app uses the Claude API with vision capabilities to analyze images. Each analysis request:
- Uses the `claude-3-5-sonnet-20241022` model
- Sends images as base64-encoded JPEG
- Requests expert pawn shop assistant analysis
- Returns detailed valuation information

## Security Notes

- ✅ API keys are excluded from version control via `.gitignore`
- ✅ Use `Config.xcconfig` for sensitive configuration
- ✅ Never hardcode API keys in source files
- ✅ Camera permissions are properly requested via Info.plist

## Troubleshooting

### "API key not configured" Error
- Ensure you've created `Config.xcconfig` from the example file
- Verify your API key is valid and properly formatted
- Check that the key is added to Info.plist or project configuration

### Camera Not Working
- Ensure you've granted camera permissions in iOS Settings
- Check that Info.plist includes `NSCameraUsageDescription`
- Try running on a physical device (simulator camera has limitations)

### Build Errors
- Clean build folder: Cmd + Shift + K
- Ensure Xcode version is 14.0+
- Verify all source files are added to the target

## Future Enhancements

- [ ] Photo library support
- [ ] Save analysis history
- [ ] Export reports as PDF
- [ ] Offline mode with cached results
- [ ] Multiple item comparison
- [ ] Barcode/QR code scanning
- [ ] Price trend tracking
- [ ] User authentication
- [ ] Cloud sync across devices

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available for personal and commercial use.

## Support

For issues or questions, please open an issue on GitHub.

---

**Note**: This app requires an active Claude API subscription. API usage costs apply based on Anthropic's pricing.