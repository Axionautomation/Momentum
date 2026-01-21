---
name: swiftui-design
description: Create distinctive, beautiful iOS applications with intentional design choices. Use when designing UI components, choosing colors, typography, animations, or creating custom layouts for SwiftUI.
---

# SwiftUI iOS Design Excellence Skill

A comprehensive guide for creating distinctive, beautiful iOS applications that avoid generic "AI slop" aesthetics while leveraging SwiftUI's powerful design capabilities.

## Core Philosophy

SwiftUI apps should feel **native, intentional, and delightful**. Avoid converging toward generic designs by making bold, context-appropriate choices that surprise users while respecting iOS design patterns.

---

## Typography

### Font Selection Strategy

**Avoid overused choices:**
- SF Pro (system default) - use sparingly, only when appropriate
- Generic sans-serifs without character

**Embrace distinctive fonts:**
- **Serif fonts**: New York, Crimson Pro, Literata, Spectral, Fraunces
- **Display fonts**: Righteous, Rubik, Outfit, Cabinet Grotesk, Lexend
- **Monospace**: JetBrains Mono, Fira Code, SF Mono (sparingly)
- **Rounded/Friendly**: Comfortaa, Quicksand, Fredoka
- **Editorial**: Lora, Merriweather, Playfair Display

### Implementation

```swift
// Custom font loading
extension Font {
    static func custom(_ name: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom(name, size: size)
    }

    // Create semantic font scales
    static let displayLarge = Font.custom("Fraunces-Bold", size: 48)
    static let headingLarge = Font.custom("Crimson Pro", size: 32, weight: .semibold)
    static let bodyLarge = Font.custom("Literata-Regular", size: 18)
    static let labelMedium = Font.custom("Outfit-Medium", size: 14)
}

// Info.plist: Add fonts to "Fonts provided by application"
```

### Typography Guidelines

- **Mix weights and styles**: Combine different fonts for hierarchy (e.g., display serif + body sans-serif)
- **Variable fonts**: Use variable font axes when available (.width, .weight)
- **Dynamic Type**: Always support accessibility with `.dynamicTypeSize()` modifiers
- **Tracking & Leading**: Fine-tune spacing with `.tracking()` and `.lineSpacing()`

---

## Color & Theme

### Creating Cohesive Palettes

**Avoid:**
- Purple gradients on white backgrounds
- Evenly distributed color schemes
- Generic Material Design palettes

**Embrace:**
- **Dominant color with sharp accents**: 1-2 primary colors + 1 bold accent
- **IDE-inspired themes**: Dracula, Nord, Tokyo Night, Catppuccin, Gruvbox
- **Cultural aesthetics**: Japanese minimalism, Bauhaus geometry, Memphis design
- **Contextual palettes**: Match the app's purpose and audience

### Implementation

```swift
// Color system using extensions
extension Color {
    // Tokyo Night-inspired palette
    static let tokyoNight = ColorScheme.tokyoNight

    struct ColorScheme {
        static let tokyoNight = TokyoNight()

        struct TokyoNight {
            let background = Color(hex: "#1a1b26")
            let surface = Color(hex: "#24283b")
            let primary = Color(hex: "#7aa2f7")
            let accent = Color(hex: "#bb9af7")
            let success = Color(hex: "#9ece6a")
            let text = Color(hex: "#c0caf5")
            let textMuted = Color(hex: "#565f89")
        }
    }

    // Hex initializer
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = Double((hexNumber & 0xff0000) >> 16) / 255
        let g = Double((hexNumber & 0x00ff00) >> 8) / 255
        let b = Double(hexNumber & 0x0000ff) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// Environment-based theming
@Environment(\.colorScheme) var colorScheme

var backgroundColor: Color {
    colorScheme == .dark ? Color.tokyoNight.background : Color(hex: "#f5f5f0")
}
```

### Gradient Mastery

```swift
// Atmospheric gradients
let meshGradient = MeshGradient(
    width: 3,
    height: 3,
    points: [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.5], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1]
    ],
    colors: [
        .purple, .blue, .cyan,
        .indigo, .purple, .blue,
        .purple, .indigo, .blue
    ]
)

// Animated gradient backgrounds
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [.orange, .pink, .purple],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
```

---

## Motion & Animation

### Animation Principles

- **Meaningful motion**: Every animation should have purpose
- **Orchestrated reveals**: Stagger elements on load for impact
- **Spring physics**: Use `.spring()` for natural, organic motion
- **Gesture-driven**: Tie animations to user interactions

### High-Impact Patterns

```swift
// Staggered reveal on appear
struct StaggeredList: View {
    let items = ["Item 1", "Item 2", "Item 3", "Item 4"]
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .offset(y: appeared ? 0 : 50)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                        value: appeared
                    )
            }
        }
        .onAppear { appeared = true }
    }
}

// Hero transitions
struct HeroTransition: View {
    @Namespace private var animation
    @State private var isExpanded = false

    var body: some View {
        if isExpanded {
            RoundedRectangle(cornerRadius: 20)
                .matchedGeometryEffect(id: "hero", in: animation)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5)) {
                        isExpanded.toggle()
                    }
                }
        } else {
            RoundedRectangle(cornerRadius: 10)
                .matchedGeometryEffect(id: "hero", in: animation)
                .frame(width: 100, height: 100)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5)) {
                        isExpanded.toggle()
                    }
                }
        }
    }
}

// Micro-interactions with haptics
struct HapticButton: View {
    @State private var isPressed = false

    var body: some View {
        Button("Press Me") {
            // Action
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
```

