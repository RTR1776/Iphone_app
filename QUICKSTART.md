# 🚀 Quick Start - Get Running in 5 Minutes

## Prerequisites
- Mac with Xcode 14.0+
- iPhone running iOS 15.0+
- Claude API key (get free trial at console.anthropic.com)

## Setup Steps

### 1️⃣ Get Your API Key (2 min)
```bash
# Visit https://console.anthropic.com/
# Sign up → Create API Key → Copy it
```

### 2️⃣ Configure the App (1 min)
```bash
# In the project directory
cp Config.xcconfig.example Config.xcconfig
nano Config.xcconfig
# Replace YOUR_API_KEY with your actual key
# Save and exit (Ctrl+X, Y, Enter)
```

### 3️⃣ Open in Xcode (1 min)
```bash
open PawnShopAssistant.xcodeproj
```

In Xcode:
- Select your iPhone from the device dropdown
- Click the ▶️ button (or Cmd+R)

### 4️⃣ Test It! (1 min)
On your iPhone:
1. Grant camera permission when asked
2. Tap "Take Photo"
3. Point camera at any item (watch, jewelry, electronics)
4. Take the photo
5. Tap "Analyze & Get Price"
6. Wait ~5 seconds
7. See the AI analysis! 🎉

## Example Items to Try
- ⌚ Watches (especially luxury brands)
- 💍 Jewelry (rings, necklaces, bracelets)
- 📱 Electronics (phones, tablets, laptops)
- 🎮 Gaming consoles
- 📷 Cameras
- 🎸 Musical instruments
- 👜 Designer handbags
- 🏆 Collectibles

## What You'll Get
The AI will tell you:
- ✓ What the item is
- ✓ Its condition
- ✓ Market value (what it sells for)
- ✓ Pawn value (what shop offers)
- ✓ Why it's priced that way
- ✓ How to verify it's authentic

## Troubleshooting

**"API key not configured"**
→ Check Config.xcconfig has your real API key

**Camera not working**
→ Must use real iPhone (simulator won't work)

**Build error**
→ Clean build: Cmd+Shift+K, then rebuild

## Need More Help?
- 📖 **SETUP_GUIDE.md** - Detailed instructions
- 📚 **README.md** - Full documentation
- 🔧 **TECHNICAL_DOCS.md** - Architecture details

## That's It!
You now have a working AI pawn shop assistant! 🎊

**Pro Tip**: The AI is incredibly smart. Try asking it about vintage items, rare collectibles, or even things in poor condition. It will give you realistic valuations and explain its reasoning.
