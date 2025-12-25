# App UI Mockup

## Main Screen (Initial State)

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│              🎒                     │
│         (bag icon)                  │
│                                     │
│      Pawn Shop Assistant            │
│    AI-powered item valuation        │
│                                     │
│                                     │
│                                     │
│                                     │
│           (empty state)             │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📷  Take Photo               │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

## After Taking Photo

```
┌─────────────────────────────────────┐
│                                     │
│              🎒                     │
│      Pawn Shop Assistant            │
│    AI-powered item valuation        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │      [Photo Preview]          │  │
│  │     of captured item          │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📷  Take Photo               │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  🔍  Analyze & Get Price      │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  ↻   Start Over               │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

## During Analysis

```
┌─────────────────────────────────────┐
│              🎒                     │
│      Pawn Shop Assistant            │
│    AI-powered item valuation        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      [Photo Preview]          │  │
│  └───────────────────────────────┘  │
│                                     │
│       ⏳ Analyzing item...          │
│         (loading spinner)           │
│                                     │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## With Analysis Results

```
┌─────────────────────────────────────┐
│              🎒                     │
│      Pawn Shop Assistant            │
│    AI-powered item valuation        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      [Photo Preview]          │  │
│  └───────────────────────────────┘  │
│                                     │
│  Analysis Results                   │
│  ┌───────────────────────────────┐  │
│  │ Item: Rolex Submariner Watch  │  │
│  │                               │  │
│  │ Condition: Good, minor wear   │  │
│  │ on bracelet, functioning      │  │
│  │                               │  │
│  │ Market Value: $8,000-$12,000  │  │
│  │ Pawn Value: $3,200-$6,000     │  │
│  │                               │  │
│  │ Key Factors:                  │  │
│  │ • Authentic Rolex design      │  │
│  │ • Working mechanical movement │  │
│  │ • Minor cosmetic wear         │  │
│  │                               │  │
│  │ Verification Tips:            │  │
│  │ • Check serial number         │  │
│  │ • Verify crown markings       │  │
│  │ • Test water resistance       │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  ↻   Start Over               │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Error State

```
┌─────────────────────────────────────┐
│              🎒                     │
│      Pawn Shop Assistant            │
│    AI-powered item valuation        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      [Photo Preview]          │  │
│  └───────────────────────────────┘  │
│                                     │
│   ⚠️ Error: API key not configured │
│      Please add CLAUDE_API_KEY     │
│      to Config.xcconfig            │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📷  Take Photo               │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  🔍  Analyze & Get Price      │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  ↻   Start Over               │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Key UI Elements

### Header
- Bag icon (🎒) representing pawn shop
- App title: "Pawn Shop Assistant"
- Subtitle: "AI-powered item valuation"

### Image Section
- Large preview of captured photo
- Rounded corners with shadow
- Scales to fit screen
- Only visible after photo taken

### Results Section
- Scrollable text area
- Gray background for readability
- Formatted analysis text
- Only visible after analysis completes

### Loading State
- Progress spinner
- "Analyzing item..." text
- Disables buttons during analysis

### Error State
- Red error text
- Clear, actionable message
- Appears below results area

### Action Buttons

**Take Photo** (Blue)
- Always visible
- Opens native camera
- Replaces existing photo

**Analyze & Get Price** (Green)
- Only visible when photo exists
- Disabled during analysis
- Sends to Claude API

**Start Over** (Gray)
- Only visible when photo exists
- Clears all state
- Returns to initial view

## Interaction Flow

```
Initial State
     ↓
  [Tap "Take Photo"]
     ↓
Camera Opens
     ↓
  [Capture Image]
     ↓
Photo Preview Shows
     ↓
  [Tap "Analyze & Get Price"]
     ↓
Loading State (spinner)
     ↓
API Call to Claude
     ↓
Results Display
     ↓
  [Optional: "Start Over"]
     ↓
Back to Initial State
```

## Design Features

✅ Clean, minimal interface
✅ Large, tappable buttons
✅ Clear visual hierarchy
✅ Loading feedback
✅ Error handling visible
✅ Scrollable results
✅ Professional color scheme:
   - Blue: Primary action (camera)
   - Green: Success action (analyze)
   - Gray: Secondary action (reset)
   - Red: Error messages

## Accessibility

- System font sizes respected
- VoiceOver compatible
- High contrast colors
- Large touch targets
- Clear button labels
- Status feedback for all actions

## Platform Features

- SwiftUI native styling
- iOS design guidelines
- Dark mode compatible
- Adapts to device size
- Portrait and landscape support
