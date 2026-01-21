# Momentum UI Plan

## Overview

A clean, energetic iOS app focused on daily task completion with satisfying interactions. Light mode only, electric blue accent, geometric typography. Inspired by Things 3, Streaks, and Atoms.

---

## Navigation Structure

**4 Tabs** (renamed from original):
1. **Home** - Daily task completion (primary view)
2. **Progress** - Goal roadmap visualization
3. **Mindset** - Motivation hub with quotes, affirmations, "why you started"
4. **Profile** - Settings and user info

**Floating Elements:**
- AI button remains in bottom bar alongside tabs
- Keep the existing `FloatingTabBar` + `FloatingAIButton` pattern

---

## Design System

### Color Palette

```
Primary Background: #FFFFFF (pure white)
Secondary Background: #F8FAFC (slate-50, subtle cards)
Surface/Cards: #FFFFFF with subtle shadow

Primary Accent: #2563EB (electric blue-600)
Primary Accent Light: #3B82F6 (blue-500, hover states)
Primary Accent Dark: #1D4ED8 (blue-700, pressed states)

Text Primary: #0F172A (slate-900)
Text Secondary: #64748B (slate-500)
Text Tertiary: #94A3B8 (slate-400)

Success: #10B981 (emerald-500)
Warning: #F59E0B (amber-500)
Danger: #EF4444 (red-500)

Difficulty Colors:
- Easy: #10B981 (emerald - 1 point)
- Medium: #F59E0B (amber - 2 points)
- Hard: #EF4444 (red - 3 points)
```

### Typography

**Font:** Plus Jakarta Sans (geometric sans-serif, free Google Font)
- Modern, clean, excellent weight range
- Pairs well with energetic aesthetic
- Great readability on mobile

```
Display (celebration screens): Plus Jakarta Sans Bold, 32pt
Heading Large: Plus Jakarta Sans SemiBold, 24pt
Heading Medium: Plus Jakarta Sans SemiBold, 20pt
Body: Plus Jakarta Sans Regular, 16pt
Body Medium: Plus Jakarta Sans Medium, 16pt
Label: Plus Jakarta Sans Medium, 14pt
Caption: Plus Jakarta Sans Regular, 12pt
```

### Spacing Scale
```
4pt - micro spacing
8pt - tight spacing
12pt - compact spacing
16pt - standard spacing
20pt - comfortable spacing
24pt - section spacing
32pt - large section gaps
```

### Corner Radii
```
Small (buttons, badges): 8pt
Medium (cards): 16pt
Large (modals, sheets): 24pt
```

---

## Home Screen Design

### Layout (top to bottom)

#### 1. Header Section
```
┌─────────────────────────────────────┐
│  Good morning, Henry        ○ Ring  │
│  Monday, January 20                 │
└─────────────────────────────────────┘
```

- **Greeting**: Dynamic based on time (Good morning/afternoon/evening)
- **Date**: Full format "Monday, January 20"
- **Weekly Progress Ring**: Compact ring in top-right showing X/42 points
  - Ring uses electric blue fill
  - Center shows "18/42" or similar
  - Tapping opens Progress tab

#### 2. Task Cards Stack

Three stacked cards, one for each difficulty. Order: Easy → Medium → Hard (or user preference).

**Collapsed Card Layout:**
```
┌─────────────────────────────────────┐
│  ● ●     Task Title Here            │
│  ⏱ 15 min   📁 Goal Name           │
└─────────────────────────────────────┘
```

- **Difficulty Icons**: 1 dot (easy), 2 dots (medium), 3 dots (hard) - colored
- **Task Title**: Primary text, truncated if needed
- **Estimated Time**: Clock icon + duration
- **Goal Name**: Folder icon + goal name (always visible)
- **Card Background**: White with subtle shadow
- **Left Accent**: Thin colored bar on left edge matching difficulty

**Expanded Card Layout:**
```
┌─────────────────────────────────────┐
│  ● ●     Task Title Here            │
│  ⏱ 15 min   📁 Goal Name           │
├─────────────────────────────────────┤
│  Description text goes here...      │
│                                     │
│  Microsteps:                        │
│  ☐ First small step                 │
│  ☐ Second small step                │
│  ☐ Third small step                 │
│                                     │
│  [Notes]  [AI Help]                 │
└─────────────────────────────────────┘
```

- Expands in place with spring animation
- Description text (if available)
- Microsteps checklist (if generated)
- Quick action buttons: Notes, AI Help

#### 3. Empty State (When No Tasks)
- "No tasks for today" message
- Option to browse goals or talk to AI

#### 4. Celebration Screen (All 3 Complete)
```
┌─────────────────────────────────────┐
│                                     │
│           🎉                        │
│                                     │
│     You crushed it today!           │
│                                     │
│     +6 points earned                │
│     18/42 this week                 │
│                                     │
│     [See Your Progress]             │
│                                     │
└─────────────────────────────────────┘
```

- Full-screen celebration
- Confetti animation
- Points summary
- CTA to Progress tab

---

## Task Interaction Design

### Hold to Complete

1. **Initial State**: Card at rest
2. **Press Start**: Card scales down slightly (0.98), subtle haptic
3. **Hold Progress**: Circular progress indicator fills around the card edge (0.8s duration)
4. **Release Early**: Snaps back, no completion
5. **Hold Complete**:
   - Strong haptic feedback
   - Pop sound effect
   - Card animates away (scale to 0 + fade)
   - Progress ring updates
   - Next card slides up

### Card Expansion

- Tap card to expand/collapse
- Spring animation (response: 0.5, damping: 0.8)
- Other cards fade slightly when one is expanded
- Haptic on expand

