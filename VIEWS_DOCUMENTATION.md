# Momentum App - Views Architecture Documentation

> **Note:** This documentation covers all views except onboarding, which remains unchanged.

---

## Table of Contents
1. [Navigation Structure](#navigation-structure)
2. [Main Tab Views](#main-tab-views)
3. [AI Companion Views](#ai-companion-views)
4. [Modal Sheets & Components](#modal-sheets--components)
5. [View Relationships](#view-relationships)

---

## Navigation Structure

### MainTabView.swift
**Location:** `/Views/MainTabView.swift`

**Purpose:** Root navigation container for the entire app using a tab-based interface with Whoop-style floating AI button.

**Key Features:**
- **5 Bottom Tabs:**
  1. Today (home icon)
  2. Road (map icon)
  3. Goals (target icon)
  4. Stats (chart icon)
  5. Me/Profile (person icon)
- **Floating AI Button:** Bottom-right corner (20pt trailing, 90pt above tab bar)
- **Global AI Chat Sheet:** Full-screen modal triggered by floating button
- **Dark Mode:** Forces dark color scheme across entire app

**Technical Details:**
- Uses `ZStack` to overlay floating button on top of `TabView`
- State managed via `@EnvironmentObject var appState: AppState`
- Selected tab tracked with `appState.selectedTab`
- Tint color: `.momentumViolet` (brand purple)

**Layout:**
```
ZStack {
  TabView (5 tabs)
  FloatingAIButton (overlay)
}
.sheet(isPresented: $appState.showGlobalChat) {
  GlobalAIChatView()
}
```

---

## Main Tab Views

### 1. TodayView.swift
**Location:** `/Views/Today/TodayView.swift`

**Purpose:** Daily task dashboard - the main "home screen" where users interact with their 3 daily tasks.

**Key Sections:**

1. **Header:**
   - Profile icon (tap → navigates to Profile tab)
   - Streak counter (🔥 icon + days)

2. **Vision Card:**
   - Displays user's refined annual vision/goal
   - Gold gradient background with border
   - Trophy icon (🏆)

3. **Today's Momentum:**
   - Current date display
   - 3 task cards for the day (Easy, Medium, Hard)
   - Each card shows:
     - Task title
     - Difficulty emoji + color
     - Estimated minutes
     - Status (not started, in progress, completed)
     - Tap to open `TaskDetailSheet`

4. **Weekly Progress:**
   - Circular progress indicator
   - "X of Y tasks complete this week"
   - Percentage completion

5. **View Journey Button:**
   - Secondary button → navigates to Road tab

**Interactions:**
- Tap task card → Opens `TaskDetailSheet` with:
  - Task details
  - Microsteps (AI-generated sub-tasks)
  - Complete button
  - AI Assistant button
- Complete task → Celebration toast appears
- Complete all 3 tasks → Full-screen celebration animation

**State Management:**
- `@State private var selectedTask: MomentumTask?` - Sheet presentation
- Uses `.sheet(item:)` pattern (prevents blank screen bug)

**Sub-Components:**
- `TaskCardView` - Individual task cards
- `TaskDetailSheet` - Task detail modal
- `CompletionToast` - Task completion feedback
- `AllTasksCompleteCelebrationView` - 3-task completion celebration

---

### 2. RoadView.swift
**Location:** `/Views/Road/RoadView.swift`

**Purpose:** Visual journey map showing the user's 12 Power Goals as a winding road from current position to annual vision destination.

**Key Sections:**

1. **Goal Destination (Top):**
   - 🏆 trophy icon
   - User's refined vision statement
   - Gold gradient background with glow effect
   - Represents the "finish line"

2. **Winding Road with Power Goals:**
   - 12 Power Goals displayed as nodes on a curved path
   - Road alternates left/right (zigzag pattern)
   - Each node shows:
     - Circle indicator (colored by status)
     - Power Goal title
     - Month indicator
   - **Node Colors:**
     - Green: Completed
     - Purple (momentumViolet): Active/In Progress
     - Gray: Not Started
   - Current power goal has pulsing effect
   - Tap node → Opens `PowerGoalDetailSheet`

3. **Stats Card (Bottom):**
   - Completion percentage
   - Tasks completed count
   - Current streak

**Technical Details:**
- Uses `GeometryReader` and `Path` to draw curved road segments
- Power Goals displayed in reverse order (month 12 → 1, bottom to top)
- Alternating left/right calculated with `index % 2 == 0`

**Interactions:**
- Tap power goal node → Opens detail sheet showing:
  - Power goal description
  - Weekly milestones
  - Task breakdown
  - Progress indicators

**Sub-Components:**
- `PowerGoalDetailSheet` - Power goal detail modal

---

### 3. GoalsView.swift
**Location:** `/Views/Goals/GoalsView.swift`

**Purpose:** Detailed goals and tasks management view with expandable task notes, research findings, and brainstorming.

**Key Sections:**

1. **Header:**
   - "Your Goals" title
   - Vision statement display

2. **Power Goals Breakdown:**
   - Current power goal prominently displayed
   - Weekly milestones as expandable cards
   - "View Breakdown" button to expand/collapse

3. **Tasks with Notes System:**
   - Each task displays:
     - Title
     - Difficulty badge
     - Estimated time
     - Completion status
     - **Notes indicator** (note.text icon if task has notes)
     - Chevron (up/down) for expansion
   - Tap task → Expands to show `taskNotesSection`

4. **Task Notes Section (Expandable):**
   When a task is expanded, shows:

   a. **Brainstorm Section:**
      - Text input field
      - Placeholder: "Put brainstormed ideas here and I will help you do them"
      - Auto-saves to task notes

   b. **Research Findings:**
      - Cards for each research finding
      - Shows: Query, clarifying Q&A, results preview
      - Timestamp
      - "Read more" expansion

   c. **Conversation History:**
      - Last 3 AI conversation messages
      - User messages (right-aligned, purple)
      - AI messages (left-aligned, gray)
      - "View full conversation" link

   d. **AI Help Button:**
      - "Ask AI for help with this task" button
      - Opens `GlobalAIChatView` with task context

**State Management:**
- `@State private var expandedTaskId: UUID?` - Tracks which task notes are shown
- `@State private var brainstormText: String` - Brainstorm input
- Tasks with notes tracked via `appState.tasksWithNotes()`

**Interactions:**
- Tap task row → Toggle expansion
- Type in brainstorm field → Auto-saves to `appState.updateBrainstorm()`
- Tap "Ask AI" → Opens global chat with task context pre-loaded

**Technical Details:**
- Uses accordion/progressive disclosure pattern
- Notes auto-save immediately (no "Save" button needed)
- Background: `Color.white.opacity(0.03)` for expanded sections

---

### 4. StatsView.swift
**Location:** `/Views/Stats/StatsView.swift`

**Purpose:** Comprehensive statistics and progress analytics dashboard.

**Key Sections:**

1. **Overview Card:**
   - 2x2 grid of key metrics:
     - Total Tasks (checkmark icon)
     - Completion Rate (chart icon)
     - Current Streak (🔥 emoji + days)
     - Longest Streak (🔥 emoji + days)

2. **Weekly Chart:**
   - Bar chart showing daily task completion
   - 7 days (Mon-Sun)
   - Uses SwiftUI Charts framework
   - Purple bars for completion count

3. **Premium Insights (Locked):**
   - Shows locked features for free users
   - Teases AI-powered insights
   - "Upgrade to Premium" button
   - Displays:
     - Peak productivity times
     - Task difficulty analysis
     - Completion patterns
     - AI recommendations

4. **Monthly Progress:**
   - Progress bar for current month
   - Power Goals completed
   - Tasks completed vs. total

5. **Achievements Section:**
   - Badge display (locked/unlocked)
   - Achievement titles
   - Progress toward next achievement

**Data Sources:**
- Live data from `appState`
- Mock data from `MockDataService` (for charts/achievements)

**Monetization Hook:**
- Premium insights card incentivizes upgrade
- Shows value of premium tier

---

### 5. ProfileView.swift
**Location:** `/Views/Profile/ProfileView.swift`

**Purpose:** User profile, settings, and account management.

**Key Sections:**

1. **Profile Card:**
   - Profile icon (person.circle.fill)
   - User name: "Henry Smith"
   - Email address
   - Member since date

2. **Premium Features Card:**
   - Current subscription tier display
   - Premium features list:
     - AI-powered insights
     - Advanced analytics
     - Priority support
     - Custom AI personalities
   - Expiration date (if applicable)
   - "Upgrade to Premium" button

3. **Settings Section:**
   - Notification settings (toggle)
   - Dark mode (always on)
   - Language settings
   - Data & privacy
   - AI Personality customization

4. **Manage Goals Section:**
   - "Generate New Plan" button
     - Opens `QuickPlanGeneratorSheet`
     - Lets users create additional goals
   - "Edit Current Goal" option
   - "Archive Completed Goals" option

5. **Support Section:**
   - Help Center link
   - Contact Support
   - Rate the App
   - Share Momentum
   - Privacy Policy
   - Terms of Service

6. **Log Out Button:**
   - Red text button
   - Calls `appState.resetOnboarding()`
   - Clears user data and returns to onboarding

**Modal Sheets:**
- `PremiumUpgradeSheet` - Subscription purchase flow
- `AIPersonalitySheet` - Customize AI companion tone
- `QuickPlanGeneratorSheet` - Generate new goals

**Technical Details:**
- Uses `@EnvironmentObject var appState: AppState`
- Settings changes persist via UserDefaults
- Premium status checked via `appState.currentUser?.subscriptionTier`

---

## AI Companion Views

### FloatingAIButton.swift
**Location:** `/Views/Components/FloatingAIButton.swift`

**Purpose:** Whoop-style floating action button for accessing global AI companion from anywhere.

**Design:**
- **Size:** 60x60 circular button
- **Icon:** Sparkles (✨) symbol in white
- **Background:** MomentumGradients.primary (purple gradient)
- **Position:** Fixed bottom-right (20pt trailing, 90pt bottom)
- **Animation:** Pulsing ring effect (60px → 70px, repeating)
- **Shadow:** Purple glow effect

**Behavior:**
- Tap → Calls `appState.openGlobalChat()`
- Stays above tab bar at all times
- `.ignoresSafeArea(.keyboard)` - Doesn't move when keyboard appears
- Always accessible regardless of current tab

**Technical Details:**
- Uses `@State private var isPulsing: Bool` for animation
- Animation: `.easeInOut(duration: 2.0).repeatForever(autoreverses: true)`
- ZStack with outer pulse ring + inner solid circle

---

### GlobalAIChatView.swift
**Location:** `/Views/Components/GlobalAIChatView.swift`

**Purpose:** Full-screen AI companion chat interface with task context awareness and research capabilities.

**Key Features:**

1. **Task Context Header:**
   - **With Task Context:**
     - "Working on: [Task Title]"
     - "Switch Task" button → Opens `TaskPickerView`
   - **Without Task Context:**
     - "Select a task for context" button
     - Opens `TaskPickerView` to choose task

2. **Conversation Area:**
   - ScrollView with message bubbles
   - **AI greeting:** "Hi! I'm your AI companion. I can research things, help with tasks, and brainstorm ideas."
   - **Message Types:**
     - User messages: Right-aligned, purple background
     - AI messages: Left-aligned, gray background, sparkle icon
     - System messages: Clarifying questions UI
   - **Conversation History:** Loads from `task.notes.conversationHistory`
   - Auto-scrolls to bottom on new messages

3. **Clarifying Questions UI:**
   When AI detects research request:
   - AI message: "I have a few questions to help me research this better:"
   - Numbered question list (1, 2, 3...)
   - Text input fields for each answer
   - "Start Research" button (disabled until all answered)
   - Purple gradient button with search icon

4. **Input Section:**
   - Multi-line text field (1-4 lines)
   - Placeholder: "Ask me anything..." or "Answer the questions above..."
   - Send button (arrow.up.circle.fill icon)
   - Disabled during processing or when clarifying

5. **Loading States:**
   - Progress spinner + "Generating questions..." or "Researching..."
   - Prevents multiple simultaneous requests

**Conversation Flow:**

1. **User asks question** → AI analyzes intent
2. **If research request:**
   - AI generates 2-3 clarifying questions
   - User answers questions
   - Tap "Start Research"
   - AI performs browser search using Groq
   - AI synthesizes results
   - Research finding auto-saved to task notes
3. **If general help:**
   - AI responds directly
   - Conversation auto-saved

**State Management:**
- `@StateObject private var orchestrator = ConversationOrchestrator()`
- `@EnvironmentObject var appState: AppState`
- `@State private var conversationHistory: [(question: String, answer: String)]`
- `@State private var clarificationAnswers: [String]`

**Auto-Save:**
- Every message automatically saved via:
  - `appState.addConversationMessage(taskId:message:)`
  - `appState.addResearchFinding(taskId:finding:)`
- No manual save button needed

**Technical Details:**
- Uses `ConversationOrchestrator` for multi-turn conversations
- Groq browser_search tool for research
- ScrollViewReader for auto-scroll
- `.onChange(of: orchestrator.currentConversation.count)` triggers scroll

---

### TaskPickerView.swift
**Location:** `/Views/Components/TaskPickerView.swift`

**Purpose:** Task selection modal for switching AI chat context.

**Content:**
- Lists all active tasks from in-progress milestones
- Sorted by scheduled date
- Each task row shows:
  - Task title
  - Difficulty emoji + name
  - Date label (Today, Tomorrow, Yesterday, or MMM d)
  - Status indicator (checkmark if completed)
  - Chevron arrow

**Behavior:**
- Tap task → Calls `onSelect(task)` callback
- Closes modal
- `GlobalAIChatView` switches to new task context
- Loads conversation history for selected task

**Empty State:**
- If no tasks: Shows empty state
  - Tray icon
  - "No active tasks found"
  - "Complete onboarding to create your first goal and tasks"

**Technical Details:**
- NavigationView with inline title
- "Cancel" button in trailing toolbar
- Dark background matching app theme

---

### AIAssistantView.swift
**Location:** `/Views/Components/AIAssistantView.swift`

**Purpose:** Task-specific AI assistant modal (opened from TaskDetailSheet).

**Similar to GlobalAIChatView but:**
- Always scoped to specific task (passed as parameter)
- No task picker (locked to one task)
- Shows task info header (title, time, description)
- Suggested questions at bottom:
  - "How do I get started?"
  - "What resources do I need?"
  - "Can you break this into smaller steps?"

**Key Features:**
- Same conversation orchestrator pattern
- Same clarifying questions flow
- Same research capabilities
- Auto-saves to task notes
- Loads existing conversation history

**Differences from GlobalAIChatView:**
- Presented as sheet from task detail (not global)
- No task switching
- Task context always visible at top
- Suggested questions for first-time users

---

## Modal Sheets & Components

### TaskDetailSheet
**Location:** Defined in `TodayView.swift`

**Purpose:** Detailed view of a single task with actions and microsteps.

**Content:**
1. Task title and description
2. Metadata (time, difficulty)
3. Microsteps section:
   - AI-generated sub-tasks
   - "Generate Microsteps" button (uses Groq)
   - Loading state while generating
   - Checkable steps
4. Complete Task button (primary gradient button)
5. Ask AI Assistant button (opens `AIAssistantView`)

**Presentation:**
- Medium/Large detents (user can resize)
- Drag indicator visible
- Dark background

**Actions:**
- Complete → Calls `appState.completeTask()`
- Generate Microsteps → Calls `groqService.generateMicrosteps()`
- Ask AI → Opens `AIAssistantView` modal

---

### PowerGoalDetailSheet
**Location:** Defined in `RoadView.swift`

**Purpose:** Detailed view of a Power Goal with weekly milestones.

**Content:**
1. Power Goal title
2. Description
3. Month indicator
4. Weekly milestones list (1-5 weeks)
5. Each milestone shows:
   - Week number
   - Milestone description
   - Task count
   - Progress indicator
6. Status badge (Active, Completed, Not Started)

**Presentation:**
- Medium detent
- Drag indicator

---

### TaskCardView
**Location:** Defined in `TodayView.swift`

**Purpose:** Reusable card component for displaying task summary.

**Content:**
- Task title
- Difficulty color stripe on left edge
- Difficulty emoji + name
- Estimated time with clock icon
- Status icon (checkmark if completed)
- Tap gesture → Opens task detail

**Design:**
- White.opacity(0.08) background
- Rounded corners (12px)
- Horizontal padding
- Difficulty color: Left border accent

---

### CompletionToast
**Location:** Defined in `TodayView.swift`

**Purpose:** Temporary notification shown when task is completed.

**Content:**
- Checkmark icon
- "Task Completed!" message
- Slide down from top animation
- Auto-dismisses after 2-3 seconds

**Animation:**
- `.move(edge: .top).combined(with: .opacity)`
- Spring animation

---

### AllTasksCompleteCelebrationView
**Location:** Referenced in `TodayView.swift`

**Purpose:** Full-screen celebration when user completes all 3 daily tasks.

**Content:**
- Animated confetti/celebration graphics
- Congratulatory message
- Streak update (if applicable)
- Continue button
- Motivational quote

**Trigger:**
- Appears when `appState.showAllTasksCompleteCelebration == true`
- Set when third task of the day is marked complete

---

## View Relationships

### Navigation Flow

```
MainTabView (Root)
├─ TodayView (Tab 1)
│  ├─ TaskDetailSheet (Modal)
│  │  └─ AIAssistantView (Modal)
│  ├─ CompletionToast (Overlay)
│  └─ AllTasksCompleteCelebrationView (Overlay)
│
├─ RoadView (Tab 2)
│  └─ PowerGoalDetailSheet (Modal)
│
├─ GoalsView (Tab 3)
│  └─ Inline Task Notes (Expandable)
│
├─ StatsView (Tab 4)
│  └─ (No modals)
│
├─ ProfileView (Tab 5)
│  ├─ PremiumUpgradeSheet (Modal)
│  ├─ AIPersonalitySheet (Modal)
│  └─ QuickPlanGeneratorSheet (Modal)
│
└─ FloatingAIButton (Global Overlay)
   └─ GlobalAIChatView (Modal)
      └─ TaskPickerView (Modal)
```

### Data Flow

```
AppState (Central State)
    ↓
[All Views Access via @EnvironmentObject]
    ↓
├─ Current User
├─ Active Goal
├─ Power Goals
├─ Weekly Milestones
├─ Tasks
├─ Task Notes
│  ├─ Conversation History
│  ├─ Research Findings
│  └─ User Brainstorms
└─ Global Chat State
```

### AI Service Flow

```
User Interaction
    ↓
ConversationOrchestrator
    ↓
├─ Intent Analysis (GroqService)
├─ Clarifying Questions (GroqService)
└─ Browser Search (GroqService with browser_search tool)
    ↓
Auto-Save to AppState
    ↓
Persist to UserDefaults
```

---

## Design System

### Colors
- **Background:** `Color.momentumDarkBackground` (dark brown/black)
- **Primary Accent:** `Color.momentumViolet` (purple)
- **Success:** `Color.momentumGreenStart` (green)
- **Warning:** `Color.momentumGold` (gold/yellow)
- **Text Primary:** `.white`
- **Text Secondary:** `Color.momentumSecondaryText` (light gray)
- **Card Background:** `Color.white.opacity(0.08)`
- **Gradients:** `MomentumGradients.primary` (purple gradient)

### Typography
- **Heading:** `MomentumFont.heading(size)` - Bold, prominent
- **Body:** `MomentumFont.body(size)` - Regular weight
- **Body Medium:** `MomentumFont.bodyMedium(size)` - Medium weight
- **Stats:** `MomentumFont.stats(size)` - Number display

### Spacing
- **Section Padding:** 24px vertical
- **Horizontal Margins:** 16-20px
- **Card Padding:** 16px
- **Card Spacing:** 12-16px between cards
- **Corner Radius:** 12-20px (cards), 16px (modals)

### Buttons
- **Primary:** Gradient background, white text, 12px radius
- **Secondary:** Outlined, purple text, 12px radius
- **Destructive:** Red text, transparent background

---

## Key Technical Patterns

### 1. Sheet Presentation
**Always use `.sheet(item:)` for object-based sheets:**
```swift
@State private var selectedTask: MomentumTask?

.sheet(item: $selectedTask) { task in
    TaskDetailSheet(task: task)
}
```
**Why:** Prevents blank screen bugs on app reopen.

### 2. Auto-Save Pattern
**No manual save buttons - everything auto-saves:**
```swift
appState.addConversationMessage(taskId: task.id, message: msg)
appState.addResearchFinding(taskId: task.id, finding: finding)
appState.updateBrainstorm(taskId: task.id, content: text)
```

### 3. Progressive Disclosure
**GoalsView uses accordion pattern:**
- Tap to expand task notes
- Only one task expanded at a time
- Chevron indicates expansion state
- Smooth animations

### 4. Task Context Awareness
**AI features always know which task:**
```swift
// Global chat
appState.globalChatTaskContext

// Task-specific
let task: MomentumTask // passed as parameter
```

### 5. Environment Object
**All views use AppState:**
```swift
@EnvironmentObject var appState: AppState
```
**Provides access to:**
- User data
- Goals and tasks
- Navigation state
- AI chat state

---

## Future Considerations

### Planned Features (Not Yet Implemented)
1. **Social Sharing:** Share achievements to social media
2. **Team Goals:** Collaborative goal tracking
3. **AI Personality Customization:** Change AI tone/style
4. **Habit Tracking:** Daily habit integration
5. **Calendar Integration:** Sync with iOS Calendar
6. **Widgets:** Home screen widgets for today's tasks
7. **Apple Watch:** Companion app for quick task completion
8. **Offline Mode:** Task completion without internet

### Scalability Notes
- **UserDefaults Limits:** Current storage is ~1MB practical limit
  - Consider Core Data migration if notes grow large
  - Monitor with `appState.estimateDataSize()`
- **API Rate Limits:** Groq API has rate limits
  - Implement request caching for research
  - Show usage warnings at 80% limit
- **Performance:**
  - Lazy loading for large task lists
  - Pagination for conversation history
  - Image optimization if added later

---

## Accessibility

### Current Support
- **VoiceOver:** All buttons and cards labeled
- **Dynamic Type:** Text scales with system settings
- **High Contrast:** Dark mode optimized
- **Color Blind:** Uses icons + text (not color alone)

### Keyboard Navigation
- All interactive elements focusable
- Sheet dismissal via swipe down
- Form fields navigate with tab

---

## Testing Checklist

### Critical User Flows
- [ ] Complete onboarding → See first 3 tasks in TodayView
- [ ] Tap task → TaskDetailSheet opens
- [ ] Complete task → Toast appears
- [ ] Complete 3 tasks → Celebration shows
- [ ] Tap floating AI → GlobalAIChatView opens
- [ ] Ask research question → Clarifications appear
- [ ] Answer clarifications → Research performs
- [ ] Switch task context → TaskPickerView works
- [ ] Expand task notes in GoalsView → Notes display
- [ ] Type brainstorm → Auto-saves
- [ ] Tap Road tab → See 12 power goals on path
- [ ] Tap power goal → Detail sheet opens
- [ ] View Stats → Charts render
- [ ] Go to Profile → Settings load
- [ ] Log out → Returns to onboarding

### Edge Cases
- [ ] App reopen after close → No blank screens
- [ ] No internet → Graceful error handling
- [ ] API failure → User-friendly error message
- [ ] Empty states → Proper placeholder content
- [ ] Very long task titles → Text truncates properly
- [ ] Many research findings → Scrolls smoothly

---

## File Organization

```
Views/
├── MainTabView.swift               # Root navigation
├── Today/
│   └── TodayView.swift            # Tab 1: Daily tasks
├── Road/
│   └── RoadView.swift             # Tab 2: Journey map
├── Goals/
│   └── GoalsView.swift            # Tab 3: Goals detail + notes
├── Stats/
│   └── StatsView.swift            # Tab 4: Analytics
├── Profile/
│   └── ProfileView.swift          # Tab 5: Settings & account
├── Components/
│   ├── FloatingAIButton.swift     # Global AI button
│   ├── GlobalAIChatView.swift     # Global AI chat
│   ├── TaskPickerView.swift       # Task selection modal
│   └── AIAssistantView.swift      # Task-specific AI help
└── Onboarding/
    └── OnboardingView.swift       # [Not documented - no changes]
```

---

*Last Updated: January 1, 2026*
*Version: 1.0 (App Store Ready)*
