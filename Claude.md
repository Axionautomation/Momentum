# Momentum

AI-powered goal achievement app that bridges the gap between annual vision and daily action.

## Vision

Momentum combines Dan Martell's structured planning framework with AI assistance to help users achieve their goals through consistent daily progress. Users input their annual vision, and the app generates a structured path: 12 Power Goals → Weekly Milestones → 3 Daily Tasks (Easy/Medium/Hard). The floating AI assistant provides research, guidance, and motivation throughout.

## Tech Stack

- **Platform**: iOS 16+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with centralized AppState
- **AI**: Groq API (llama-3.3-70b-versatile)
- **Persistence**: UserDefaults (JSON Codable)
- **Icons**: PhosphorSwift

## Package Dependencies

### PhosphorSwift (Icons)
- **Source**: https://github.com/phosphor-icons/swift
- **Version**: 2.1.0
- **Import**: `import PhosphorSwift`
- **Usage**:
```swift
Ph.sparkle.regular       // Regular weight
Ph.checkCircle.fill      // Filled variant
Ph.caretLeft.regular     // Navigation icons
Ph.target.regular        // Goal icons
```

## Project Structure

```
Momentum/
├── Models/
│   └── Models.swift              # All data models (Goals, Tasks, Users)
├── ViewModels/
│   └── AppState.swift            # Centralized state management
├── Views/
│   ├── MainTabView.swift         # Root navigation (4 tabs)
│   ├── Today/
│   │   └── TodayView.swift       # Daily dashboard
│   ├── Road/
│   │   └── JourneyView.swift     # Visual goal map
│   ├── Goals/
│   │   └── GoalsView.swift       # Goals detail + notes
│   ├── Stats/
│   │   └── ProgressView.swift    # Analytics dashboard
│   ├── Profile/
│   │   └── ProfileView.swift     # Settings
│   ├── Onboarding/
│   │   └── OnboardingView.swift  # User onboarding flow
│   └── Components/
│       ├── FloatingAIButton.swift    # Global AI trigger
│       ├── GlobalAIChatView.swift    # Full-screen AI chat
│       ├── AIAssistantView.swift     # Task-specific help
│       └── TaskPickerView.swift      # Task selection modal
├── Services/
│   ├── GroqService.swift             # AI integration
│   ├── ConversationOrchestrator.swift # Multi-turn conversations
│   └── MockDataService.swift         # Demo data
├── Utilities/
│   ├── Config.swift              # API keys, app config
│   └── Theme.swift               # Design system
└── Assets/                       # Images, colors, app icons
```

## Key Files

| File | Purpose |
|------|---------|
| `Models.swift` | All data models: MomentumUser, Goal, PowerGoal, WeeklyMilestone, MomentumTask, TaskNotes |
| `AppState.swift` | @MainActor state container, persistence, task management |
| `GroqService.swift` | AI API calls: onboarding questions, plan generation, task help, research |
| `Config.swift` | API keys, base URLs, app version |
| `Theme.swift` | Colors, typography, gradients, view modifiers |

## Data Model Hierarchy

```
Goal (1 per type: project, habit, identity)
├── PowerGoal (12 per project - monthly milestones)
│   └── WeeklyMilestone (5 per power goal)
│       └── MomentumTask (3 per day: easy, medium, hard)
│           ├── Microstep[] (AI-generated sub-tasks)
│           └── TaskNotes (conversations, research, brainstorms)
```

## Design System

### Colors
```swift
// Primary
Color.momentumViolet        // #7C3AED - Brand purple
Color.momentumDeepBlue      // #1E3A8A - Deep blue

// Background
Color.momentumDarkBackground    // #0F172A - Main background
Color.momentumSurfacePrimary    // #0E0F12 - Card surfaces
Color.momentumSurfaceSecondary  // #15171C - Elevated surfaces

// Text
Color.momentumPrimaryText       // White
Color.momentumSecondaryText     // #94A3B8 - Gray

// Accent
Color.momentumGold              // #F59E0B - Achievements
Color.momentumGreenStart        // #10B981 - Success
Color.momentumCoral             // #FF6B4A - Highlights
```

### Typography
```swift
MomentumFont.heading(24)     // Bold, default design
MomentumFont.body(16)        // Regular weight
MomentumFont.bodyMedium(17)  // Medium weight
MomentumFont.stats(18)       // Medium, rounded design
```