### Completion Animation Sequence

1. Hold progress circle completes
2. Card glows briefly (blue overlay)
3. Checkmark appears (animated draw)
4. Pop sound plays
5. Card shrinks and fades out
6. Remaining cards animate to fill space
7. Progress ring increments with animation

---

## Weekly Points System

**Points per task:**
- Easy: 1 point
- Medium: 2 points
- Hard: 3 points

**Weekly total:** 6 points/day × 7 days = **42 points max**

**Progress Ring:**
- Shows current week's points
- Resets every Monday
- Ring fills proportionally (18/42 = ~43% filled)
- Center text shows "18/42" or percentage

---

## Multi-Goal Handling

### Goal Assignment
- Users can have up to 3 active goals
- Daily tasks are mixed from all active goals
- Each task card shows which goal it belongs to

### Goal Indicator on Cards
- Small colored dot or icon
- Goal name visible in secondary text
- Each goal could have an assigned color

---

## Animation Specifications

### Staggered Reveal (on appear)
```swift
.offset(y: appeared ? 0 : 30)
.opacity(appeared ? 1 : 0)
.animation(
    .spring(response: 0.6, dampingFraction: 0.8)
    .delay(Double(index) * 0.1),
    value: appeared
)
```

### Card Expansion
```swift
.matchedGeometryEffect(id: task.id, in: namespace)
// or
withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
    isExpanded.toggle()
}
```

### Completion Animation
```swift
// Scale down during hold
.scaleEffect(isHolding ? 0.95 : 1.0)

// Progress ring around card
Circle()
    .trim(from: 0, to: holdProgress)
    .stroke(Color.blue, lineWidth: 3)

// Exit animation
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .scale(scale: 0.8).combined(with: .opacity)
))
```

### Haptic Feedback
```swift
// Light haptic on press
UIImpactFeedbackGenerator(style: .light).impactOccurred()

// Medium haptic on completion
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Success haptic on all complete
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

---

## Sound Design

**Task Completion:** Short, satisfying "pop" sound
- Duration: ~100-200ms
- Frequency: Mid-high (pleasant, not jarring)
- Consider: iOS system sound or custom audio file

**All Tasks Complete:** Celebratory chime
- Duration: ~500ms
- Layered sound (like achievement unlock)

---

## Tab Designs (Summary)

### Progress Tab
- Goal roadmap visualization
- Visual timeline of Power Goals (12 months)
- Current milestone highlighted
- Path/journey metaphor showing progress

### Mindset Tab
- Motivation hub
- Daily quote or affirmation
- "Why you started" reminder (user's vision)
- Encouraging messages from AI

### Profile Tab
- User settings
- Streak statistics
- AI personality selection
- Notification preferences
- Subscription management

---

## Files to Create/Modify

### New Files
- `Views/Home/HomeView.swift` - Main home screen
- `Views/Home/TaskCardView.swift` - Individual task card component
- `Views/Home/WeeklyProgressRing.swift` - Progress ring component
- `Views/Home/CelebrationView.swift` - All-tasks-complete celebration
- `Views/Progress/ProgressView.swift` - Goal roadmap (rename from MomentumProgressView)
- `Views/Mindset/MindsetView.swift` - Motivation hub
- `Resources/Fonts/PlusJakartaSans-*.ttf` - Font files
- `Resources/Sounds/pop.mp3` - Completion sound

### Modify
- `Utilities/Theme.swift` - Update color palette and typography
- `Views/MainTabView.swift` - Update tab names and icons
- `ViewModels/AppState.swift` - Add weekly points tracking

### Delete/Deprecate
- `Views/Today/TodayView.swift` - Replaced by HomeView
- `Views/Road/JourneyView.swift` - Replaced by ProgressView
- `Views/Goals/GoalsView.swift` - Functionality merged elsewhere
- `Views/Stats/ProgressView.swift` - Replaced

---

## Implementation Order

1. **Theme.swift** - Update colors, add font system
2. **HomeView.swift** - Basic layout with greeting and placeholder cards
3. **TaskCardView.swift** - Card component with expand/collapse
4. **WeeklyProgressRing.swift** - Progress visualization
5. **Hold-to-complete interaction** - Core completion mechanic
6. **Animations** - Stagger, completion, transitions
7. **Sound & Haptics** - Polish layer
8. **CelebrationView.swift** - All-complete state
9. **MainTabView.swift** - Update navigation
10. **Other tabs** - Progress, Mindset, Profile

---

## Technical Notes

### Font Installation
1. Add Plus Jakarta Sans .ttf files to project
2. Add to Info.plist under "Fonts provided by application"
3. Create font extension in Theme.swift

### Sound Playback
```swift
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?

    func playPop() {
        guard let url = Bundle.main.url(forResource: "pop", withExtension: "mp3") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}
```

### Points Calculation
```swift
extension AppState {
    var weeklyPoints: Int {
        // Sum points from all completed tasks this week
        // Easy = 1, Medium = 2, Hard = 3
    }

    var weeklyPointsMax: Int { 42 }
}
```

---

## Success Criteria

- [ ] Home screen feels clean and focused
- [ ] Task completion is satisfying (hold mechanic works smoothly)
- [ ] Animations are smooth (60fps)
- [ ] Typography is distinctive (not generic SF Pro)
- [ ] Colors feel energetic but not overwhelming
- [ ] Progress ring clearly communicates weekly status
- [ ] Celebration screen feels rewarding
- [ ] Multi-goal tasks are clearly attributed
- [ ] Sounds enhance without annoying
