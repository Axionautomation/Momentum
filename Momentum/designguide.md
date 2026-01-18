# Momentum App — UI Architecture & Visual System Specification

**Version:** 1.2
**Philosophy:** Identity → Goals → Execution → Evidence
**Inspiration:** Whoop, elite Apple apps (principles, not aesthetics)

---

## 1. Core Navigation Model (Whoop-Inspired)

Momentum uses a **4-tab primary navigation** with a **persistent AI assistant** and a **global profile entry point**.

### Bottom Navigation Bar

```
[ Today ] [ Journey ] [ Goals ] [ Progress ]      [ ✨ AI ]
```

* **Only 4 primary views**.
* **AI Assistant** is always visible and treated as core infrastructure.
* **Me / Profile** is *not* a tab — accessed via a top-right icon on most screens.

---

## 2. Global Visual System (Critical)

### 2.1 Material & Depth Rules (Non-Negotiable)

❌ **DO NOT use Apple’s default Liquid Glass / .ultraThinMaterial / base blur styles.**
They appear cheap, muddy, and reduce clarity.

✅ Instead, use a **custom floating surface system** inspired by Liquid Glass *conceptually*, not visually.

---

### 2.2 Custom Floating Surface Spec

**Floating surfaces must:**

* Be opaque or near-opaque
* Use **dark charcoal / near-black** as the base
* Have **subtle elevation**, not blur dominance

**Recommended Base Colors**

* Primary surface: `#0E0F12` (near-black)
* Secondary surface: `#15171C`
* Divider / outline: `#1F2228`

**Elevation Treatment**

* Soft shadow
* Slight inner highlight
* No heavy blur

This preserves:

* Contrast
* Readability
* Premium feel

---

### 2.3 Accent Color Strategy

**Primary Accent**

* Deep purple (Momentum Violet)
* Used **sparingly and intentionally**

**Rule**

> Purple is a signal, not a background.

Use purple for:

* Primary actions
* Progress highlights
* Active states
* AI affordances

Avoid:

* Purple backgrounds everywhere
* Purple cards by default

---

### 2.4 Vibrancy Injection (Very Important)

While the app is dark and restrained, **strategic splashes of vibrant color are required**.

**Where vibrant color is allowed:**

* Completion celebrations
* Streak moments
* Calendar heatmap strong days
* Key progress inflection points

**Examples**

* Green for strong execution days
* Gold for milestones / achievements
* Purple glow for AI moments

**Rule**

> Most of the app is calm. Progress is loud.

---

## 3. Global UI Elements

### 3.1 Floating AI Assistant

* Persistent across all views
* Custom dark surface
* Purple accent ring or glow
* No system blur
* Subtle pulse animation

AI should feel **alive**, not glassy.

---

### 3.2 Profile / Me Entry Point

* Top-right avatar or icon
* Minimal chrome
* Opens Me View (modal or push)

---

## 4. The Four Core Views

---

## 4.1 Today — Execution Layer

**Question:**

> “What do I do today to move forward?”

### Visual Tone

* Calm
* Focused
* High contrast

### Rules

* No browsing
* No stats
* No history

Only:

* Today
* Tasks
* Momentum feedback

---

## 4.2 Journey — Narrative Layer

**Question:**

> “Where am I in the story of my year?”

### Visual Tone

* Spacious
* Motivational
* Directional

### Rules

* No dense data
* No task micromanagement
* Visual clarity over precision

---

## 4.3 Goals — Structure Layer

**Question:**

> “What am I trying to become and complete?”

### Goals Overview

* Grouped by:

  * Identities
  * Projects
  * Habits
* Dark cards
* Subtle outlines
* Purple only for active focus

---

### Goal Detail View

**Visual Tone**

* Reflective
* Analytical
* Calm depth

**Key Visuals**

* Binary calendar (colored days)
* Progress rings
* Task timelines

No celebratory effects here — this is a thinking space.

---

## 4.4 Progress — Evidence Layer

**Question:**

> “Is this actually working?”

### Calendar Heatmap

**Color Logic**

* Neutral days → muted gray
* Weak days → soft color
* Strong days → vibrant, saturated color

The more effort + difficulty completed → the more vibrant the day.

---

### Trends & Breakdown

* Charts on dark surfaces
* Minimal gridlines
* Purple only for emphasis, not defaults

---

## 5. AI Assistant (System-Wide)

### Visual Identity

* Dark surface
* Purple glow
* Occasional sparkle or motion
* Never glassy

AI should feel:

* Intentional
* Intelligent
* Premium

Not playful, not toy-like.

---

## 6. Me View — Identity & Control

### Visual Tone

* Quiet
* Minimal
* Serious

This is where the system is tuned, not used.

---

## 7. Explicit Anti-Patterns (DO NOT SHIP)

❌ Default Apple Liquid Glass
❌ Over-blurred backgrounds
❌ Purple-everywhere theming
❌ Gamification clutter
❌ Multiple dashboards doing the same thing

---

## 8. Final Design Law

> **Dark, calm surfaces.
> Sparse purple signals.
> Vibrant color only when progress is earned.**

Momentum should feel like a **high-performance instrument**, not a toy.
