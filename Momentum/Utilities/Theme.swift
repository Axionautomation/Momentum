//
//  Theme.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

// MARK: - Color System (Dark-First, Futuristic)

extension Color {
    // MARK: Backgrounds
    static let momentumBackground = Color(hex: "09090B")              // zinc-950 — deepest background
    static let momentumBackgroundSecondary = Color(hex: "18181B")     // zinc-900 — cards, surfaces

    // MARK: Surfaces (Glassmorphism)
    static let momentumSurface = Color(hex: "27272A")                 // zinc-800
    static let momentumSurfaceBorder = Color.white.opacity(0.08)      // glass border
    static let momentumSurfaceGlow = Color.white.opacity(0.05)        // inner glow

    // MARK: Primary Accent — Electric Blue → Cyan
    static let momentumBlue = Color(hex: "3B82F6")                    // blue-500
    static let momentumBlueLight = Color(hex: "06B6D4")               // cyan-500
    static let momentumBlueDark = Color(hex: "2563EB")                // blue-600

    // MARK: Secondary Accent — Violet → Fuchsia
    static let momentumViolet = Color(hex: "8B5CF6")                  // violet-500
    static let momentumFuchsia = Color(hex: "D946EF")                 // fuchsia-500

    // MARK: Text
    static let momentumTextPrimary = Color(hex: "FAFAFA")             // zinc-50
    static let momentumTextSecondary = Color(hex: "A1A1AA")           // zinc-400
    static let momentumTextTertiary = Color(hex: "71717A")            // zinc-500

    // MARK: Status
    static let momentumSuccess = Color(hex: "10B981")                 // emerald-500
    static let momentumWarning = Color(hex: "F59E0B")                 // amber-500
    static let momentumDanger = Color(hex: "EF4444")                  // red-500

    // MARK: Domain Colors
    static let momentumCareer = Color(hex: "3B82F6")                  // blue — career domain
    static let momentumFinance = Color(hex: "10B981")                 // green — finance domain
    static let momentumGrowth = Color(hex: "8B5CF6")                  // violet — growth domain