### View Modifiers
```swift
.opaqueSurface()             // Dark surface with border
.opaqueSurface(level: .primary)   // Darkest surface
.opaqueSurface(level: .elevated)  // With shadow
.cardStyle(highlighted: true)     // Card with optional highlight
```

### Button Styles
```swift
Button("Action") { }
    .buttonStyle(PrimaryButtonStyle())    // Gradient background

Button("Cancel") { }
    .buttonStyle(SecondaryButtonStyle())  // Transparent with border
```

### Gradients
```swift
MomentumGradients.primary    // Deep blue → Violet
MomentumGradients.success    // Green gradient
MomentumGradients.gold       // Gold gradient (achievements)
MomentumGradients.background // Dark background gradient
```

## AI Integration

### Groq API
- **Base URL**: `https://api.groq.com/openai/v1`
- **Model**: `llama-3.3-70b-versatile`
- **Key Location**: `Config.groqAPIKey`

### GroqService Methods
```swift
// Onboarding
generateOnboardingQuestions(vision:goalType:) → [OnboardingQuestion]
generateGoalPlan(vision:answers:) → AIGeneratedPlan

// Task Help
getTaskHelp(task:context:) → String
generateMicrosteps(for:) → [Microstep]

// Research
analyzeMessageIntent(message:taskContext:) → MessageIntent
generateResearchClarifications(query:taskContext:) → [String]
performBrowserSearch(query:clarifications:) → ResearchFinding
```

## Patterns & Conventions

### State Management
- Use `@EnvironmentObject var appState: AppState` for global state
- AppState is `@MainActor` - all UI updates thread-safe
- Auto-save on every change to UserDefaults

### Sheet Presentation
```swift
// Always use item-based sheets (prevents blank screens)
.sheet(item: $selectedTask) { task in
    TaskDetailView(task: task)
}
```

### Navigation
- Tab-based via MainTabView
- Modal sheets for details
- Dark mode forced: `.preferredColorScheme(.dark)`

### Async/Await
```swift
Task {
    let result = await groqService.generateGoalPlan(vision: vision, answers: answers)
    // Handle result
}
```

## Common Tasks

### Adding a New View
1. Create file in appropriate `Views/` subdirectory
2. Import SwiftUI and PhosphorSwift
3. Add `@EnvironmentObject var appState: AppState`
4. Use `Color.momentumDarkBackground` as root background
5. Apply `.preferredColorScheme(.dark)`

### Adding an Icon
```swift
import PhosphorSwift

Ph.iconName.regular    // Regular weight
Ph.iconName.fill       // Filled
Ph.iconName.bold       // Bold weight
```
Browse icons at: https://phosphoricons.com

### Adding a New Model
1. Add struct to `Models.swift`
2. Conform to `Identifiable, Codable`
3. Add corresponding property to AppState if needed
4. Add persistence key if storing separately

### Modifying AI Prompts
- All prompts in `GroqService.swift`
- System prompts define AI personality and response format
- Use JSON response format for structured data

## Build & Run

```bash
# Open project
open Momentum.xcodeproj

# Build (Cmd+B)
# Run on simulator (Cmd+R)
# Target: iOS 26.0+
```

## Configuration

Edit `Config.swift` for:
- `groqAPIKey` - Groq API key
- `groqAPIBaseURL` - API endpoint
- `groqModel` - Model selection
- `appVersion` - Version string

## Workflow Requirements

### Always Ask Clarifying Questions

Before making significant changes, **always ask clarifying questions** when:
- Requirements are ambiguous or incomplete
- Multiple implementation approaches are possible
- Changes could affect existing functionality
- You're unsure about the user's intent or preferences
- The task involves architectural decisions

Do not assume - it's better to ask and get it right than to make incorrect changes.

### Always Push to GitHub

After completing any code changes:

1. **Stage and commit** your changes with a descriptive commit message
2. **Push to the remote repository** at the end of your work session
3. **Verify the push was successful** before confirming completion

```bash
git add .
git commit -m "Description of changes"
git push origin main
```

**Important:**
- Never commit `Config.swift` (contains API keys, already in .gitignore)
- Repository: https://github.com/Axionautomation/Momentum.git
