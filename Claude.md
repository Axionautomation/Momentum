# Momentum

AI coworker for career, finance, and personal growth — the AI is the engine, the user is the pilot.

## Vision

Momentum is evolving from a goal-tracking app into a proactive AI coworker that researches, drafts, schedules, and executes alongside the user. The AI doesn't wait to be asked — it prepares morning briefings with overnight research, drafts content, schedules focus sessions, and presents actionable recommendations. Users steer; the AI does the heavy lifting.

The core loop: User inputs vision → AI generates 12 milestones → daily tasks with checklists → AI proactively researches, drafts content, and schedules work → morning briefing summarizes progress and next steps.

See `Plan.md` for the full 8-phase transformation roadmap.

## Tech Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with centralized AppState
- **AI**: Groq API (llama-3.3-70b-versatile) — expanding to multi-model (Groq fast + Claude complex)
- **Persistence**: UserDefaults (JSON Codable) — migrating to Firebase Firestore
- **Icons**: PhosphorSwift
- **Design**: Dark-first, glassmorphic, bold typography

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
│   └── Models.swift              # All data models (Goals, Milestones, Tasks, GoalDomain)
├── ViewModels/
│   └── AppState.swift            # Centralized state management (3-tab navigation)
├── Views/
│   ├── MainTabView.swift         # Root navigation (3 tabs: Dashboard, Goals, Profile)
│   ├── Home/
│   │   ├── HomeView.swift        # Dashboard / daily view
│   │   ├── TaskCardView.swift    # Squircle task cards with hold-to-complete
│   │   ├── TaskExpandedView.swift # Task detail sheet
│   │   ├── CelebrationView.swift # Task completion celebration
│   │   └── WeeklyProgressRing.swift # Progress ring component
│   ├── Process/
│   │   ├── ProcessView.swift     # Goals overview
│   │   └── ProjectWorkspaceView.swift # Project detail workspace
│   ├── Today/
│   │   └── TodayView.swift       # Today's task view
│   ├── Mindset/
│   │   └── MindsetView.swift     # Quotes & affirmations
│   ├── Profile/
│   │   └── ProfileView.swift     # Settings & account
│   ├── Onboarding/
│   │   └── OnboardingView.swift  # User onboarding flow
│   └── Components/
│       ├── FloatingAIButton.swift    # Floating AI chat trigger (gradient)
│       ├── GlobalAIChatView.swift    # AI chat (overlay panel + modal)
│       ├── AIAssistantView.swift     # Task-specific help
│       ├── TaskPickerView.swift      # Task selection modal
│       ├── TaskDetailView.swift      # Task detail with checklist
│       ├── SwipeableTaskStack.swift  # Swipeable card stack
│       ├── DifficultyBadge.swift     # Task difficulty indicator
│       └── QuizHelpBubble.swift      # Skill assessment quiz
├── Services/
│   ├── GroqService.swift             # AI integration (1,600+ lines)
│   ├── ConversationOrchestrator.swift # Multi-turn conversations
│   └── MockDataService.swift         # Demo data
├── Utilities/
│   ├── Config.swift              # API keys, app config
│   └── Theme.swift               # Design system (dark-first, glassmorphic)
└── Assets/                       # Images, colors, app icons
```

## Key Files

| File | Purpose |
|------|---------|
| `Models.swift` | Data models: MomentumUser, Goal, GoalDomain, Milestone, MomentumTask, ChecklistItem, TaskNotes |
| `AppState.swift` | @MainActor state container, 3-tab navigation (dashboard/goals/profile), persistence |
| `GroqService.swift` | AI API calls: onboarding, plan generation, task evaluation, research, chat |
| `Config.swift` | API keys, base URLs, app version |
| `Theme.swift` | Dark-first design system: colors, glassmorphism, typography, animations, gradients |
| `MainTabView.swift` | 3-tab FloatingTabBar + persistent chat overlay panel |

## Data Model Hierarchy

```
Goal (with GoalDomain: .career | .finance | .growth)
├── visionText / visionRefined
└── Milestone[] (12 sequential milestones)
    └── MomentumTask[] (daily tasks with checklists)
        ├── ChecklistItem[] (step-by-step with time estimates)
        ├── TaskNotes (conversations, research, brainstorms)
        └── AITaskEvaluation (AI assessment + tool prompts)
```

### GoalDomain
```swift
enum GoalDomain: String, Codable, CaseIterable {
    case career   // Blue accent
    case finance  // Green accent
    case growth   // Violet accent
}
```

## Design System

### Colors (Dark-First)
```swift
// Background
Color.momentumBackground           // #09090B - zinc-950 (primary)
Color.momentumBackgroundSecondary  // #18181B - zinc-900

// Surface / Cards
Color.momentumCardBackground       // #18181B - zinc-900
Color.momentumCardBorder           // white 8% opacity

// Accent
Color.momentumBlue                 // #3B82F6 - Electric blue (primary accent)
Color.momentumBlueLight            // #06B6D4 - Cyan
Color.momentumViolet               // #8B5CF6 - Violet

