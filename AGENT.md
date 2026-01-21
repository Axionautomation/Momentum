# Agent Instructions for Momentum

This document provides instructions for AI agents working on the Momentum codebase.

## Project Goal

**Momentum** is an AI-powered goal achievement app that bridges the gap between annual vision and daily action.

The app helps users:
1. Define their annual vision and goals
2. Break goals into 12 Power Goals (monthly milestones)
3. Further break down into Weekly Milestones
4. Execute through 3 Daily Tasks (Easy/Medium/Hard difficulty)
5. Get AI assistance for research, guidance, and motivation

The core philosophy is based on Dan Martell's structured planning framework - making big goals achievable through consistent daily progress.

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
# Standard workflow
git add .
git commit -m "Description of changes"
git push origin main
```

**Important reminders:**
- Never commit `Config.swift` (contains API keys, already in .gitignore)
- Use `Config.swift.example` as the template for configuration
- Verify no secrets are being committed before pushing

## Technical Context

See `CLAUDE.md` for detailed technical documentation including:
- Tech stack (SwiftUI, iOS 26+, Groq API)
- Project structure and key files
- Design system (colors, typography, components)
- AI integration details
- Common development patterns

## Key Principles

1. **Follow existing patterns** - The codebase has established conventions. Follow them.
2. **Use the design system** - Colors, typography, and components are defined in `Theme.swift`
3. **Maintain dark mode** - Always apply `.preferredColorScheme(.dark)`
4. **Use PhosphorSwift for icons** - Import and use `Ph.iconName.variant`
5. **Keep state in AppState** - Use `@EnvironmentObject var appState: AppState`

## Repository

- **GitHub**: https://github.com/Axionautomation/Momentum.git
- **Branch**: main
- **Config**: Copy `Config.swift.example` to `Config.swift` and add your API keys

## Quick Reference

| Task | Action |
|------|--------|
| Icons | `import PhosphorSwift` → `Ph.iconName.regular` |
| Colors | `Color.momentumViolet`, `Color.momentumDarkBackground` |
| State | `@EnvironmentObject var appState: AppState` |
| Background | `Color.momentumDarkBackground` |
| Sheets | Use item-based: `.sheet(item: $selection)` |
