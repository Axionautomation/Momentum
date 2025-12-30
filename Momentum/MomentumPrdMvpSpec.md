# Momentum - Product Requirements Document & MVP Specification
*AI-Powered Goal Achievement App*

**Version:** 1.0 MVP  
**Target Platform:** iOS (SwiftUI)  
**Development Timeline:** 2-3 weeks  
**Last Updated:** December 28, 2025

---

## Executive Summary

**Momentum** transforms ambitious visions into daily wins through AI-powered goal decomposition, combining Dan Martell's structured framework (north star vision → 12 power goals → daily actions) with James Clear's 1% improvement philosophy. The app's core insight: people fail at goals not from lack of desire, but from unclear next steps. Momentum makes the next step crystal clear every single day.

**Key Differentiators:**
- AI generates personalized action plans from user visions in under 60 seconds
- Windy road visualization shows compound progress toward goals
- Three-task daily system balances challenge and achievability
- Identity-based goal discovery for abstract aspirations
- Serious tool with friendly, energetic coaching tone

---

## Brand Identity

### Name & Logo
- **Name:** Momentum
- **Logo:** Shooting star - symbolizes forward motion, aspiration, and velocity
- **Icon Design:** Clean geometric shooting star on gradient background (deep blue to violet)
- **Brand Feel:** Serious but friendly, energetic yet disciplined, aspirational and action-oriented

### Color System
```
Primary: Deep Blue (#1E3A8A) - Trust, focus, ambition
Secondary: Violet (#7C3AED) - Transformation, aspiration
Accent: Coral Orange (#FF6B4A) - Energy, celebration, achievement
Success: Gradient Green (#10B981 → #34D399) - Progress, growth
Background: 
  - Light Mode: Off-white (#F9FAFB)
  - Dark Mode: Deep Navy (#0F172A) - Default
Text:
  - Primary: White (#FFFFFF) in dark mode
  - Secondary: Light Gray (#94A3B8)
```

### Typography
- **Headings:** SF Pro Display (Bold) - iOS native, clean, authoritative
- **Body:** SF Pro Text (Regular/Medium) - Optimized for readability
- **Numbers/Stats:** SF Pro Rounded (Medium) - Friendly, energetic for progress metrics

### Voice & Tone
**AI Personality (Default - Customizable in Premium):**
- **Voice:** Friendly coach who believes in you
- **Tone:** Energetic, encouraging, action-oriented
- **Style:** Direct but warm, specific not vague
- **Examples:**
  - Task completion: "Nice work! 1 step closer 🚀"
  - Setback: "Hey, setbacks are part of the journey. The next step is getting back up."
  - Planning: "Let's break these down into steps you can crush."
  - Celebration: "All 3 done! You're building unstoppable momentum 🎉"

---

## User Personas

### Primary: The Ambitious Achiever
**Profile:** 22-35 years old, has big dreams, struggles with execution
- **Pain Points:** 
  - Knows what they want but overwhelmed by how to get there
  - Starts strong, loses momentum after 2-3 weeks
  - Other apps feel too rigid or too vague
- **Motivation:** Wants to become someone greater, needs structure and accountability
- **Success Metric:** Completing first Power Goal milestone within 30 days

### Secondary: The Entrepreneurial Student
**Profile:** 18-25, building side projects while in school, limited time
- **Pain Points:**
  - Juggling classes, projects, personal goals
  - Needs efficient use of limited free time
  - Wants to build discipline and track systems
- **Motivation:** Prove to themselves they can finish what they start
- **Success Metric:** Maintaining 30-day streak on core habit

---

## Core Methodology

### Dan Martell Framework Integration
1. **North Star Vision** - One SMART annual goal
2. **12 Power Goals** - Monthly projects aligned with vision
3. **Weekly Milestones** - Concrete outcomes per week
4. **Daily MINs** - Most Important Next Steps (3 tasks/day)
5. **300% Rule** - 100% clarity + 100% belief + 100% commitment

### James Clear Psychology Layer
1. **1% Daily Improvement** - Small wins compound over time
2. **Systems Over Goals** - Focus on consistent daily actions
3. **Identity-Based Goals** - Become the type of person who achieves
4. **Habit Stacking** - One consistent task anchors the day
5. **Environment Design** - Visual reminders (vision always visible)

### The Momentum Method (Hybrid)
```
VISION (Annual SMART Goal)
  ↓
12 POWER GOALS (Monthly projects)
  ↓
WEEKLY MILESTONES (5-7 per Power Goal)
  ↓
DAILY TASKS (3 per day: 1 consistent, 1 medium, 1 challenging)
  ↓
MICROSTEPS (Optional AI-generated sub-tasks)
```