// Status
Color.momentumSuccess              // #10B981 - Emerald
Color.momentumWarning              // #F59E0B - Amber
Color.momentumDanger               // #EF4444 - Red

// Text
Color.momentumTextPrimary          // #FAFAFA - zinc-50
Color.momentumTextSecondary        // #A1A1AA - zinc-400
Color.momentumTextTertiary         // #71717A - zinc-500

// Domain Colors
Color.momentumCareer               // Blue
Color.momentumFinance              // Green
Color.momentumGrowth               // Violet
```

### Typography (SF Pro Display)
```swift
MomentumFont.headingLarge()      // 28pt bold
MomentumFont.headingMedium()     // 22pt semibold
MomentumFont.body()              // 17pt regular
MomentumFont.bodyMedium()        // 17pt medium
MomentumFont.label()             // 13pt medium
MomentumFont.caption()           // 12pt regular
```

### View Modifiers
```swift
.momentumCard()              // Dark card with border + corner radius
.glass()                     // Ultra-thin material glassmorphism
.glassCard()                 // Glass + card styling
.glowBorder(color:)          // Animated gradient border
```

### Button Styles
```swift
Button("Action") { }
    .buttonStyle(PrimaryButtonStyle())    // Blue gradient + glow shadow

Button("Cancel") { }
    .buttonStyle(SecondaryButtonStyle())  // Transparent + border
```

### Gradients
```swift
MomentumGradients.primary    // Blue → Cyan
MomentumGradients.neonBlue   // Electric blue → Cyan
MomentumGradients.neonViolet // Violet → Fuchsia
MomentumGradients.success    // Green gradient
MomentumGradients.midnight   // zinc-950 → zinc-900
```

### Animations
```swift
MomentumAnimation.smoothSpring   // response: 0.35, damping: 0.85
MomentumAnimation.snappy         // response: 0.25, damping: 0.9
MomentumAnimation.dramatic       // response: 0.5, damping: 0.7
MomentumAnimation.staggered(index:) // Staggered entrance delays
```

### Spacing
```swift
MomentumSpacing.tight        // 4
MomentumSpacing.compact      // 8
MomentumSpacing.standard     // 12
MomentumSpacing.comfortable  // 16
MomentumSpacing.large        // 20
MomentumSpacing.section      // 24
```

## Navigation

- **3 tabs**: Dashboard (house), Goals (target), Profile (user)
- **Floating tab bar**: Glassmorphic `.ultraThinMaterial` at bottom
- **Floating AI button**: Blue→Cyan gradient, opens chat overlay
- **Chat panel**: Persistent overlay (not modal), swipe-down to dismiss
- **Dark mode enforced**: `.preferredColorScheme(.dark)` at root

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

// Task Management
evaluateTodaysTasks(tasks:milestoneContext:goalContext:) → [TaskWithEvaluation]
generateChecklistForTask(task:milestoneContext:goalContext:) → [ChecklistItem]

// Chat & Research
analyzeMessageIntent(message:taskContext:) → MessageIntent
performBrowserSearch(query:clarifications:) → ResearchFinding

// Skill Assessment
generateSkillQuestion(task:goal:) → SkillQuestion
```

## Patterns & Conventions

### State Management
- Use `@EnvironmentObject var appState: AppState` for global state
- AppState is `@MainActor` - all UI updates thread-safe
- Auto-save on every change to UserDefaults
- Active goal accessed via `appState.activeGoal`

### Chat Overlay
```swift
// GlobalAIChatView supports both overlay and modal modes
GlobalAIChatView(isOverlay: true, onDismiss: { dismissChat() })
GlobalAIChatView()  // Default modal mode
```

### Navigation Tabs
```swift
enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case goals = "Goals"
    case profile = "Profile"
}
```

### Dark Theme
- All views use dark color tokens from Theme.swift
- All previews include `.preferredColorScheme(.dark)`
- Background: `Color.momentumBackground` (not `Color.white`)
- Text: `.momentumTextPrimary`, `.momentumTextSecondary`, `.momentumTextTertiary`

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
4. Use `Color.momentumBackground` as root background
5. Use dark color tokens for all surfaces and text
6. Add `.preferredColorScheme(.dark)` to preview

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
5. Add `GoalDomain` if goal-related

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
# Target: iOS 17.0+
```

## Configuration

Edit `Config.swift` for:
- `groqAPIKey` - Groq API key
- `groqAPIBaseURL` - API endpoint
- `groqModel` - Model selection
- `appVersion` - Version string

## Workflow Requirements

### Always Ask Clarifying Questions

Before making significant changes, **always ask clarifying questions** using AskUserQuestion when:
- Requirements are ambiguous or incomplete
- Multiple implementation approaches are possible
- Changes could affect existing functionality
- You're unsure about the user's intent or preferences
- The task involves architectural decisions

Never assume - it's better to ask and get it right than to make incorrect changes.

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
