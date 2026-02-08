# Momentum: App Store Launch Guide

## From Goal Tracker to AI Coworker

Momentum evolves from a reactive goal-tracking app into a bold, futuristic AI coworker for career, finance, and personal growth. The AI proactively researches, drafts content, schedules work sessions, and presents a morning briefing — while the human steers.

**The coworker model:** AI is the engine, user is the pilot. The AI comes prepared with overnight research, takes initiative on tasks, drafts real content, remembers everything, and knows when to ask.

---

## Phase 1: Foundation Cleanup & Design System Overhaul ✅ COMPLETE

**Goal:** Establish the bold/futuristic design language and clean up technical debt.

### 1.1 Design System Overhaul (`Theme.swift`)
- [x] Define new dark-first color palette (zinc-950/900 backgrounds, glassmorphism surfaces)
- [x] Add glassmorphic view modifiers (`.glass()`, `.glassCard()`, `.glowBorder()`)
- [x] Add bold typography scale using SF Pro Display
- [x] Add animation presets (`.smoothSpring`, `.snappy`, `.dramatic`)
- [x] Add gradient presets (`.neonBlue`, `.neonViolet`, `.midnight`, `.aurora`)

### 1.2 Legacy Cleanup (`Models.swift`)
- [x] Remove legacy compatibility models: PowerGoal, WeeklyMilestone, PowerGoalStatus, WeeklyMilestoneStatus
- [x] Add `GoalDomain` enum: `.career`, `.finance`, `.growth`
- [x] Add domain property to `Goal` model
- [x] Add migration v5 to handle legacy data cleanup
- Note: TaskDifficulty, Microstep kept as derived/computed properties (still used by views)

### 1.3 Navigation Restructure (`MainTabView.swift`)
- [x] Change tabs from `home/process/mindset/profile` to `dashboard/goals/profile`
- [x] Replace modal sheet chat with persistent overlay panel
- [x] Update `FloatingTabBar` with glassmorphic style
- [x] Update tab icons and labels
- [x] Replace deprecated UIScreen.main with GeometryReader

### 1.4 Apply Design to All Existing Views
- [x] Update every view file to use new color tokens (removed all hardcoded Color.white/gray/blue)
- [x] Update all backgrounds to zinc-950/900
- [x] Ensure `.preferredColorScheme(.dark)` on all previews
- [x] Update CLAUDE.md to reflect new architecture
- [x] Fix all legacy initializer references (weeklyMilestoneId → milestoneId, powerGoals → milestones)

---

## Phase 2: Dashboard & Morning Briefing

**Goal:** Build the command-center dashboard with the AI briefing system.

### 2.1 Dashboard View (`Views/Dashboard/DashboardView.swift`)
- [ ] Hero section: Morning briefing card with greeting, AI insight, quick stats
- [ ] Today's tasks section with domain color-coding
- [ ] AI Activity feed ("What I've been working on")
- [ ] Quick actions row

### 2.2 Briefing Engine (`Services/BriefingEngine.swift`)
- [ ] `generateMorningBriefing()` method
- [ ] Add `BriefingReport` model to Models.swift
- [ ] Cache briefing locally (regenerate if stale > 4 hours)
- [ ] Trigger briefing generation on app launch

### 2.3 Background Processing (`Services/AITaskProcessor.swift`)
- [ ] Add background task scheduling via `BGTaskScheduler`
- [ ] Register `com.momentum.briefing` background task
- [ ] Schedule daily briefing generation

---

## Phase 3: Multi-Model AI Architecture

**Goal:** Evolve from single Groq model to intelligent multi-model routing.

### 3.1 AI Service Router (`Services/AI/AIServiceRouter.swift`)
- [ ] Create `AIProvider` protocol with `complete()`, `name`, `costTier`
- [ ] Route requests by complexity (Groq for fast, Claude for complex)
- [ ] Implement fallback chain

### 3.2 Groq Provider (`Services/AI/GroqProvider.swift`)
- [ ] Extract Groq-specific API logic from GroqService
- [ ] Route through `AIProvider` protocol
- [ ] Maintain retry logic and JSON parsing

### 3.3 Claude Provider (`Services/AI/ClaudeProvider.swift`)
- [ ] Implement Anthropic Messages API integration
- [ ] Add tool use / function calling support
- [ ] Add streaming support for real-time chat

### 3.4 Refactor GroqService.swift
- [ ] Decompose into domain-specific services:
  - `OnboardingAIService.swift`
  - `TaskAIService.swift`
  - `ResearchAIService.swift`
  - `ContentAIService.swift`
  - `ChatAIService.swift`

---

## Phase 4: Agentic Capabilities & Integrations

**Goal:** Make the AI actually DO things — research, draft, schedule.

### 4.1 Web Research Pipeline
- [ ] Proactive research triggered by task creation, user request, or briefing
- [ ] Research flow: analyze -> generate queries -> fetch -> summarize -> save
- [ ] Present findings in briefing or AI feed

### 4.2 Content Drafting Service
- [ ] AI drafts: emails, LinkedIn posts, business plan sections, cover letters, pitch outlines
- [ ] Draft model with review/edit/approve flow
- [ ] Drafts appear in briefing and AI feed

### 4.3 Calendar Integration (EventKit)
- [ ] Request calendar access
- [ ] Schedule focus sessions, add deadlines, block time
- [ ] Show calendar conflicts
- [ ] Sync task due dates with calendar events