### Advanced Animation Techniques

```swift
// Custom timing curves
extension Animation {
    static let snappy = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.4)
    static let elastic = Animation.interpolatingSpring(stiffness: 300, damping: 20)
}

// Keyframe animations (iOS 17+)
struct KeyframeExample: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 50, height: 50)
            .keyframeAnimator(initialValue: AnimationValues(), trigger: animate) { view, value in
                view
                    .scaleEffect(value.scale)
                    .rotationEffect(value.rotation)
                    .offset(y: value.offsetY)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.3)
                    SpringKeyframe(1.0, duration: 0.2)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(.degrees(0), duration: 0.0)
                    LinearKeyframe(.degrees(360), duration: 0.5)
                }
                KeyframeTrack(\.offsetY) {
                    SpringKeyframe(-100, duration: 0.3)
                    SpringKeyframe(0, duration: 0.2)
                }
            }
            .onAppear { animate = true }
    }

    struct AnimationValues {
        var scale = 1.0
        var rotation = Angle.zero
        var offsetY = 0.0
    }
}
```

---

## Backgrounds & Atmosphere

### Creating Depth

**Avoid:** Flat solid colors

**Embrace:**
- Layered gradients with blur effects
- Geometric patterns and noise
- Contextual visual elements
- Glassmorphism and neumorphism (sparingly)

### Implementation

```swift
// Atmospheric noise background
struct NoiseBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("noise-texture")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.05)
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

// Geometric pattern background
struct GeometricBackground: View {
    var body: some View {
        Canvas { context, size in
            let rows = 10
            let cols = 10
            let cellWidth = size.width / CGFloat(cols)
            let cellHeight = size.height / CGFloat(rows)

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * cellWidth
                    let y = CGFloat(row) * cellHeight

                    let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
                    let path = Path(rect)

                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.1)),
                        lineWidth: 1
                    )
                }
            }
        }
        .background(Color(hex: "#0a0a0a"))
    }
}

// Glassmorphism effect
struct GlassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glassmorphism")
                .font(.custom("Fraunces-Bold", size: 24))
            Text("Frosted glass effect")
                .font(.custom("Literata-Regular", size: 16))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}
```

---

## Layout & Composition

### Breaking Generic Patterns

**Avoid:**
- Predictable vertical stacks
- Centered everything
- Cookie-cutter card layouts

**Embrace:**
- Asymmetric layouts
- Overlapping elements with z-index
- Grid-based systems with breakout elements
- Negative space as a design element

### Advanced Layouts

```swift
// Bento-style grid
struct BentoGrid: View {
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                BentoCard(color: .blue, span: 2)
                    .gridCellColumns(2)
                BentoCard(color: .purple)
            }
            GridRow {
                BentoCard(color: .green)
                BentoCard(color: .orange, span: 2)
                    .gridCellColumns(2)
            }
        }
        .padding()
    }

    struct BentoCard: View {
        let color: Color
        var span: Int = 1

        var body: some View {
            RoundedRectangle(cornerRadius: 16)
                .fill(color.gradient)
                .frame(height: span == 2 ? 200 : 100)
        }
    }
}

// Overlapping cards with parallax
struct ParallaxCards: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.3 + Double(index) * 0.2))
                        .frame(width: 300, height: 400)
                        .offset(x: offset * CGFloat(index) * 0.3, y: CGFloat(index) * 40)
                        .shadow(radius: 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
            )
        }
    }
}
```

---

## Anti-Patterns to Avoid

1. **Using system fonts everywhere** → Choose distinctive typefaces
2. **Purple gradient fever** → Explore unexpected color combinations
3. **Generic SF Symbols overuse** → Create custom icons or use styled alternatives
4. **Over-relying on Lists** → Explore grids, carousels, custom layouts
5. **No animation strategy** → Plan motion as part of the design
6. **Flat white backgrounds** → Add atmosphere and depth
7. **Cookie-cutter navigation** → Customize tab bars and navigation

---

## Quick Reference: Avoiding "AI Slop"

### Typography Anti-Slop
```swift
// ❌ Generic
.font(.system(size: 16))

// ✅ Distinctive
.font(.custom("Crimson Pro", size: 18))
```

### Color Anti-Slop
```swift
// ❌ Generic purple gradient
LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)

// ✅ Distinctive themed palette
LinearGradient(
    colors: [Color(hex: "#ff6b6b"), Color(hex: "#4ecdc4")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Animation Anti-Slop
```swift
// ❌ No animation or generic fade
.opacity(isVisible ? 1 : 0)

// ✅ Orchestrated spring animation with stagger
.offset(y: appeared ? 0 : 50)
.opacity(appeared ? 1 : 0)
.animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: appeared)
```

---

## Final Principle

**Every design decision should be intentional.** If you can't explain why you chose a particular font, color, or animation beyond "it looks nice," you're likely converging toward generic. Ask: *What emotion am I creating? What story am I telling? How is this different from every other app?*