    // MARK: Legacy Aliases (mapped to new values)
    static let momentumCardBackground = Color(hex: "18181B")          // → backgroundSecondary
    static let momentumCardBorder = Color.white.opacity(0.08)         // → surfaceBorder
    static let momentumEasy = Color(hex: "10B981")                    // emerald
    static let momentumMedium = Color(hex: "F59E0B")                  // amber
    static let momentumHard = Color(hex: "EF4444")                    // red
    static let momentumGold = Color(hex: "F59E0B")                    // amber
    static let momentumGoldLight = Color(hex: "FCD34D")               // amber-300
    static let momentumCoral = Color(hex: "FF6B4A")                   // coral
    static let momentumDeepBlue = Color(hex: "1E3A8A")                // deep blue
    static let momentumGreenStart = Color(hex: "10B981")              // emerald
    static let momentumGreenEnd = Color(hex: "34D399")                // emerald-400
    static let momentumDarkBackground = Color(hex: "09090B")          // → background
    static let momentumSurfacePrimary = Color(hex: "18181B")          // → backgroundSecondary
    static let momentumSurfaceSecondary = Color(hex: "27272A")        // → surface
    static let momentumSurfaceDivider = Color.white.opacity(0.08)     // → surfaceBorder
    static let momentumPrimaryText = Color(hex: "FAFAFA")             // → textPrimary
    static let momentumSecondaryText = Color(hex: "A1A1AA")           // → textSecondary
    static let momentumLightBackground = Color(hex: "18181B")         // → backgroundSecondary

    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography (SF Pro Display — Bold & Futuristic)

struct MomentumFont {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func headline(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func bodyMedium(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func label(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    // Legacy aliases
    static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func headingLarge(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func headingMedium(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func stats(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// MARK: - Spacing

struct MomentumSpacing {
    static let micro: CGFloat = 4
    static let tight: CGFloat = 8
    static let compact: CGFloat = 12
    static let standard: CGFloat = 16
    static let comfortable: CGFloat = 20
    static let section: CGFloat = 24
    static let large: CGFloat = 32
}

// MARK: - Corner Radii

struct MomentumRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

// MARK: - Gradients

struct MomentumGradients {
    // Primary: Electric Blue → Cyan
    static let primary = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "06B6D4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Neon Blue
    static let neonBlue = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "06B6D4")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Neon Violet
    static let neonViolet = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Midnight
    static let midnight = LinearGradient(
        colors: [Color(hex: "09090B"), Color(hex: "18181B")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Aurora (celebration)
    static let aurora = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6"), Color(hex: "D946EF"), Color(hex: "06B6D4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Success
    static let success = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "34D399")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Domain gradients
    static let career = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "06B6D4")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let finance = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "34D399")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let growth = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Legacy aliases
    static let celebration = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gold = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "FCD34D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coral = LinearGradient(
        colors: [Color(hex: "FF6B4A"), Color(hex: "FF6B4A").opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = LinearGradient(
        colors: [Color(hex: "09090B"), Color(hex: "18181B")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Animation Presets

struct MomentumAnimation {
    static let smoothSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let dramatic = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Staggered delay for list items
    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.35, dampingFraction: 0.85).delay(Double(index) * baseDelay)
    }
}

// MARK: - Glassmorphic View Modifiers

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = MomentumRadius.medium

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = MomentumRadius.medium

    func body(content: Content) -> some View {
        content
            .padding(MomentumSpacing.standard)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct GlowBorderModifier: ViewModifier {
    var color: Color = .momentumBlue
    var cornerRadius: CGFloat = MomentumRadius.medium
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color, color.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 8, y: 0)
    }
}

// MARK: - Card Modifiers (Updated for Dark Theme)

struct MomentumCardModifier: ViewModifier {
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(Color.momentumBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(
                        isHighlighted ? Color.momentumBlue : Color.white.opacity(0.08),
                        lineWidth: isHighlighted ? 1.5 : 0.5
                    )
            )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MomentumFont.bodyMedium(17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [.momentumBlue, .momentumBlueLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .momentumBlue.opacity(0.3), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MomentumFont.bodyMedium(17))
            .foregroundColor(.momentumBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .fill(Color.momentumBlue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(Color.momentumBlue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Glassmorphic surface — ultra-thin material + subtle border
    func glass(cornerRadius: CGFloat = MomentumRadius.medium) -> some View {
        modifier(GlassModifier(cornerRadius: cornerRadius))
    }

    /// Glassmorphic card — glass + padding + shadow
    func glassCard(cornerRadius: CGFloat = MomentumRadius.medium) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    /// Animated gradient glow border
    func glowBorder(color: Color = .momentumBlue, cornerRadius: CGFloat = MomentumRadius.medium) -> some View {
        modifier(GlowBorderModifier(color: color, cornerRadius: cornerRadius))
    }

    /// Standard card style
    func momentumCard(highlighted: Bool = false) -> some View {
        modifier(MomentumCardModifier(isHighlighted: highlighted))
    }

    // Legacy modifiers (mapped to new implementations)
    func opaqueSurface(level: OpaqueSurfaceModifier.SurfaceLevel = .secondary, cornerRadius: CGFloat = 12) -> some View {
        modifier(OpaqueSurfaceModifier(level: level, cornerRadius: cornerRadius))
    }

    func frostedGlass() -> some View {
        glass(cornerRadius: 16)
    }

    func cardStyle(highlighted: Bool = false) -> some View {
        modifier(CardModifier(isHighlighted: highlighted))
    }
}

// MARK: - Legacy Modifiers (kept for compatibility, updated visuals)

struct OpaqueSurfaceModifier: ViewModifier {
    var level: SurfaceLevel = .primary
    var cornerRadius: CGFloat = 12

    enum SurfaceLevel {
        case primary
        case secondary
        case elevated
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.3),
                radius: level == .elevated ? 20 : 8,
                y: level == .elevated ? 10 : 4
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var backgroundColor: Color {
        switch level {
        case .primary:
            return .momentumBackgroundSecondary
        case .secondary, .elevated:
            return .momentumSurface
        }
    }
}

struct FrostedGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CardModifier: ViewModifier {
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isHighlighted ? Color.momentumBlue : Color.white.opacity(0.08),
                        lineWidth: isHighlighted ? 1.5 : 0.5
                    )
            )
    }
}