**Task Difficulty Balance:**
- **Task 1:** Consistent anchor (doesn't change much day-to-day) - EASY
  - Example: "Write for 15 minutes" or "Review business plan notes"
- **Task 2:** Meaningful progress - MEDIUM
  - Example: "Draft email template for cold outreach"
- **Task 3:** Stretching challenge (still achievable) - HARDER
  - Example: "Call 3 potential clients" or "Complete market research analysis"

---

## Information Architecture

### App Structure
```
┌─────────────────────────────────────┐
│          MOMENTUM APP               │
├─────────────────────────────────────┤
│                                     │
│  TAB BAR NAVIGATION                 │
│  ┌─────┬─────┬─────┬─────┬─────┐  │
│  │TODAY│ROAD │GOALS│STATS│ ME  │  │
│  └─────┴─────┴─────┴─────┴─────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Screen Hierarchy

**1. Today View (Default Home)**
- Vision (frosted glass background)
- 3 Daily Tasks (focal point)
- Quick Stats (streak, tasks completed this week)
- CTA: "View Full Journey" → Road View

**2. Road View (Progress Visualization)**
- Windy road (top to bottom)
- User pin showing current position
- 12 Power Goal POIs (points of interest)
- Goal at top (bright, majestic)
- Speedometer streak indicator
- Progress percentage

**3. Goals View (Plan Explorer)**
- Current Power Goal (highlighted)
- 12 Power Goals list with status
- Tap to expand: Weekly milestones + tasks
- Daily roadmap calendar view

**4. Stats View (Analytics)**
- Completion rate over time
- Best performing days/times
- Total tasks completed
- Longest streak
- Insights: "You crush Tuesdays!" (Premium)

**5. Me View (Settings & Profile)**
- AI Personality customization (Premium)
- Goal management (add new, archive old)
- Premium upgrade CTA
- Account settings
- Help & Support

---

## Detailed Screen Specifications

### ONBOARDING FLOW

#### Screen 1: Welcome
**Layout:**
```
┌───────────────────────────────────┐
│                                   │
│         [Shooting Star Logo]      │
│                                   │
│        Welcome to Momentum        │
│                                   │
│   Turn your biggest vision into   │
│     tomorrow's first task         │
│                                   │
│                                   │
│    [Swipe or Tap to Continue]    │
│                                   │
└───────────────────────────────────┘
```

**Copy:**
- Headline: "Welcome to Momentum"
- Subhead: "Turn your biggest vision into tomorrow's first task"
- Button: Swipeable cards or "Continue" button

**Animation:** Shooting star trails across screen on entry

---

#### Screen 2: How It Works (Optional Skip)
**Layout:** 3 swipeable benefit cards
1. **"Start with your vision"**
   - Icon: Mountain peak with flag
   - Text: "Dream big. We'll handle the breakdown."
   
2. **"Get your daily tasks"**
   - Icon: Three checkboxes
   - Text: "Three doable tasks every day. No overwhelm."
   
3. **"Watch progress compound"**
   - Icon: Rising arrow with sparkles
   - Text: "Small wins add up. You'll see exactly how far you've come."

**Button:** "Got it, let's start" or "Skip" in corner

---

#### Screen 3: Vision Input (CRITICAL - 60 SEC START)
**Layout:**
```
┌───────────────────────────────────┐
│  [← Back]              [Skip]     │
│                                   │
│  Tell us about your vision        │
│                                   │
│  What's the big goal you want     │
│  to achieve this year?            │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ Type your vision here...    │ │
│  │                             │ │
│  │                             │ │
│  └─────────────────────────────┘ │
│                                   │
│  Examples:                        │
│  • Start a consulting agency      │
│  • Become an entrepreneur         │
│  • Launch my first app            │
│                                   │
│         [Continue →]              │
│                                   │
└───────────────────────────────────┘
```

**Behavior:**
- Text input auto-focuses on screen load
- Character limit: 200 characters
- Real-time character counter
- "Continue" button disabled until >10 characters entered
- Keyboard has "Done" button (not "Next")

**AI Processing Trigger:**
- User taps "Continue"
- Loading state: "Analyzing your vision..." (1-2 seconds)
- Transition to Questionnaire Screen

---

#### Screen 4: AI Questionnaire (3-5 Questions)
**Layout:**
```
┌───────────────────────────────────┐
│  Question 2 of 4                  │
│  [████████░░] 50%                 │
│                                   │
│  [AI Avatar Icon]                 │
│                                   │
│  "What's your current experience  │
│   level with [domain from         │
│   vision]?"                       │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ○ Complete beginner         │ │
│  │ ○ Some experience           │ │
│  │ ○ Intermediate              │ │
│  │ ○ Advanced                  │ │
│  └─────────────────────────────┘ │
│                                   │
│  [Or type your answer...]         │
│                                   │
│         [Next Question →]         │
│                                   │
└───────────────────────────────────┘
```

**Question Types:**

**For Goal-Based Visions** (e.g., "Start a consulting agency"):
1. "What's your current experience level with [domain]?"
2. "How much time can you dedicate weekly?" (5-10 / 10-20 / 20+ hours)
3. "What's your target timeline?" (3 months / 6 months / 1 year)
4. "What's your biggest concern?" (Finding clients / Building skills / Managing time)

**For Identity-Based Visions** (e.g., "Become an entrepreneur"):
1. "What are your passions or interests?"
2. "What does being [identity] mean to you specifically?"
3. "Is there a concrete goal this identity leads to?" (If yes, capture it)
4. "What's holding you back from starting?"

**AI Behavior:**
- Questions adapt based on previous answers
- Mix of multiple choice (faster) and text input (deeper)
- Skip option available for each question
- Progress bar shows completion
- Total time: 45-60 seconds

---

#### Screen 5: AI Generation (Loading State)
**Layout:**
```
┌───────────────────────────────────┐
│                                   │
│                                   │
│      [Animated Shooting Star]     │
│                                   │
│    Creating your momentum plan    │
│                                   │
│  [Animated progress indicator]    │
│                                   │
│  ✓ Analyzing your vision          │
│  ⟳ Breaking into Power Goals      │
│  ○ Generating your first tasks    │
│                                   │
│                                   │
└───────────────────────────────────┘
```

**Behavior:**
- Full-screen loading state
- Animated shooting star with particle trail
- Step-by-step progress (even if AI finishes faster, show steps for 3-4 seconds minimum)
- Background: Grok API call generating full plan

**Technical:**
```
API Call to Grok OSS 120B:
POST /v1/chat/completions
{
  "model": "grok-beta",
  "messages": [
    {
      "role": "system",
      "content": "You are Momentum's AI coach. Generate a structured goal plan using Dan Martell's framework. Be encouraging and specific. Output strict JSON format."
    },
    {
      "role": "user",
      "content": "Vision: {user_vision}\nQuestionnaire: {answers}\n\nGenerate:\n1. 12 Power Goals (monthly projects)\n2. For Power Goal #1: 5 weekly milestones\n3. For Week 1: 21 daily tasks (3 per day, varying difficulty)\n4. Identify one consistent anchor task\n\nJSON Schema:\n{\n  \"vision_refined\": \"SMART version of user vision\",\n  \"power_goals\": [\n    {\"month\": 1, \"goal\": \"...\", \"description\": \"...\"}\n  ],\n  \"current_power_goal\": {\n    \"goal\": \"...\",\n    \"weekly_milestones\": [\n      {\"week\": 1, \"milestone\": \"...\", \"daily_tasks\": [\n        {\"day\": 1, \"tasks\": [\n          {\"title\": \"...\", \"difficulty\": \"easy|medium|hard\", \"estimated_minutes\": 15-45, \"description\": \"...\"}\n        ]}\n      ]}\n    ]\n  },\n  \"anchor_task\": \"The consistent task that anchors each day\"\n}"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000
}
```

---

#### Screen 6: Your First Tasks (60-Second Goal)
**Layout:**
```
┌───────────────────────────────────┐
│  [✨ Celebration Animation]       │
│                                   │
│   Your plan is ready!             │
│                                   │
│   Vision: [Refined SMART goal]    │
│                                   │
│  ─────────────────────────────    │
│                                   │
│  Here are your first 3 tasks      │
│  for today:                       │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☐ [Task 1 - Easy]           │ │
│  │   🕐 15 min                  │ │
│  └─────────────────────────────┘ │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☐ [Task 2 - Medium]         │ │
│  │   🕐 30 min                  │ │
│  └─────────────────────────────┘ │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☐ [Task 3 - Harder]         │ │
│  │   🕐 45 min                  │ │
│  └─────────────────────────────┘ │
│                                   │
│  [View Full Plan] [Start Today →]│
│                                   │
└───────────────────────────────────┘
```

**Copy:**
- Headline: "Your plan is ready!"
- Vision: Display refined SMART version
- Subhead: "Here are your first 3 tasks for today:"
- Tasks: Show title + estimated time
- Buttons: "View Full Plan" (secondary) | "Start Today" (primary)

**Behavior:**
- Brief celebration animation (sparkles, shooting star)
- Tasks displayed one-by-one with slight delay (200ms between)
- "Start Today" transitions to main Today View
- "View Full Plan" goes to Goals View with expanded current Power Goal

**Achievement Unlocked:** ✓ Onboarding complete within 60 seconds

---

### MAIN APP: TODAY VIEW (Default Home)

**Layout:**
```
┌───────────────────────────────────┐
│  [Profile Icon]     [Streak: 🔥5] │
│                                   │
│  ╔═══════════════════════════╗   │
│  ║ [Vision Text - Frosted]   ║   │
│  ║ "Launch my consulting     ║   │
│  ║  agency by June 2026"     ║   │
│  ╚═══════════════════════════╝   │
│                                   │
│  Today's Momentum                 │
│  Monday, Dec 29                   │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☑ Research 3 competitors   │ │
│  │   [Checkmark animation]     │ │
│  │   Done at 9:47 AM           │ │
│  └─────────────────────────────┘ │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☐ Draft service packages   │ │
│  │   🕐 30 min  💪 Medium      │ │
│  │   [Tap to expand details]   │ │
│  └─────────────────────────────┘ │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ☐ Call 3 potential clients │ │
│  │   🕐 45 min  🚀 Challenge   │ │
│  │   [Tap to expand details]   │ │
│  └─────────────────────────────┘ │
│                                   │
│  ─────────────────────────────    │
│  This Week: 12/21 tasks ████░░    │
│  [View Your Journey →]            │
│                                   │
└───────────────────────────────────┘
│  TODAY  ROAD  GOALS  STATS  ME   │
└───────────────────────────────────┘
```

**Components:**

**1. Header**
- Left: Profile icon (tappable → Me View)
- Right: Streak counter with flame emoji + number
  - Tapping opens streak details modal

**2. Vision Card (Frosted Glass)**
- Background: Subtle gradient with 20% opacity
- Text: White, semi-bold, 18pt
- Blur effect: iOS frosted glass (UIVisualEffectView)
- Placement: Always visible behind tasks, top 25% of screen

**3. Date Header**
- "Today's Momentum" (bold, 24pt)
- Current date (regular, 16pt, gray)

**4. Task Cards (The Focal Point)**
Each task card shows:
- Checkbox (custom design, not system)
- Task title (bold, 17pt)
- Metadata row:
  - Clock icon + time estimate
  - Difficulty emoji (Easy: ⭐ | Medium: 💪 | Hard: 🚀)
- Tap-to-expand: Shows full description + "Mark Complete" button

**Task States:**
- **Incomplete:** White card, empty checkbox, full opacity
- **Completed:** Slightly faded, checkmark fills with green animation
- **All 3 Complete:** Confetti animation triggers

**5. Weekly Progress Bar**
- "This Week: 12/21 tasks"
- Progress bar with gradient fill
- Updates in real-time

**6. CTA Button**
- "View Your Journey" → navigates to Road View
- Secondary style (outline button)

---

### Task Completion Flow

**Interaction:**
1. User taps checkbox on task card
2. Modal slides up from bottom:

```
┌───────────────────────────────────┐
│  ╔═══════════════════════════╗   │
│  ║                           ║   │
│  ║  Draft service packages   ║   │
│  ║                           ║   │
│  ║  Create 3-tier pricing    ║   │
│  ║  structure for potential  ║   │
│  ║  clients. Include basic,  ║   │
│  ║  growth, and premium      ║   │
│  ║  tiers with clear value.  ║   │
│  ║                           ║   │
│  ║  🕐 30 min  💪 Medium     ║   │
│  ║                           ║   │
│  ║  Microsteps:              ║   │
│  ║  • Research competitor    ║   │
│  ║    pricing                ║   │
│  ║  • List your services     ║   │
│  ║  • Define tier benefits   ║   │
│  ║                           ║   │
│  ╚═══════════════════════════╝   │
│                                   │
│      [Mark Complete ✓]            │
│      [Cancel]                     │
│                                   │
└───────────────────────────────────┘
```

3. User taps "Mark Complete"
4. Modal closes with slide-down animation
5. Task card animates:
   - Checkbox fills with green checkmark (300ms)
   - Card text fades slightly (200ms)
   - "Done at [time]" appears below task (fade-in)
   - Brief haptic feedback (success pattern)
6. Toast notification slides from top:
   ```
   ┌─────────────────────┐
   │ Nice work! 🚀       │
   │ 1 step closer       │
   └─────────────────────┘
   ```
7. Road View pin moves slightly up
8. If all 3 tasks completed:
   - Confetti animation (3 seconds)
   - Full-screen celebration modal:
   ```
   ┌───────────────────────────────────┐
   │                                   │
   │        🎉 All 3 Done! 🎉         │
   │                                   │
   │  You're building unstoppable      │
   │         momentum                  │
   │                                   │
   │  [View Progress] [Keep Going →]  │
   │                                   │
   └───────────────────────────────────┘
   ```

---

### ROAD VIEW (Progress Visualization)

**Layout:**
```
┌───────────────────────────────────┐
│  [← Back]         Road View       │
│                                   │
│     🌟 VISION: Launch Agency      │
│     [Bright, majestic styling]    │
│                                   │
│  ╔═══════════════════════════╗   │
│  ║         🏆 Goal           ║   │
│  ╚═══════════════════════════╝   │
│          │                        │
│          │  ┌──────────┐          │
│          │  │ Month 12 │          │
│          │  └──────────┘          │
│         ╱                         │
│        ╱                          │
│       │   ┌──────────┐            │
│       │   │ Month 11 │            │
│       │   └──────────┘            │
│        ╲                          │
│         ╲                         │
│          │  ┌──────────┐          │
│          │  │ Month 10 │          │
│          │  └──────────┘          │
│         ╱                         │
│        ╱   ...                    │
│       │                           │
│       │   ┌──────────┐            │
│       │   │ Month 2  │            │
│       │   └──────────┘            │
│        ╲                          │
│         ╲   📍 YOU'RE HERE        │
│          │  ┌──────────┐          │
│          │  │ Month 1  │  ← Active│
│          │  └──────────┘          │
│                                   │
│  ╔═══════════════════════════╗   │
│  ║  Streak: 🔥 5 days        ║   │
│  ║  [Speedometer graphic]    ║   │
│  ║  47% to Power Goal 1      ║   │
│  ╚═══════════════════════════╝   │
│                                   │
└───────────────────────────────────┘
│  TODAY  ROAD  GOALS  STATS  ME   │
└───────────────────────────────────┘
```

**Design Specifications:**

**1. Goal Display (Top)**
- Large, prominent text
- Gradient background (gold to yellow)
- Subtle glow/shadow effect
- Icon: Star or trophy
- "Majestic" feel through:
  - Larger font size (22pt)
  - Premium gradient
  - Subtle animation (gentle pulsing glow)

**2. Windy Road**
- Orientation: Top (goal) to bottom (start)
- Visual style: Hand-drawn path feel, slightly organic
- Color: Light gray path with darker edges
- Width: 60% of screen width
- Curves: Smooth S-curves, alternating left/right

**3. Power Goal POIs (Points of Interest)**
- 12 circular nodes along the path
- Each shows: "Month [X]" + Power Goal title (truncated)
- States:
  - **Future:** Gray, unfilled circle
  - **Current:** Highlighted with accent color, thicker border
  - **Completed:** Green checkmark, filled
- Tappable: Opens detail modal with weekly milestones

**4. User Pin**
- Icon: Shooting star or location pin with star
- Position: Calculated based on % completion of current Power Goal
- Animation: Smooth upward movement when tasks completed (spring animation)
- Trail: Subtle dotted line showing path traveled (fades at bottom)

**5. Speedometer Streak Indicator**
- Gauge-style display (180° semicircle)
- Needle points to current streak count
- Zones:
  - 0-7 days: Yellow zone
  - 8-20 days: Green zone  
  - 21+ days: Blue "elite" zone
- Number displayed in center: "[X] days"
- Flame emoji next to gauge

**6. Progress Card (Bottom)**
- Shows current stats:
  - Streak count
  - % progress to next Power Goal
  - Days since starting journey
  - Total tasks completed
- Frosted glass card style

**Interaction:**
- Vertical scroll if road extends beyond screen
- Pull-to-refresh updates progress
- Tap POI → Modal with Power Goal details
- Tap user pin → Scrolls to current position (if off-screen)

---

### GOALS VIEW (Plan Explorer)

**Layout:**
```
┌───────────────────────────────────┐
│  [← Back]         Your Goals      │
│                                   │
│  Current Focus                    │
│  ┌─────────────────────────────┐ │
│  │ 🎯 Month 1: Build Foundation│ │
│  │                             │ │
│  │ Define service packages &   │ │
│  │ validate market fit         │ │
│  │                             │ │
│  │ 47% complete ████████░░░░   │ │
│  │                             │ │
│  │ [View Breakdown ▼]          │ │
│  └─────────────────────────────┘ │
│                                   │
│  All Power Goals (12)             │
│  ┌─────────────────────────────┐ │
│  │ ✓ Month 1: Build Foundation │ │
│  │   47% ████████░░░░          │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │ ○ Month 2: First Clients    │ │
│  │   Locked until Month 1 done │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │ ○ Month 3: Scale Systems    │ │
│  │   Starts Feb 1              │ │
│  └─────────────────────────────┘ │
│  ...                              │
│                                   │
│  [+ Add New Goal]                 │
│  (Premium: Unlimited / Free: 2)   │
│                                   │
└───────────────────────────────────┘
│  TODAY  ROAD  GOALS  STATS  ME   │
└───────────────────────────────────┘
```

**Expanded View (Tap "View Breakdown"):**
```
┌───────────────────────────────────┐
│  Month 1: Build Foundation        │
│  [Collapse ▲]                     │
│                                   │
│  Weekly Milestones                │
│                                   │
│  Week 1: Market Research          │
│  ┌─────────────────────────────┐ │
│  │ ✓ Mon: Research competitors │ │
│  │ ✓ Mon: Draft packages       │ │
│  │ ✓ Mon: Call 3 clients       │ │
│  │ ─                           │ │
│  │ ○ Tue: [Task 1]             │ │
│  │ ○ Tue: [Task 2]             │ │
│  │ ○ Tue: [Task 3]             │ │
│  │ ...                         │ │
│  └─────────────────────────────┘ │
│                                   │
│  Week 2: Define Services          │
│  ┌─────────────────────────────┐ │
│  │ Unlocks after Week 1        │ │
│  └─────────────────────────────┘ │
│                                   │
│  ...Week 3-5                      │
│                                   │
│  Daily Roadmap                    │
│  [Calendar Icon] View in Calendar │
│  (Premium Feature)                │
│                                   │
└───────────────────────────────────┘
```

**Features:**

**1. Current Power Goal Card**
- Highlighted with accent color border
- Progress bar and percentage
- Expandable to show full weekly breakdown
- Edit button (Premium): Allows AI re-planning

**2. All Power Goals List**
- Scrollable vertical list
- States:
  - **Active:** Border, progress bar visible
  - **Completed:** Green checkmark, collapsed
  - **Locked:** Grayed out, "Unlocks after [previous]"
- Tap to expand and see details

**3. Add New Goal Button**
- Always visible at bottom
- Shows limit for free users: "(1 of 2 goals used)"
- Premium users: Unlimited
- Tapping starts new goal creation flow (same as onboarding)

**4. Calendar Integration (Premium)**
- Button: "View in Calendar" 
- Opens native iOS calendar with synced tasks
- Locked for free users with upgrade CTA

---

### STATS VIEW (Analytics & Insights)

**Layout:**
```
┌───────────────────────────────────┐
│  [← Back]         Your Stats      │
│                                   │
│  Overview                         │
│  ┌─────────────────────────────┐ │
│  │ Total Tasks: 47             │ │
│  │ Completion Rate: 89%        │ │
│  │ Current Streak: 🔥 5 days   │ │
│  │ Longest Streak: 🏆 12 days  │ │
│  └─────────────────────────────┘ │
│                                   │
│  This Week                        │
│  [Bar chart showing daily tasks]  │
│  Mon Tue Wed Thu Fri Sat Sun      │
│   3   3   2   3   3   0   1       │
│                                   │
│  Your Patterns (Premium)          │
│  ┌─────────────────────────────┐ │
│  │ 🔒 Unlock Premium Insights  │ │
│  │                             │ │
│  │ • Best performing days      │ │
│  │ • Optimal task times        │ │
│  │ • Completion predictions    │ │
│  │                             │ │
│  │ [Upgrade to Premium →]      │ │
│  └─────────────────────────────┘ │
│                                   │
│  Monthly Progress                 │
│  [Line graph showing tasks/week]  │
│  Dec: 12 → 15 → 18 → 21          │
│                                   │
│  Achievements                     │
│  ┌────┬────┬────┬────┬────┐     │
│  │ 🔥 │ 💯 │ 🚀 │ 🏆 │ ⭐ │     │
│  │ 7  │First│Fast│30  │All │     │
│  │Day │100 │Start│Day│Goals│     │
│  └────┴────┴────┴────┴────┘     │
│                                   │
└───────────────────────────────────┘
│  TODAY  ROAD  GOALS  STATS  ME   │
└───────────────────────────────────┘
```

**Components:**

**1. Overview Card**
- Key metrics at a glance
- Total tasks completed (all-time)
- Completion rate (% of assigned tasks done)
- Current streak
- Longest streak (personal best)

**2. Weekly Chart**
- Simple bar chart
- 7 bars (Mon-Sun)
- Height = tasks completed that day
- Current day highlighted
- Tappable: Shows task list for that day

**3. Premium Insights (Locked for Free)**
- Teaser of what's available
- AI-generated insights like:
  - "You crush Tuesdays - 95% completion"
  - "Morning tasks have 80% completion vs 60% evening"
  - "You're on track for 30-day streak if you maintain pace"
- Upgrade CTA button

**4. Monthly Progress**
- Line graph showing trend
- X-axis: Weeks
- Y-axis: Tasks completed
- Shows growth over time

**5. Achievements/Badges**
- Grid of unlocked badges
- Examples:
  - 🔥 7-Day Streak
  - 💯 First 100 Tasks
  - 🚀 Fast Start (3 tasks in first 3 days)
  - 🏆 30-Day Streak
  - ⭐ Completed All Daily Tasks for a Week
- Tapping shows badge details and unlock date

---

### ME VIEW (Settings & Profile)

**Layout:**
```
┌───────────────────────────────────┐
│  [← Back]         Profile         │
│                                   │
│  ┌─────────────────────────────┐ │
│  │    [Profile Avatar]         │ │
│  │    Henry Smith              │ │
│  │    henry@email.com          │ │
│  │    Member since Dec 2025    │ │
│  └─────────────────────────────┘ │
│                                   │
│  ⭐ Premium Features              │
│  ┌─────────────────────────────┐ │
│  │ 🔒 You're on the Free plan  │ │
│  │                             │ │
│  │ Upgrade to unlock:          │ │
│  │ • Unlimited goals           │ │
│  │ • Calendar sync             │ │
│  │ • AI personality custom     │ │
│  │ • Advanced analytics        │ │
│  │ • Unlimited AI re-planning  │ │
│  │                             │ │
│  │ $4.99/mo or $39.99/year     │ │
│  │                             │ │
│  │ [Upgrade to Premium →]      │ │
│  └─────────────────────────────┘ │
│                                   │
│  Settings                         │
│  ┌─────────────────────────────┐ │
│  │ AI Personality (Premium)    │ │
│  │ Notifications               │ │
│  │ Theme (Light/Dark/Auto)     │ │
│  │ Calendar Settings (Premium) │ │
│  └─────────────────────────────┘ │
│                                   │
│  Manage Goals                     │
│  ┌─────────────────────────────┐ │
│  │ Active Goals (1/2)          │ │
│  │ Completed Goals             │ │
│  │ Archived Goals              │ │
│  └─────────────────────────────┘ │
│                                   │
│  Support                          │
│  ┌─────────────────────────────┐ │
│  │ Help & Tutorials            │ │
│  │ Contact Support             │ │
│  │ Privacy Policy              │ │
│  │ Terms of Service            │ │
│  └─────────────────────────────┘ │
│                                   │
│  [Log Out]                        │
│                                   │
└───────────────────────────────────┘
│  TODAY  ROAD  GOALS  STATS  ME   │
└───────────────────────────────────┘
```

**Premium Upgrade Modal (Tap "Upgrade"):**
```
┌───────────────────────────────────┐
│  [× Close]                        │
│                                   │
│      Unlock Your Full Potential   │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ ✓ Unlimited goals           │ │
│  │ ✓ Calendar sync             │ │
│  │ ✓ Custom AI personality     │ │
│  │ ✓ Advanced insights         │ │
│  │ ✓ Unlimited AI re-planning  │ │
│  │ ✓ Priority support          │ │
│  └─────────────────────────────┘ │
│                                   │
│  Choose Your Plan                 │
│                                   │
│  ○ Monthly: $4.99/month           │
│  ● Annual: $39.99/year            │
│     (Save 33% - 2 months free!)   │
│                                   │
│  7-day free trial included        │
│  Cancel anytime                   │
│                                   │
│  [Start Free Trial →]             │
│                                   │
│  [Restore Purchases]              │
│                                   │
└───────────────────────────────────┘
```

**AI Personality Settings (Premium):**
```
┌───────────────────────────────────┐
│  [← Back] AI Personality          │
│                                   │
│  Choose your coach's style:       │
│                                   │
│  ○ Energetic & Friendly (Default) │
│     "Let's crush these tasks!"    │
│                                   │
│  ○ Calm & Focused                 │
│     "Take it one step at a time"  │
│                                   │
│  ○ Direct & No-Nonsense           │
│     "Here's what needs doing"     │
│                                   │
│  ○ Motivational Coach             │
│     "You've got this, champion!"  │
│                                   │
│  Preview Message:                 │
│  ┌─────────────────────────────┐ │
│  │ "Nice work! 1 step closer🚀"│ │
│  └─────────────────────────────┘ │
│                                   │
│  [Save Changes]                   │
│                                   │
└───────────────────────────────────┘
```

---

## Technical Specifications

### Technology Stack

**iOS App:**
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Minimum iOS:** 16.0
- **Dependencies:**
  - Supabase Swift SDK (auth, database, realtime)
  - EventKit (calendar integration)
  - Charts framework (for stats visualization)

**Backend:**
- **Platform:** Supabase
  - PostgreSQL database
  - Edge Functions (Node.js/TypeScript)
  - Row Level Security (RLS) for data protection
  - Realtime subscriptions
- **Authentication:** Supabase Auth (email/password + Apple Sign-In)
- **Storage:** Supabase Storage (for profile images, future features)

**AI Integration:**
- **Model:** Grok OSS 120B via xAI API
- **Endpoint:** Edge Functions proxy to protect API keys
- **Caching:** Prompt caching for common goal types
- **Fallback:** GPT-4o-mini if Grok unavailable

**Calendar:**
- **Framework:** EventKit (iOS native)
- **Sync Direction:** One-way (app → calendar)
- **Update Frequency:** Weekly batch sync (Sundays)

---

### Database Schema

```sql
-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  subscription_tier TEXT DEFAULT 'free', -- 'free' | 'premium'
  subscription_expires_at TIMESTAMP,
  ai_personality TEXT DEFAULT 'energetic', -- 'energetic' | 'calm' | 'direct' | 'motivational'
  streak_count INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_task_completed_at TIMESTAMP
);

-- Goals Table
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  vision_text TEXT NOT NULL,
  vision_refined TEXT, -- AI-generated SMART version
  is_identity_based BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'active', -- 'active' | 'completed' | 'archived'
  created_at TIMESTAMP DEFAULT NOW(),
  target_completion_date DATE,
  current_power_goal_index INTEGER DEFAULT 0, -- 0-11 for 12 Power Goals
  completion_percentage DECIMAL DEFAULT 0
);

-- Power Goals Table (12 per Goal)
CREATE TABLE power_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID REFERENCES goals(id) ON DELETE CASCADE,
  month_number INTEGER NOT NULL CHECK (month_number BETWEEN 1 AND 12),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'locked', -- 'locked' | 'active' | 'completed'
  start_date DATE,
  completion_percentage DECIMAL DEFAULT 0
);