### 4.4 AI Memory System
- [ ] Persistent memory entries (skills, preferences, decisions, research, patterns)
- [ ] Searchable and context-injected into every AI prompt
- [ ] User can view, edit, and delete memories in Profile

---

## Phase 5: Notifications, Widgets & Polish

**Goal:** Keep users engaged outside the app. Make everything feel premium.

### 5.1 Notification System
- [ ] Request notification permission during onboarding
- [ ] Local notifications: morning briefing, task reminders, streak alerts, milestones
- [ ] Rich notifications with quick actions

### 5.2 Daily Briefing Widget (WidgetKit)
- [ ] Add WidgetKit extension target
- [ ] Create App Group for shared data
- [ ] Medium widget: top 3 tasks + streak + AI insight
- [ ] Small widget: streak + tasks remaining
- [ ] Glassmorphic dark design matching app

### 5.3 Haptics & Animation Polish
- [ ] Haptic feedback map (light, medium, success, warning)
- [ ] Animation polish: staggered entrances, task completion bounce, confetti, shimmers

---

## Phase 6: Profile Hub Rebuild

**Goal:** Transform ProfileView into a full account hub.

### 6.1 Profile Navigation
- [ ] Sectioned navigation: You / Achievements / AI Memory / Settings / Account

### 6.2 Achievements Section
- [ ] Expanded badge system (streak, task count, milestone, domain, speed badges)
- [ ] Visual achievement grid with locked/unlocked states
- [ ] Animated unlock celebrations

### 6.3 AI Memory View
- [ ] List all AI memory entries grouped by category
- [ ] View/edit/delete capability
- [ ] "What does AI know about me?" explanation

### 6.4 Settings Expansion
- [ ] Notification preferences (briefing time, reminders, achievements)
- [ ] AI preferences (personality, model, proactivity level)
- [ ] Calendar integration toggle
- [ ] Data & privacy (export, download memory, clear history)

---

## Phase 7: Authentication, Database & Subscription

**Goal:** Production-ready backend with accounts and payments. Only when product is polished.

### 7.1 Firebase Setup
- [ ] Add firebase-ios-sdk SPM package
- [ ] Create Firebase project (Auth + Firestore + Analytics + Crashlytics)
- [ ] Initialize Firebase in MomentumApp.swift

### 7.2 Authentication
- [ ] Sign in with Apple + Email/password
- [ ] Password reset, account deletion
- [ ] Guest mode with prompt to create account

### 7.3 Auth UI
- [ ] SignInView, SignUpView, ForgotPasswordView

### 7.4 Firestore Migration
- [ ] Define Firestore schema
- [ ] Local-first with background sync
- [ ] Data migration on first login

### 7.5 Subscription System
- [ ] Add RevenueCat SPM package
- [ ] "Momentum Pro" — $12.99/month or $99.99/year with 14-day trial
- [ ] PaywallView with feature comparison
- [ ] Subscription management in Profile

---

## Phase 8: App Store Preparation

**Goal:** Everything needed to submit and launch.

### 8.1 App Store Assets
- [ ] App icon refresh
- [ ] 6 screenshots (6.7" + 6.1")
- [ ] 30-second app preview video
- [ ] App Store description, keywords, subtitle
- [ ] Category: Productivity (primary), Lifestyle (secondary)

### 8.2 Legal & Privacy
- [ ] Privacy policy + Terms of service (hosted URLs)
- [ ] App Privacy nutrition labels
- [ ] GDPR compliance (data export + account deletion)
- [ ] Declare AI usage in metadata

### 8.3 Technical Requirements
- [ ] Launch screen
- [ ] Support URL and email
- [ ] Minimum iOS 17
- [ ] All device sizes handled
- [ ] Accessibility: VoiceOver labels
- [ ] Error handling: user-facing alerts
- [ ] Crash reporting via Crashlytics

### 8.4 Testing
- [ ] Unit tests for all services
- [ ] UI tests for critical flows
- [ ] TestFlight beta distribution
- [ ] Sandbox subscription testing

---

## Service Integration Map

| Service | Purpose | Provider | Phase |
|---------|---------|----------|-------|
| Groq API | Fast AI completions | Groq | Existing |
| Claude API | Complex reasoning, tool use | Anthropic | Phase 3 |
| EventKit | Calendar integration | Apple | Phase 4 |
| UserNotifications | Push/local notifications | Apple | Phase 5 |
| WidgetKit | Home screen widgets | Apple | Phase 5 |
| BGTaskScheduler | Background processing | Apple | Phase 2 |
| Firebase Auth | User accounts | Google | Phase 7 |
| Firestore | Cloud database | Google | Phase 7 |
| Firebase Analytics | Usage tracking | Google | Phase 7 |
| Crashlytics | Crash reporting | Google | Phase 7 |
| RevenueCat | Subscription management | RevenueCat | Phase 7 |

---

## Verification Checklist (After Each Phase)

1. Build and run on iOS Simulator — no crashes, no warnings
2. Walk through core flow: launch -> dashboard -> complete task -> profile -> AI chat
3. Test data persistence: close/reopen app
4. Test on physical device for haptics, animations, performance
5. After Phase 5: verify widget updates and notifications
6. After Phase 7: test auth + subscription flows
7. After Phase 8: full TestFlight beta test

---

## Implementation Order

**Phase 1** -> 2 -> 3 -> 4 -> 5 -> 6 -> **7** (only when product is polished) -> **8** (final push)

Each phase produces a shippable improvement. The app remains functional after every phase.
