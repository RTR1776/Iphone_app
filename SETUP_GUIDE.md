# Quick Setup Guide - Pawn Shop Assistant

This guide will help you get the Pawn Shop Assistant app running on your iPhone in just a few minutes.

## Step 1: Get a Claude API Key

1. Go to [https://console.anthropic.com/](https://console.anthropic.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Click "Create Key"
5. Copy your API key (starts with `sk-ant-api03-...`)

**Important**: Keep this key secure! Don't share it publicly.

## Step 2: Clone the Repository

```bash
git clone https://github.com/RTR1776/Iphone_app.git
cd Iphone_app
```

## Step 3: Configure Your API Key

### Option 1: Using Config.xcconfig (Recommended)

```bash
# Copy the example config file
cp Config.xcconfig.example Config.xcconfig

# Edit the config file
nano Config.xcconfig
# or use your preferred editor
```

Replace `your_claude_api_key_here` with your actual API key:
```
CLAUDE_API_KEY = sk-ant-api03-YOUR-ACTUAL-KEY-HERE
```

Save and close the file.

### Option 2: Direct Configuration in Xcode

1. Open `PawnShopAssistant.xcodeproj` in Xcode
2. Open `PawnShopAssistant/Info.plist`
3. Add a new row:
   - Key: `CLAUDE_API_KEY`
   - Type: String
   - Value: Your API key

## Step 4: Open in Xcode

```bash
open PawnShopAssistant.xcodeproj
```

Or:
1. Open Xcode
2. File → Open
3. Navigate to the cloned repository
4. Select `PawnShopAssistant.xcodeproj`

## Step 5: Configure Signing

1. In Xcode, select the project in the navigator
2. Select the "PawnShopAssistant" target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your Apple Developer Team from the dropdown
   - If you don't see a team, you may need to add your Apple ID in Xcode Preferences

## Step 6: Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. If prompted on iPhone, tap "Trust This Computer"
3. In Xcode, select your iPhone from the device dropdown (top toolbar)

**Note**: The simulator can be used for UI testing, but the camera won't work. You need a physical device for the full experience.

## Step 7: Build and Run

1. Click the "Play" button in Xcode (or press Cmd+R)
2. Xcode will build and install the app on your iPhone
3. If prompted, grant camera permissions on your iPhone

## Step 8: Test the App

1. Tap "Take Photo"
2. Point camera at an item (watch, jewelry, electronics, etc.)
3. Take the photo
4. Tap "Analyze & Get Price"
5. Wait for the AI analysis
6. Review the detailed results!

## Troubleshooting

### "API key not configured" error
- Double-check your API key in Config.xcconfig or Info.plist
- Make sure there are no extra spaces or quotes
- Verify the key starts with `sk-ant-api03-`

### "No account for team" error
- You need an Apple ID signed in to Xcode
- Go to Xcode → Preferences → Accounts
- Click "+" to add your Apple ID
- You can use a free Apple ID for development

### Camera permission denied
- Go to iPhone Settings → Privacy & Security → Camera
- Find "Pawn Shop Assistant"
- Toggle permission ON

### Build fails with "Code signing" error
- Make sure you've selected a team in Signing & Capabilities
- Try changing the Bundle Identifier to something unique
- Free Apple IDs can only sign apps for 7 days at a time

### App crashes on launch
- Check Xcode console for error messages
- Verify all files are included in the project
- Try cleaning the build folder (Cmd+Shift+K) and rebuild

### "Cannot connect to Claude API" error
- Check your internet connection
- Verify your API key is valid and active
- Check if you have API credits in your Anthropic account

## Next Steps

Once the app is working:

1. **Test with various items**: Try different types of items to see the AI's analysis
2. **Read the analysis carefully**: The AI provides market value, pawn value, and authentication tips
3. **Customize the prompt**: Edit `ClaudeAPIService.swift` to adjust what the AI analyzes
4. **Add your own features**: The codebase is clean and ready for extensions

## Need Help?

- Check the [README.md](README.md) for more details
- Review [TECHNICAL_DOCS.md](TECHNICAL_DOCS.md) for architecture info
- Open an issue on GitHub if you encounter problems

## Quick Reference

### Useful Xcode Shortcuts
- `Cmd+R`: Build and run
- `Cmd+.`: Stop running app
- `Cmd+Shift+K`: Clean build folder
- `Cmd+B`: Build without running
- `Cmd+Shift+O`: Quick file open

### Common File Locations
- Main UI: `PawnShopAssistant/Views/ContentView.swift`
- API Service: `PawnShopAssistant/Services/ClaudeAPIService.swift`
- View Logic: `PawnShopAssistant/ViewModels/PawnShopViewModel.swift`
- App Entry: `PawnShopAssistant/PawnShopAssistantApp.swift`

### API Key Management
- Config file: `Config.xcconfig` (gitignored)
- Example file: `Config.xcconfig.example` (committed)
- Never commit your actual API key!

## Success Checklist

- [ ] Cloned repository
- [ ] Got Claude API key
- [ ] Created Config.xcconfig with API key
- [ ] Opened project in Xcode
- [ ] Configured code signing
- [ ] Connected iPhone
- [ ] Built and ran app
- [ ] Granted camera permission
- [ ] Took a test photo
- [ ] Got AI analysis results

If you've checked all these boxes, you're all set! 🎉

## Cost Considerations

The Claude API is a paid service. Here's what to expect:

- **Free Tier**: Anthropic may offer free credits for new users
- **Pay-as-you-go**: You pay per API call based on image size and response length
- **Typical cost**: Expect $0.01-0.05 per image analysis
- **Monitor usage**: Check your Anthropic console regularly

## Privacy Note

- Images are sent to Claude API for analysis
- No images are stored locally by the app
- No data is collected by the app developer
- Review Anthropic's privacy policy for their data handling
- For sensitive items, consider using a local AI model in the future

---

**Ready to start?** Head back to [Step 1](#step-1-get-a-claude-api-key) and let's build this app!