-- Weekly Milestones Table (5 per Power Goal)
CREATE TABLE weekly_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  power_goal_id UUID REFERENCES power_goals(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 5),
  milestone_text TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending' | 'in_progress' | 'completed'
  start_date DATE
);

-- Tasks Table (3 per day)
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  weekly_milestone_id UUID REFERENCES weekly_milestones(id) ON DELETE CASCADE,
  goal_id UUID REFERENCES goals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  estimated_minutes INTEGER NOT NULL CHECK (estimated_minutes BETWEEN 10 AND 60),
  is_anchor_task BOOLEAN DEFAULT FALSE, -- The consistent daily task
  scheduled_date DATE NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending' | 'completed' | 'skipped'
  completed_at TIMESTAMP,
  calendar_event_id TEXT -- EventKit identifier
);

-- Microsteps Table (optional sub-tasks)
CREATE TABLE microsteps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  step_text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE
);

-- AI Generation History (for re-planning)
CREATE TABLE ai_generations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  goal_id UUID REFERENCES goals(id),
  prompt_type TEXT NOT NULL, -- 'questionnaire' | 'plan_generation' | 'replan'
  prompt_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  model_used TEXT DEFAULT 'grok-oss-120b',
  tokens_used INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Achievements/Badges
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_type TEXT NOT NULL, -- '7_day_streak' | 'first_100' | 'fast_start' etc.
  unlocked_at TIMESTAMP DEFAULT NOW()
);

