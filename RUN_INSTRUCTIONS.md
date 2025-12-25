# 🚀 How to Run the Pawn Shop Assistant App

Follow these simple steps to get the app running on your iPhone or simulator.

---

## Prerequisites

Before you start, make sure you have:
- ✅ **Mac** with macOS (required for Xcode)
- ✅ **Xcode 14.0 or later** installed
- ✅ **iPhone** with iOS 15.0+ OR use the **iOS Simulator**
- ✅ **Claude API Key** from Anthropic

---

## Step 1: Get Your Claude API Key

1. Visit [https://console.anthropic.com/](https://console.anthropic.com/)
2. Sign up or log in to your account
3. Navigate to **API Keys** section
4. Click **Create Key** and copy your new API key
   - It will look like: `sk-ant-api03-xxxxxxxxxxxxx`

---

## Step 2: Configure the API Key

In your terminal, navigate to the project directory and run:

```bash
# Create the config file from the example
cp Config.xcconfig.example Config.xcconfig

# Open the file in your default text editor
open -e Config.xcconfig
```

Replace `your_claude_api_key_here` with your actual API key:

```
CLAUDE_API_KEY = sk-ant-api03-your-actual-key-here
```

**Save the file** and close the editor.

> ⚠️ **Important**: `Config.xcconfig` is in `.gitignore` so your API key won't be committed to Git!

---

## Step 3: Open the Project in Xcode

```bash
# From the project directory
open PawnShopAssistant.xcodeproj
```

Or simply:
- Double-click `PawnShopAssistant.xcodeproj` in Finder

---

## Step 4: Build and Run

### Option A: Run on iPhone Simulator (Easiest)

1. In Xcode, at the top toolbar, click the **device dropdown** (next to "PawnShopAssistant")
2. Select any **iPhone simulator** (e.g., "iPhone 15 Pro")
3. Press the **▶️ Play button** or press `Cmd + R`
4. Wait for the build to complete (~30 seconds first time)
5. The app will launch automatically in the simulator

> ⚠️ **Note**: The camera won't work in the simulator, but you can still test the UI.

### Option B: Run on Real iPhone (Best Experience)

1. Connect your iPhone to your Mac with a USB cable
2. **Unlock your iPhone**
3. On your iPhone, trust your Mac if prompted
4. In Xcode, select your **iPhone** from the device dropdown
5. If this is your first time:
   - You may need to register your device with your Apple ID
   - Go to Xcode → Settings → Accounts → Add your Apple ID
6. Press the **▶️ Play button** or press `Cmd + R`
7. On your iPhone, you may need to trust the developer:
   - Go to Settings → General → VPN & Device Management
   - Tap your Apple ID and select **Trust**
8. Run the app again from Xcode

---

## Step 5: Use the App

Once the app launches:

1. **Grant Camera Permission** when prompted
2. Tap **"Take Photo"**
3. Point the camera at any item:
   - ⌚ Watch
   - 💍 Jewelry
   - 📱 Electronics
   - 🎮 Gaming console
   - 📷 Camera
   - etc.
4. Take the photo
5. Tap **"Analyze & Get Price"**
6. Wait ~5-10 seconds for AI analysis
7. View the detailed results:
   - Item identification
   - Condition assessment
   - Market value
   - Pawn shop offer value
   - Authentication tips

---

## Troubleshooting

### ❌ "API key not configured" Error

**Problem**: The app can't find your API key.

**Solution**:
1. Make sure you created `Config.xcconfig` (not editing the `.example` file!)
2. Check that your API key is correct in `Config.xcconfig`
3. Clean the build: In Xcode, press `Cmd + Shift + K`
4. Rebuild: Press `Cmd + R`

---

### ❌ Build Errors

**Problem**: Xcode shows compile errors.

**Solutions**:
1. **Clean Build Folder**: Press `Cmd + Shift + K`
2. **Clean Derived Data**:
   - Xcode → Settings → Locations → Click arrow next to Derived Data
   - Delete the `PawnShopAssistant-xxx` folder
3. **Restart Xcode**
4. Try building again: `Cmd + R`

---

### ❌ Camera Not Working

**Problem**: Camera is black or not showing.

**Solutions**:
- **If using simulator**: Camera doesn't work in simulator! Use a real iPhone.
- **If using real iPhone**:
  1. Make sure you granted camera permission
  2. Check Settings → Privacy → Camera → Pawn Shop Assistant (should be ON)
  3. Try restarting the app

---

### ❌ Code Signing Error

**Problem**: "Signing for PawnShopAssistant requires a development team"

**Solution**:
1. In Xcode, select the project in the navigator (blue icon)
2. Select the **PawnShopAssistant** target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** (your Apple ID)
6. Xcode will automatically fix the signing

---

### ❌ Slow Analysis / Timeout

**Problem**: Analysis takes too long or times out.

**Solutions**:
1. Check your internet connection
2. Make sure your API key is valid and has credits
3. Check your API usage at [console.anthropic.com](https://console.anthropic.com/)
4. Try with a smaller/clearer photo

---

## What the App Does

The **Pawn Shop Assistant** uses AI to analyze photos of items and provide:

- 🔍 **Item Identification**: What is the item?
- 📊 **Condition Assessment**: What's the condition?
- 💰 **Market Value**: What does it sell for?
- 💵 **Pawn Value**: What would a pawn shop offer?
- 🔑 **Key Factors**: Why is it worth this much?
- ✅ **Authentication Tips**: How to verify it's real?

---

## Project Structure

```
PawnShopAssistant/
├── PawnShopAssistantApp.swift    # App entry point
├── Views/
│   ├── ContentView.swift         # Main UI
│   └── ImagePicker.swift         # Camera interface
├── ViewModels/
│   └── PawnShopViewModel.swift   # Business logic
├── Services/
│   └── ClaudeAPIService.swift    # AI API integration
├── Models/
│   └── ItemAnalysis.swift        # Data models
└── Info.plist                    # App configuration
```

---

## Additional Resources

- 📖 **[README.md](README.md)** - Full project documentation
- 📚 **[TECHNICAL_DOCS.md](TECHNICAL_DOCS.md)** - Technical architecture
- 🧪 **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - How to run tests
- 🎨 **[UI_MOCKUP.md](UI_MOCKUP.md)** - UI design documentation

---

## Need Help?

- Check the [troubleshooting section](#troubleshooting) above
- Review the [README.md](README.md) for more details
- Open an issue on GitHub

---

**🎉 That's it! You're ready to use the Pawn Shop Assistant!**