-- Analytics Events
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- 'task_completed' | 'goal_created' | 'streak_broken' etc.
  event_data JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Row Level Security Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE power_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE microsteps ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own goals" ON goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON goals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own goals" ON goals FOR DELETE USING (auth.uid() = user_id);

-- (Repeat for other tables with user_id or goal_id joins)
```

---

## MVP Development Timeline

### Week 1: Foundation & Onboarding (Days 1-7)

**Day 1-2: Project Setup & Backend**
- [ ] Create Xcode project (SwiftUI, iOS 16+)
- [ ] Set up Supabase project
- [ ] Configure database schema (all tables)
- [ ] Set up Row Level Security policies
- [ ] Create Edge Function stub for AI generation
- [ ] Configure environment variables

**Day 3-4: Authentication & Onboarding UI**
- [ ] Implement Supabase Auth (email + Apple Sign-In)
- [ ] Build welcome screens (1-2 benefit cards)
- [ ] Create vision input screen
- [ ] Build questionnaire UI (adaptable questions)
- [ ] Add loading/generation screen with animations

**Day 5-7: AI Integration**
- [ ] Complete generate-plan Edge Function
- [ ] Integrate Grok API (or GPT-4o-mini fallback)
- [ ] Test prompt engineering for quality plans
- [ ] Parse and store generated plan in database
- [ ] Build "Your First Tasks" results screen
- [ ] **MILESTONE:** User can create account, input vision, see first 3 tasks in under 60 seconds

---

### Week 2: Core App & Task Management (Days 8-14)

**Day 8-9: Today View**
- [ ] Build tab bar navigation
- [ ] Create Today View UI (vision + 3 tasks)
- [ ] Implement frosted glass vision background
- [ ] Add task cards with expand/collapse
- [ ] Build task completion flow (modal → animation)

**Day 10-11: Progress Tracking**
- [ ] Implement streak calculation logic
- [ ] Build windy road visualization (Road View)
- [ ] Create speedometer streak indicator
- [ ] Add user pin with movement animation
- [ ] Display Power Goal POIs on road
- [ ] Implement task completion → road progression

**Day 12-13: Goals View**
- [ ] Build Power Goals list UI
- [ ] Create expandable weekly milestones view
- [ ] Show daily task roadmap per week
- [ ] Implement goal status (active/completed/locked)
- [ ] Add "Add New Goal" flow (max 2 for free)

**Day 14: Testing & Refinement**
- [ ] End-to-end testing (onboarding → task completion)
- [ ] Fix critical bugs
- [ ] Optimize animations/transitions
- [ ] Test on multiple iOS versions (16.0+)
- [ ] **MILESTONE:** Core loop functional (create goal → complete tasks → see progress)

---

### Week 3: Premium Features & Polish (Days 15-21)

**Day 15-16: Calendar Integration (Premium)**
- [ ] Request EventKit permissions
- [ ] Create "Momentum" calendar
- [ ] Implement task → calendar event sync
- [ ] Build Sunday batch sync logic
- [ ] Test time block calculations
- [ ] Add calendar settings UI

**Day 17-18: Stats & Analytics**
- [ ] Build Stats View with charts
- [ ] Implement completion rate calculations
- [ ] Create achievements/badges system
- [ ] Design premium insights (locked for free)
- [ ] Add badge unlock animations

**Day 19: Monetization**
- [ ] Set up App Store Connect In-App Purchases
- [ ] Implement StoreKit 2 integration
- [ ] Build paywall UI (Premium features)
- [ ] Add subscription checking logic
- [ ] Test purchase/restore flows
- [ ] Implement feature gating (free vs premium)

**Day 20: Me View & Settings**
- [ ] Build profile screen
- [ ] Add AI personality settings (Premium)
- [ ] Create goal management (archive/delete)
- [ ] Add help/support links
- [ ] Implement theme switching (dark/light)
- [ ] Build upgrade prompts throughout app

**Day 21: Final Polish & Prep**
- [ ] Complete app icon (shooting star design)
- [ ] Add App Store screenshots
- [ ] Write App Store listing copy
- [ ] Final QA testing
- [ ] Submit to TestFlight
- [ ] **MILESTONE:** MVP ready for beta testing

---

## Success Metrics & KPIs

### User Acquisition
- **Target:** 100 beta users in first month
- **Metric:** App Store downloads
- **Source:** Organic + Dan Martell community outreach

### Activation
- **Target:** 80% complete onboarding (see first 3 tasks)
- **Metric:** % of signups who complete vision input
- **Why:** 60-second value delivery

### Engagement
- **Target:** 60% daily active users (DAU/MAU)
- **Metric:** Users who complete ≥1 task per day
- **Why:** Daily momentum is core to product

### Retention
- **Target:** 40% D30 retention
- **Metric:** % of users active 30 days after signup
- **Why:** Indicates sustainable habit formation

### Monetization
- **Target:** 10% conversion to Premium within 30 days
- **Metric:** % of users who upgrade
- **Revenue Target:** $500 MRR by end of Month 3

### Product Quality
- **Target:** 4.5+ star App Store rating
- **Metric:** Average rating
- **Why:** Indicates product-market fit

---

## Conclusion

Momentum MVP delivers a complete goal achievement system in 2-3 weeks by focusing on:

1. **60-Second Value Delivery:** Users see their first 3 tasks within a minute
2. **Proven Methodology:** Dan Martell + James Clear frameworks
3. **AI-Powered Breakdown:** Grok OSS 120B generates personalized plans
4. **Visual Progress:** Windy road shows compound momentum
5. **Sustainable Monetization:** Freemium with clear premium value

**Next Steps:**
1. Review and approve this PRD
2. Set up development environment
3. Begin Week 1 implementation
4. Ship to TestFlight by Day 21

Your vision for helping people achieve their goals is clear. Now let's build the momentum to make it real.

---

*Document Version: 1.0*  
*Last Updated: December 28, 2025*  
*Author: Product Specification for Momentum iOS App*
